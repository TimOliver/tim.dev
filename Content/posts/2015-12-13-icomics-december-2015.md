---
title: iComics – December 2015
date: 2015-12-13 19:20:33
author: Tim Oliver
image: /img/posts/2015/12/iComics-December-2015.jpg
tags: development, icomics
path: /2015/12/13/icomics-december-2015/
---
Hi everyone! I can’t believe 2015 is already nearly over! Jeez!

I thought I’d do a reeeeally quick update on where we’re at with iComics, and what the current goal is. 🙂

## iOS 9 Crash Panic

The release of iOS 9 was a little more exciting than I anticipated. In that I had to literally drop everything and scramble for a little bit there. XD

When iOS 9 hit, the number of 1-star reviews for iComics shot up very sharply, citing that the app simply would not start on ONLY SOME of the users’ devices, even after deleting/re-installing.

Having NEVER EVER seen this on any of my own devices, I was at an absolute loss to try and figure out how to fix this bug. Thankfully, one of iComics’ users, an amazingly awesome chap named [Cameron Cool](https://twitter.com/ccooluke) came forward with his iPad Air 2, and let me use him as a guinea pig with a new beta build of the app.

After a few hours of testing, [this was the crash log I ended up with](https://twitter.com/TimOliverAU/status/655290149517955072).

After scratching my head for several hours, I finally managed to trace the issue down to this block of code:  
```objc
EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
[EAGLContext setCurrentContext:context];
glGetIntegerv(GL_MAX_TEXTURE_SIZE, &ICMaxTextureSize);
[EAGLContext setCurrentContext:nil]; //THIS LINE OF CODE IS ABSOLUTELY ESSENTIAL!!!!!!!!!
```

In a nutshell, iComics uses an OpenGL API to work out what the maximum supported image size of the GPU for that particular device is.

What I didn’t realise was that the ‘setCurrentContext’ call ABSOLUTELY MUST be set back to nil when you’re finished, otherwise it will interfere with other parts of iOS down the line. This was apparently already happening to a small degree on iOS 8, but it GOT SO MUCH WORSE on iOS 9.

In any case, Apple were kind enough to allow me an expedited review in order to release a new version fixing that issue, and the reception to the app has been extremely positive ever since.

Major thanks to Cameron for his help. I absolutely would not have been able to fix this issue without him. 🙂

## iPad Pro Support

I’d been hoping for a jumbo iPad to happen for a long time; ever since the announcement of an ‘Air’ iPad implied as much. So I was absolutely over the moon when Apple announced it alongside the new iPhone. When they came out a day early, the Apple guys at the main store here in Perth told me I was quite possibly the first guy in the city to actually buy one from them. XD

Just in case it wasn’t obvious, these things are big. Hilariously big.

> <div style="padding: 8px;"><div style="background: #F8F8F8; line-height: 0; margin-top: 40px; padding: 50.0% 0; text-align: center; width: 100%;"></div>[iPad Pro vs iPad mini. XD](https://www.instagram.com/p/-5etp-Mya7/)
> 
> A photo posted by Tim Oliver (@timoliver) on <time datetime="2015-12-05T05:18:33+00:00" style="font-family: Arial,sans-serif; font-size: 14px; line-height: 17px;">Dec 4, 2015 at 9:18pm PST</time>
> 
> </div>

<script async="" defer="defer" src="//platform.instagram.com/en_US/embeds.js"></script>

When the iPad Pro was released, iComics was already configured to display at the native resolution (instead of being upscaled LIKE SO MANY OTHER APPS RIGHT NOW), but there were still a few elements that weren’t taking proper advantage of the new size (Such as the comic panels in the ‘list’ view mode). The latest version of iComics I’ve released has fixed this.

Now that the iPad Pro is out there, there’s two features I REALLY want to add to iComics:

- Split-screen support
- Dual-page spread in landscape mode

Sadly, both of those features are going to require some pretty extensive refactoring of the logic of the app, but it’s something I’m already planning down on paper to implement. 🙂

## Downloading Comics from Cloud Services

I received another review requesting this feature very recently. 🙂

<div class="content_cards_card content_cards_domain_appfigures-com">
<div class="content_cards_image"><a href="https://appfigures.com/reviews/213171321Lh-BxVpusoNvE1ZLXTZmzLg?lang=en"><img src="/img/posts/2022/05/213171321lh-bxvpusonve1zlxtzmzlg.png" alt="★★★★☆ iComics review on iOS App Store"></a></div>
<div class="content_cards_title"><a href="https://appfigures.com/reviews/213171321Lh-BxVpusoNvE1ZLXTZmzLg?lang=en">★★★★☆ iComics review on iOS App Store</a></div>
<div class="content_cards_description"><a href="https://appfigures.com/reviews/213171321Lh-BxVpusoNvE1ZLXTZmzLg?lang=en">Inconvenient importing · I will start by saying that this is a great app and that I would definitely recommend it. With that being said, this app's biggest flaw is that it does not feature any kind of download queue. In order to import comics, you must download them one-by-one. Not only that, but you…</a></div>
<div class="content_cards_site_name"><img src="/img/posts/2022/05/appfigures-icon.png" alt="Appfigures" width="16" height="16"> Appfigures</div>
</div>

I mentioned this in my last blog post, but since it’s something people really, REALLY want, I better touch on it again. XD

Yes. I’m working on it. Slowly but surely. XD Here’s the latest photo I’ve put up of it so far. This should give you a good indication of the services I want to support. 🙂

> <div style="padding:8px;"><div style=" background:#F8F8F8; line-height:0; margin-top:40px; padding:50.0% 0; text-align:center; width:100%;"><div style=" background:url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACwAAAAsCAMAAAApWqozAAAAGFBMVEUiIiI9PT0eHh4gIB4hIBkcHBwcHBwcHBydr+JQAAAACHRSTlMABA4YHyQsM5jtaMwAAADfSURBVDjL7ZVBEgMhCAQBAf//42xcNbpAqakcM0ftUmFAAIBE81IqBJdS3lS6zs3bIpB9WED3YYXFPmHRfT8sgyrCP1x8uEUxLMzNWElFOYCV6mHWWwMzdPEKHlhLw7NWJqkHc4uIZphavDzA2JPzUDsBZziNae2S6owH8xPmX8G7zzgKEOPUoYHvGz1TBCxMkd3kwNVbU0gKHkx+iZILf77IofhrY1nYFnB/lQPb79drWOyJVa/DAvg9B/rLB4cC+Nqgdz/TvBbBnr6GBReqn/nRmDgaQEej7WhonozjF+Y2I/fZou/qAAAAAElFTkSuQmCC); display:block; height:44px; margin:0 auto -44px; position:relative; top:-22px; width:44px;"></div></div> [Making progress on the download system UI. Slowly but surely. 🙂](https://www.instagram.com/p/9gKLUQkiRZ/)
> 
> A photo posted by iComics (@icomicsapp) on <time datetime="2015-10-31T12:46:41+00:00" style=" font-family:Arial,sans-serif; font-size:14px; line-height:17px;">Oct 31, 2015 at 5:46am PDT</time>
> 
> </div>

<script async="" defer="defer" src="//platform.instagram.com/en_US/embeds.js"></script>

At the moment, I’m playing with the API interfaces for Dropbox, Google Drive, OneDrive and Box. Ideally, I want to run all of their web authentication processes through a web browser interface I can control, so I can add 1Password integration to it (Something no other comic reader has done so far. 😉 )

I want this system to look and feel as nice as it possibly can, and that’s going to require a lot of custom UI code and background execution, not to mention security concerns in keeping users login credentials safe. I’ve made a lot of headway on it, but there’s still a long way to go. In any case, please let me assure you that I am indeed working on it, and it’s going to be awesome when it’s done. 😀

I’m hoping to work on it very heavily over the Christmas holidays, in order to free up 2016 for bigger and better features. 🙂

## Streaming on Twitch

A little while back, [Twitch brought out Twitch Creative](http://blog.twitch.tv/2015/10/introducing-twitch-creative/), a new set of guidelines where it’s now possible to stream ‘the creation of things, but not explicably related to video games’. I’m quite excited about this, and I’m now considering streaming some iComics development on Twitch.

If that sounds interesting to you, feel free to follow [my new Twitch account](http://www.twitch.tv/ItsTimXD) so you’ll be alerted the next time I go live. 🙂

## Conclusion

Overall, it’s been a crazy year. I hope everyone had a great 2015, and I hope iComics was of use to you.

Merry Christmas, take care, and see you next year! 🙂

*(The photo for this post is iComics running on my iPad Pro, displaying the comic Scott Pilgrim #1. Scott Pilgrim may be purchased [DRM-free on Comixology](https://www.comixology.com/Scott-Pilgrim-Vol-1-of-6-Scott-Pilgrims-Precious-Little-Life-Color-Edition/digital-comic/28619), but I bought my copy from [Humble Bundle](http://humblebundle.com). 🙂 )*
