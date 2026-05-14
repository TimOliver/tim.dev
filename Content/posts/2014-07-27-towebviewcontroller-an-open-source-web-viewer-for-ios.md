---
title: TOWebViewController – An open source web viewer for iOS
date: 2014-07-27 22:58:09
author: Tim Oliver
image: /img/posts/2014/07/TOWebViewController.jpg
tags: development, tech
path: /2014/07/27/towebviewcontroller-an-open-source-web-viewer-for-ios/
---
Here’s a neat little thing I’ve been working on lately. 🙂

When it comes to building apps for iPhone and iPad, there’s often a design requirement in quickly displaying web pages to users, without needing to kick them out to another app in the process.

One example of this is social media apps; ones that deals with massive amounts of user-posted content, often with links attached. One of my most favourite apps on iOS, [Tweetbot](https://itunes.apple.com/au/app/tweetbot-3-for-twitter-iphone/id722294701), handles this incredibly elegantly.

![Tweetbot-Kotaku](/img/posts/2014/07/Tweetbot-Kotaku.jpg)

Another, lesser example of this sort of thing is when there might be a need to display a set of static information to the app user, but that this information may be subject to change in the future. [Google Maps app on iOS](https://itunes.apple.com/au/app/google-maps/id585027354) employs for its legal services agreement:

![GoogleMaps-TOS-iPhone5s](/img/posts/2014/07/GoogleMaps-TOS-iPhone5s.jpg)

Apple makes building a web viewer a lot easier than it could be by providing a type of UI element called a [UIWebView](https://developer.apple.com/library/ios/documentation/uikit/reference/UIWebView_Class/Reference/Reference.html), that can take a URL, and load and display its content. But unfortunately, that’s all it does. So any other bells and whistles (Like a back button, or a loading bar) must be done by the developers.

Last year, while I was working on [my dinky little comic reader app](http://icomics.co), I came up with 3 discrete needs for a web page viewer in my app’s design:

- Linking to a set of instructions on Apple.com on how to move comics into the app via iTunes (Something I intend to replace with a proper custom document at some point!).
- Incidental links inside the app’s Settings menu (ie, links to third party library sites).
- In a future release, the ability to navigate to websites inside the app, and queue up comic downloads directly from it (eg from sites like [DriveThruComics](http://comics.drivethrustuff.com/)).

That last point’s a bit of a doozy. So much so, that when I checked out all of the open source web viewers already on GitHub, I didn’t see one that would fit the bill for all the features I ultimately want to have.

So, I decided to roll my own. 🙂

Last year, I decided to start building a completely self-contained web viewer library. Named [TOWebViewController](https://github.com/TimOliver/TOWebViewController), the goal of the class is to be able to provide a ‘drop-in’ web viewer that can be used for a variety of different app UI configurations.

![TOWebViewController on iPod touch](/img/posts/2014/07/TOWebViewController-iPod.jpg)

It follows a very ‘system-standard’ visual design style, and has been built with a multitude of configuration options, but can be easily implemented with only a couple of lines of code. Some of its features include:

**Support for iOS 5 and up**  
Supporting iOS devices even as far back as the iPhone 3GS, the 3rd generation iPod touch, and the 1st generation iPad, the class has been designed to be as flexible as possible with system requirements.

![TOWebViewController on iOS 5](/img/posts/2014/07/TOWebViewController-iPhone4s.jpg)

**A page loading progress bar**  
Normally, it’s not possible to get a proper ‘page loaded amount’ from a UIWebView, so having a loading bar is actually quite tricky. Thankfully, an incredibly smart Japanese chap named Satoshi ‘ninjinkun’ Asano developed a brilliant algorithm that counts the number of requests that start and and finish within a UIWebView, to produce a surprisingly accurate page load progress value. TOWebViewController makes use of this algorithm, which I re-implemented from scratch to ensure complete, seamless integration.

**Procedurally generated artwork**  
Between iPhone and iPad versions, Retina and non-Retina versions, iOS 6 and iOS 7 versions, I was looking at a relatively crazy number of graphics asset combinations that would needed to be included along with the viewer, to ensure proper compatibility across all devices and all versions. To minimize the redundancy of requiring image files that might end up never getting used, ALL of the assets in this bundle are generated procedurally using Apple’s Quartz technology at runtime, with both the device iOS version, and screen size taken into account.

<iframe class="instagram" height="710" loading="lazy" src="//instagram.com/p/mXv3C2syaI/embed/" width="612"></iframe>

**Custom device rotation animations**  
Unlike Safari, for some strange reason, Apple never properly implemented dynamic rescaling in the UIWebView UI control. As a result, if the user rotates the device while it’s visible, more often than not, it glitches up.

Here’s how it looks in Google Chrome for iOS, which uses the default implementation:

<iframe class="instagram" height="710" loading="lazy" src="//instagram.com/p/qYhDcJsyZY/embed/" width="612"></iframe>

In TOWebViewController, I implemented a completely custom animation for handling device rotations, designed to mimic Safari:

<iframe class="instagram" height="710" loading="lazy" src="//instagram.com/p/qYgZzrMyYs/embed/" width="612"></iframe>

The animation works by taking a photo of the web content, overlays the photo on top of the web content, animates that, and then restores the web content once the animation is complete.

*(NB: I’m picking on Google Chrome a bit here because I filed a bug report about that animation glitch back in 2013, that culminated in a face-to-face meeting with one of Google Chrome for iOS’ engineers at Google I/O 2013. So I know they’re aware of the issue! 😉 )*

TOWebViewController is [available to download from my GitHub account](https://github.com/TimOliver/TOWebViewController), under the MIT license. The goal from this point onwards is to develop upon it concurrently along with my comic reader app, adding features to it as I require them in my app.

In any case, if you’re a fellow developer, and discover you need to display some web content in your app, hopefully this library will save you some time!