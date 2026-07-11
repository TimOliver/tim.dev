---
title: /Regular Expression[s] Script!/
date: 2010-03-01 22:53:20
author: Tim Oliver
image: /img/posts/2010/03/tims_regex_tester.png
tags: development, tech
path: /2010/03/01/regex_script/
---
![TiM's Regex Tester after a successful query.](/img/posts/2010/03/tims_regex_tester.png)I think it’s fair to say that since graduating from univeristy, I’ve wound up doing a LOT of web development. XD

With heaps of small-time client work, building dynamic web apps at a company in Japan as well as pimping out and maintaining [WesternAustralia.com](http://www.westernaustralia.com/) for Tourism WA, and now developing for several web apps and web sites at [ECU](http://www.ecu.edu.au/)… so far it’s looking pretty diverse hehe. But in any case, I’m totally not complaining here; I love every minute of it! 😀

One thing I’ve found myself doing quite a lot of recently however is content migration. A lot of my work revolves around [content management systems](http://en.wikipedia.org/wiki/Content_management_system), and when it comes to upgrading to a new platform, it usually means having to copy the blocks of text/code out of the old one, re-twiddle any custom tags or syntax inside it, and then paste it into the new one.

But that being said, I quickly discovered a tool which eased the pain significantly:[ regular expressions](http://en.wikipedia.org/wiki/Regular_expressions)! (Or regex, after you get tired of saying regular expressions all the time hehe XD)

Although getting the hang of the actual syntax for regex queries is a pretty hefty learning curve, once you get the hang of them, it becomes an extremely powerful tool. 😀  
As long as you understand the potential formatting of the content you’re parsing, you can do pretty much anything with it (parsing text-wise hehe). In terms of content migration, it becomes really easy to parse out and then substitute syntax elements of the old content management system and with the new one, pretty much totally automatically. ^\_^

That being said though, I do still find writing regex queries pretty darn tricky. It’s really easy to get lost and confused in there, and unless you’re testing it the whole time you’re writing it, you’ll usually end up with it failing to work properly, or outright crashing.  
To that extent, I’ve noticed that although somewhat rare, it is possible to debug your regex queries on ‘regex testing’ web sites that some people have generously setup for free use online. One such site which I use a lot is [Solmetra’s Regular Expression Test Tool](http://www.solmetra.com/scripts/regex/), which does the job really nicely. 🙂

Sadly however, since I travel around a bit with my laptop, I do sometimes wind up in instances where I’m working on a local copy of my site, but unable to use a regex testing tool. Since all of these tools are online, I can’t really take them with me… until now.

So last weekend, I decided to spend a few hours and write my own regex testing script with PHP. 😀

With the very apt, original (lol) name of “TiM’s Regex Tester’, it may be a slightly watered down equivalent of some of the other scripts out there, but it does the trick well none-the-less. 🙂  
It handles most of PHP’s main Perl based regex functions (apparently POSIX has been deprecated now), and helps to render out the results in a nice clean display, whilst preserving all of the query data so you can make changes to it really rapidly.  
I also took the chance to use this script as a bit of CSS3 practice, to see how nice a page without any images could look. With stuff like rounded corners and text-shadowing… I’d say pretty nice indeed. XD

So finally, as a general service, for the convenience of other fellow developers online, I’ve decided to release the script for download on this blog. 🙂  
To maximize its portability, I wrote the whole thing, the PHP, CSS, JavaScript and HTML code all encapsulated in one file. While it’s not the most elegant code solution, it should plug straight into any system that’s running PHP 5 and start working without any configuration at all.  
The script is released under the[ GPL license](http://www.gnu.org/copyleft/gpl.html), so feel free to modify it and distribute it yourself. 🙂

Download TiM’s Regex Tester PHP script *(the download was lost in a site migration — sorry!)*

While this script is aimed primarily so you can have regex debugging capability in an offline environment, I may look at setting up an online version for people to use as well. 😉

So… yeah, enjoy the script, and regex FTW! XD