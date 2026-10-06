---
title: Futzing with WordPress’ base directory
date: 2010-03-31 20:30:05
author: Tim Oliver
image: /img/posts/2010/03/tim-oliver_site_structure.png
tags: development, tech
path: /2010/03/31/futzing-with-wordpress-base-directory/
---
![The list of files in my hosted spaces root directory. I'm discussing how I set up requests to go to these directories. XD](/img/posts/2010/03/tim-oliver_site_structure.png)A few blog posts ago, when I wrote about the online version of [my regex tester](http://www.regex-tester.com/), I mentioned that I was experiencing a few technical troubles on my blog. The reason for this was that the regex tester is kept in the same web space as my blog, and the way I had set it up was causing erroneous functions in WordPress.

After a bit of googling and some .htaccess hackery, I got it all working again. Since it was a bit of an interesting concept and solution, I thought I’d write it up here. 😀

So, I have one main block of web space that I use for all of my websites, which is hosted by the fine people at [Ennoverse.com](http://www.ennoverse.com/) (\*plug plug\* XD). The primary domain for the space is Tim-Oliver.com which directs to the root directory of the space and originally, the directory contained all of my blog WordPress files.

When I went to set up Regex-Tester.com, I decided I didn’t want the files and directories from my blog to mix with those of the regex site. To do this, I placed all of the blog files into a directory called ‘/blog’ and all of the regex files in a directory called ‘/regex’. I then simply set the Regex-Tester.com domain as a subdomain which directed straight to the ‘/regex’ directory after that.

Now, herein lay the dilemma:

- To maintain the same file routes and structures, I wanted my blog to operate out of ‘/blog’ on the server, but to the outside, I wanted it to look like it was still in the root directory.
- By extension to this, I wanted to make sure you couldn’t access Regex-Tester.com by typing in /regex/

So the solution seemed pretty simple. I wrote a custom .htaccess file that would soft redirect any server requests through to the ‘/blog’ directory like so:

```
Options +FollowSymLinks
# Enable rewrite rules
RewriteEngine On
RewriteBase /
#Default: Tim-Oliver Blog
RewriteRule ^(.*)$ /blog/$1 [QSA,L]
```

After trying this out, everything looked fine. Without having to touch a single setting on my blog, it was loading and rendering perfectly.

Erm…. unfortunately, it started interfering with the Regex-Tester.com subdomain. And by that, I mean it broke it completely. It turns out the requests to Regex-Tester.com were going through this rewrite delegation condition as well, and that was causing a conflict on the server.

So the natural solution to this was to edit the .htaccess code and get it to make exceptions for specific domain names (ie Regex-Tester.com) and then delegate the remainder back to default:

```
#Regex-Tester Site
RewriteCond %{HTTP_HOST} ^(www\.)?regex-tester\.com
RewriteRule .* - [L]
```

And thankfully this worked out perfectly. ^\_^ I could now load both web sites out of their respective sub-directories, but it appeared that they were totally separate.

Erm… however, finally… I noticed one last little glitch. I couldn’t log into WordPress’ admin panel anymore. ;\_; Any computer where my cookies were set was okay… but trying it on any logged out computers resulted in me constantly looping back to the login page over and over.

After tearing the page apart and checking out the various bits of code, I finally noticed that the login page had its GET redirection variable set with ‘/blog’ at the start. :S

After furthur digging around in the WordPress source code, I eventually discovered that WordPress generates its redirection addresses using the physical file locations passed from several PHP $\_SERVER variables. There was no way to edit this with .htaccess, and if even I did, I might just end up breaking the blog more.

So my final solution to this was to just write a quick WP plugin and get it to modify the $\_SERVER variables before WordPress actually began execution:

```
//remove '/blog' from the URI values to ensure correct URLS
//(/blog is needed by Apache, but should be invisible to the PHP)
function SantizeServerURIs($str)
{
$_SERVER['PHP_SELF'] = preg_replace('/^\/?blog/i', '', $_SERVER['PHP_SELF'] );
$_SERVER['REQUEST_URI'] = preg_replace('/^\/?blog/i', '', $_SERVER['REQUEST_URI'] );
}
add_action( 'init', 'SantizeServerURIs' );
```

And with that code in place, everything started working perfectly again. ^\_^

So this was basically my little method of storing two separate sites in one hosted space, but then delegating them separate requests so as to make them behave as if they were in the root directory. If anyone else was thinking of doing the same thing, hopefully it helped a little. 🙂

Let me know what you think of it. If you know of a faster way to do this, then by all means let me hear it. XD

Also, if you found a critical exploit in there that I may have missed…. please let me know that one too. 😉