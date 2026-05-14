---
title: iComics – State of the Union – May 2015
date: 2015-05-25 23:26:17
author: Tim Oliver
image: /img/posts/2015/05/iComics_May_2015.jpg
tags: development
path: /2015/05/25/icomics-state-of-the-union-may-2015/
---
Sorry about the last update being so long ago!

2015 has been absolutely ridiculous for me so far (In a truly good way, that is!).

Thanks to [a talk I did](https://www.youtube.com/watch?v=cGptaE2_WEQ) on integrating [Realm](http://realm.io) into iComics last year, [I’ve started working for Realm](https://realm.io/news/tim-oliver-joins-realm/), remotely from Perth. This has been an absolutely amazing experience so far, having learned a HUGE deal about how companies operate in Silicon Valley, as well as integrating with a team that operates in multiple time zones. The fact that this all came about as a result of my work on iComics is something I still haven’t managed to process yet. Truly awesome.

In any case, now all of the main excitement has started settling down ([Although not for long I’ll wager!](https://developer.apple.com/wwdc/)), I’ve been looking at the next batch of features and upgrades that iComics needs. Since I’ve been getting quite a few emails asking about updates to the app, it seems a bit of a status update is already long overdue. Here’s some of the major points on we’re were at right now. 🙂

## Version 1.2.5 released to the App Store

> <div style="padding:16px;"> [<div style=" display: flex; flex-direction: row; align-items: center;"><div style="background-color: #F4F4F4; border-radius: 50%; flex-grow: 0; height: 40px; margin-right: 14px; width: 40px;"></div><div style="display: flex; flex-direction: column; flex-grow: 1; justify-content: center;"><div style=" background-color: #F4F4F4; border-radius: 4px; flex-grow: 0; height: 14px; margin-bottom: 6px; width: 100px;"></div><div style=" background-color: #F4F4F4; border-radius: 4px; flex-grow: 0; height: 14px; width: 60px;"></div></div></div><div style="padding: 19% 0;"></div><div style="display:block; height:50px; margin:0 auto 12px; width:50px;"><svg height="50px" version="1.1" viewbox="0 0 60 60" width="50px" xmlns="https://www.w3.org/2000/svg" xmlns:xlink="https://www.w3.org/1999/xlink"><g fill="none" fill-rule="evenodd" stroke="none" stroke-width="1"><g fill="#000000" transform="translate(-511.000000, -20.000000)"><g><path d="M556.869,30.41 C554.814,30.41 553.148,32.076 553.148,34.131 C553.148,36.186 554.814,37.852 556.869,37.852 C558.924,37.852 560.59,36.186 560.59,34.131 C560.59,32.076 558.924,30.41 556.869,30.41 M541,60.657 C535.114,60.657 530.342,55.887 530.342,50 C530.342,44.114 535.114,39.342 541,39.342 C546.887,39.342 551.658,44.114 551.658,50 C551.658,55.887 546.887,60.657 541,60.657 M541,33.886 C532.1,33.886 524.886,41.1 524.886,50 C524.886,58.899 532.1,66.113 541,66.113 C549.9,66.113 557.115,58.899 557.115,50 C557.115,41.1 549.9,33.886 541,33.886 M565.378,62.101 C565.244,65.022 564.756,66.606 564.346,67.663 C563.803,69.06 563.154,70.057 562.106,71.106 C561.058,72.155 560.06,72.803 558.662,73.347 C557.607,73.757 556.021,74.244 553.102,74.378 C549.944,74.521 548.997,74.552 541,74.552 C533.003,74.552 532.056,74.521 528.898,74.378 C525.979,74.244 524.393,73.757 523.338,73.347 C521.94,72.803 520.942,72.155 519.894,71.106 C518.846,70.057 518.197,69.06 517.654,67.663 C517.244,66.606 516.755,65.022 516.623,62.101 C516.479,58.943 516.448,57.996 516.448,50 C516.448,42.003 516.479,41.056 516.623,37.899 C516.755,34.978 517.244,33.391 517.654,32.338 C518.197,30.938 518.846,29.942 519.894,28.894 C520.942,27.846 521.94,27.196 523.338,26.654 C524.393,26.244 525.979,25.756 528.898,25.623 C532.057,25.479 533.004,25.448 541,25.448 C548.997,25.448 549.943,25.479 553.102,25.623 C556.021,25.756 557.607,26.244 558.662,26.654 C560.06,27.196 561.058,27.846 562.106,28.894 C563.154,29.942 563.803,30.938 564.346,32.338 C564.756,33.391 565.244,34.978 565.378,37.899 C565.522,41.056 565.552,42.003 565.552,50 C565.552,57.996 565.522,58.943 565.378,62.101 M570.82,37.631 C570.674,34.438 570.167,32.258 569.425,30.349 C568.659,28.377 567.633,26.702 565.965,25.035 C564.297,23.368 562.623,22.342 560.652,21.575 C558.743,20.834 556.562,20.326 553.369,20.18 C550.169,20.033 549.148,20 541,20 C532.853,20 531.831,20.033 528.631,20.18 C525.438,20.326 523.257,20.834 521.349,21.575 C519.376,22.342 517.703,23.368 516.035,25.035 C514.368,26.702 513.342,28.377 512.574,30.349 C511.834,32.258 511.326,34.438 511.181,37.631 C511.035,40.831 511,41.851 511,50 C511,58.147 511.035,59.17 511.181,62.369 C511.326,65.562 511.834,67.743 512.574,69.651 C513.342,71.625 514.368,73.296 516.035,74.965 C517.703,76.634 519.376,77.658 521.349,78.425 C523.257,79.167 525.438,79.673 528.631,79.82 C531.831,79.965 532.853,80.001 541,80.001 C549.148,80.001 550.169,79.965 553.369,79.82 C556.562,79.673 558.743,79.167 560.652,78.425 C562.623,77.658 564.297,76.634 565.965,74.965 C567.633,73.296 568.659,71.625 569.425,69.651 C570.167,67.743 570.674,65.562 570.82,62.369 C570.966,59.17 571,58.147 571,50 C571,41.851 570.966,40.831 570.82,37.631"></path></g></g></g></svg></div><div style="padding-top: 8px;"><div style=" color:#3897f0; font-family:Arial,sans-serif; font-size:14px; font-style:normal; font-weight:550; line-height:18px;"> View this post on Instagram</div></div><div style="padding: 12.5% 0;"></div><div style="display: flex; flex-direction: row; margin-bottom: 14px; align-items: center;"><div><div style="background-color: #F4F4F4; border-radius: 50%; height: 12.5px; width: 12.5px; transform: translateX(0px) translateY(7px);"></div><div style="background-color: #F4F4F4; height: 12.5px; transform: rotate(-45deg) translateX(3px) translateY(1px); width: 12.5px; flex-grow: 0; margin-right: 14px; margin-left: 2px;"></div><div style="background-color: #F4F4F4; border-radius: 50%; height: 12.5px; width: 12.5px; transform: translateX(9px) translateY(-18px);"></div></div><div style="margin-left: 8px;"><div style=" background-color: #F4F4F4; border-radius: 50%; flex-grow: 0; height: 20px; width: 20px;"></div><div style=" width: 0; height: 0; border-top: 2px solid transparent; border-left: 6px solid #f4f4f4; border-bottom: 2px solid transparent; transform: translateX(16px) translateY(-4px) rotate(30deg)"></div></div><div style="margin-left: auto;"><div style=" width: 0px; border-top: 8px solid #F4F4F4; border-right: 8px solid transparent; transform: translateY(16px);"></div><div style=" background-color: #F4F4F4; flex-grow: 0; height: 12px; width: 16px; transform: translateY(-4px);"></div><div style=" width: 0; height: 0; border-top: 8px solid #F4F4F4; border-left: 8px solid transparent; transform: translateY(-4px) translateX(8px);"></div></div></div>](https://www.instagram.com/p/1Cz3N_EiZA/?utm_source=ig_embed&utm_medium=loading) [In case you missed it, a new version of iComics went out earlier today! Go check it out! 🙂](https://www.instagram.com/p/1Cz3N_EiZA/?utm_source=ig_embed&utm_medium=loading)
> 
> A post shared by [ iComics](https://www.instagram.com/icomicsapp/?utm_source=ig_embed&utm_medium=loading) (@icomicsapp) on <time datetime="2015-04-04T07:02:34+00:00" style=" font-family:Arial,sans-serif; font-size:14px; line-height:17px;">Apr 4, 2015 at 12:02am PDT</time>
> 
> </div>

<script async="" src="//www.instagram.com/embed.js"></script>

Version 1.2.5 was released in April to the App Store (After a rather prolonged 2 week review by Apple). It featured an iOS 8 Today widget, a couple of smaller features that users requested (Including reversible comic sorting, as well as disabling iCloud backups), and some general library updates and bug fixes. Since then, over 13,000 users have downloaded the update, and the response has been for-the-most-part, positive (More on that later).

## iComics was made free on Free Comic Book Day

As has sort of become tradition at this point, iComics was made free for the weekend of [Free Comic Book Day](http://www.freecomicbookday.com) to help celebrate comic books, and to allow anyone who had been on the fence about getting the app a chance to get it. Around 27,000 people grabbed it while it was free, which was an amazing turnout.

> <div style="padding:16px;"> [<div style=" display: flex; flex-direction: row; align-items: center;"><div style="background-color: #F4F4F4; border-radius: 50%; flex-grow: 0; height: 40px; margin-right: 14px; width: 40px;"></div><div style="display: flex; flex-direction: column; flex-grow: 1; justify-content: center;"><div style=" background-color: #F4F4F4; border-radius: 4px; flex-grow: 0; height: 14px; margin-bottom: 6px; width: 100px;"></div><div style=" background-color: #F4F4F4; border-radius: 4px; flex-grow: 0; height: 14px; width: 60px;"></div></div></div><div style="padding: 19% 0;"></div><div style="display:block; height:50px; margin:0 auto 12px; width:50px;"><svg height="50px" version="1.1" viewbox="0 0 60 60" width="50px" xmlns="https://www.w3.org/2000/svg" xmlns:xlink="https://www.w3.org/1999/xlink"><g fill="none" fill-rule="evenodd" stroke="none" stroke-width="1"><g fill="#000000" transform="translate(-511.000000, -20.000000)"><g><path d="M556.869,30.41 C554.814,30.41 553.148,32.076 553.148,34.131 C553.148,36.186 554.814,37.852 556.869,37.852 C558.924,37.852 560.59,36.186 560.59,34.131 C560.59,32.076 558.924,30.41 556.869,30.41 M541,60.657 C535.114,60.657 530.342,55.887 530.342,50 C530.342,44.114 535.114,39.342 541,39.342 C546.887,39.342 551.658,44.114 551.658,50 C551.658,55.887 546.887,60.657 541,60.657 M541,33.886 C532.1,33.886 524.886,41.1 524.886,50 C524.886,58.899 532.1,66.113 541,66.113 C549.9,66.113 557.115,58.899 557.115,50 C557.115,41.1 549.9,33.886 541,33.886 M565.378,62.101 C565.244,65.022 564.756,66.606 564.346,67.663 C563.803,69.06 563.154,70.057 562.106,71.106 C561.058,72.155 560.06,72.803 558.662,73.347 C557.607,73.757 556.021,74.244 553.102,74.378 C549.944,74.521 548.997,74.552 541,74.552 C533.003,74.552 532.056,74.521 528.898,74.378 C525.979,74.244 524.393,73.757 523.338,73.347 C521.94,72.803 520.942,72.155 519.894,71.106 C518.846,70.057 518.197,69.06 517.654,67.663 C517.244,66.606 516.755,65.022 516.623,62.101 C516.479,58.943 516.448,57.996 516.448,50 C516.448,42.003 516.479,41.056 516.623,37.899 C516.755,34.978 517.244,33.391 517.654,32.338 C518.197,30.938 518.846,29.942 519.894,28.894 C520.942,27.846 521.94,27.196 523.338,26.654 C524.393,26.244 525.979,25.756 528.898,25.623 C532.057,25.479 533.004,25.448 541,25.448 C548.997,25.448 549.943,25.479 553.102,25.623 C556.021,25.756 557.607,26.244 558.662,26.654 C560.06,27.196 561.058,27.846 562.106,28.894 C563.154,29.942 563.803,30.938 564.346,32.338 C564.756,33.391 565.244,34.978 565.378,37.899 C565.522,41.056 565.552,42.003 565.552,50 C565.552,57.996 565.522,58.943 565.378,62.101 M570.82,37.631 C570.674,34.438 570.167,32.258 569.425,30.349 C568.659,28.377 567.633,26.702 565.965,25.035 C564.297,23.368 562.623,22.342 560.652,21.575 C558.743,20.834 556.562,20.326 553.369,20.18 C550.169,20.033 549.148,20 541,20 C532.853,20 531.831,20.033 528.631,20.18 C525.438,20.326 523.257,20.834 521.349,21.575 C519.376,22.342 517.703,23.368 516.035,25.035 C514.368,26.702 513.342,28.377 512.574,30.349 C511.834,32.258 511.326,34.438 511.181,37.631 C511.035,40.831 511,41.851 511,50 C511,58.147 511.035,59.17 511.181,62.369 C511.326,65.562 511.834,67.743 512.574,69.651 C513.342,71.625 514.368,73.296 516.035,74.965 C517.703,76.634 519.376,77.658 521.349,78.425 C523.257,79.167 525.438,79.673 528.631,79.82 C531.831,79.965 532.853,80.001 541,80.001 C549.148,80.001 550.169,79.965 553.369,79.82 C556.562,79.673 558.743,79.167 560.652,78.425 C562.623,77.658 564.297,76.634 565.965,74.965 C567.633,73.296 568.659,71.625 569.425,69.651 C570.167,67.743 570.674,65.562 570.82,62.369 C570.966,59.17 571,58.147 571,50 C571,41.851 570.966,40.831 570.82,37.631"></path></g></g></g></svg></div><div style="padding-top: 8px;"><div style=" color:#3897f0; font-family:Arial,sans-serif; font-size:14px; font-style:normal; font-weight:550; line-height:18px;"> View this post on Instagram</div></div><div style="padding: 12.5% 0;"></div><div style="display: flex; flex-direction: row; margin-bottom: 14px; align-items: center;"><div><div style="background-color: #F4F4F4; border-radius: 50%; height: 12.5px; width: 12.5px; transform: translateX(0px) translateY(7px);"></div><div style="background-color: #F4F4F4; height: 12.5px; transform: rotate(-45deg) translateX(3px) translateY(1px); width: 12.5px; flex-grow: 0; margin-right: 14px; margin-left: 2px;"></div><div style="background-color: #F4F4F4; border-radius: 50%; height: 12.5px; width: 12.5px; transform: translateX(9px) translateY(-18px);"></div></div><div style="margin-left: 8px;"><div style=" background-color: #F4F4F4; border-radius: 50%; flex-grow: 0; height: 20px; width: 20px;"></div><div style=" width: 0; height: 0; border-top: 2px solid transparent; border-left: 6px solid #f4f4f4; border-bottom: 2px solid transparent; transform: translateX(16px) translateY(-4px) rotate(30deg)"></div></div><div style="margin-left: auto;"><div style=" width: 0px; border-top: 8px solid #F4F4F4; border-right: 8px solid transparent; transform: translateY(16px);"></div><div style=" background-color: #F4F4F4; flex-grow: 0; height: 12px; width: 16px; transform: translateY(-4px);"></div><div style=" width: 0; height: 0; border-top: 8px solid #F4F4F4; border-left: 8px solid transparent; transform: translateY(-4px) translateX(8px);"></div></div></div>](https://www.instagram.com/p/2PwMcKsyVj/?utm_source=ig_embed&utm_medium=loading) [ROFL. Oh lawdy. Looks like I gave away around 27,000 copies of @iComicsApp for Free Comic Book Day. Not too bad. XD](https://www.instagram.com/p/2PwMcKsyVj/?utm_source=ig_embed&utm_medium=loading)
> 
> A post shared by [ Tim Oliver](https://www.instagram.com/timoliver/?utm_source=ig_embed&utm_medium=loading) (@timoliver) on <time datetime="2015-05-04T04:12:02+00:00" style=" font-family:Arial,sans-serif; font-size:14px; line-height:17px;">May 3, 2015 at 9:12pm PDT</time>
> 
> </div>

<script async="" src="//www.instagram.com/embed.js"></script>

## Certain Users Have Been Experiencing Instability in v1.2.5

This one has me a bit worried. I’ve been receiving emails from various users that the app has started becoming less stable than previous versions. This seems to manifest as the app crashing at very reliable points in its operation; especially when hot-jumping between comics. Sadly, I’ve been unable to replicate it on any of my own devices (Isn’t that always the case? ^\_^; ), so I’m having a Dickens of a time trying to find out what’s specifically happening. This would probably seem to imply it’s some crazy threading-issue that only happens in a specific set of conditions. The best kind of bug. ^\_^:

In any case, I’ve been planning to do a complete rewrite of the section of the app that handles loading the comic page data out of the archive files to make it more efficient on more recent iOS hardware (That code was originally written specifically to be gentle to 1st gen iPads!), but it looks like I should think about doing that sooner rather than later.

In any case, if you’ve been experiencing that problem, rest assured your concerns have been heard!

## Doing Away With iTunes Document Sharing

Now that collections have now been added to iComics, the number one feature that people have been requesting is an easier way to get comics onto their iOS devices. Up until now, the main supported way has been to plug the device into a Mac/PC and manually copy the comic files to the device by drag-dropping them into iTunes. Additionally, I recently added access to iCloud Drive so it was possible to download files from your cloud accounts that way as well.

Yes. I know. Both of these methods are really lame. 🙁

While both are the officially sanctioned ways of getting content onto your devices, iTunes Document Sharing is slow and requires direct PC access, and iCloud Drive can only do one file at a time, while also having the audacity of making you wait for the file to copy with no visible visual cue.

Because both official methods are terrible, I’m looking at re-rolling the whole implementation myself. This would include proper API access to the major popular cloud storage (Dropbox, Google Drive, Box, OneDrive etc) and local network (SMB, WebDav, WiFi) services, and a proper UI implementation to allow multiple selection of files.

So far, I’ve already more or less finished the UI implementation, and it’s going to look something like this. 🙂

![TODocumentPickerViewController](/img/posts/2015/05/TODocumentPickerViewController.jpg)

Obviously, this is going to be a huge, complex system, and I haven’t even figured out how it’s all going to slot into the app. It’s going to require a careful design consideration to ensure it’s interface is ‘generic’ enough for future services, and needs to be able to work properly in the background, even if the user decides to close the app. And it has to feel and look nice too. XD

Either way, to everyone who’s emailed me about this, or has been wondering about it, rest assured; it’s coming. 🙂

Finally, I plan to open-source as much of this as I can, so no other poor developers will have to go through the same thing. XD

## A Potential Redesign of the Comic Library UI for v2.0

A little while back, I was really happy to discover that iComics made it to [AppAdvice’s List of Best Comic Readers](http://appadvice.com/appguides/show/comic-file-readers).

![](/img/posts/2015/05/AppAdvice_iComics_Review-e1432564227152.jpg)

That being said, I was a bit disheartened to see that the reviewer found the app ‘confusing’ without any extra context on that. But after reading that, I stopped to take a step back and look at the app, and I’m beginning to agree.

The problem in iComics’ present design is that the ‘Collections’ menu, arguably the most important point of origin, is behind a hamburger menu, a design element that’s now been eschewed by Facebook and [even Apple](http://blog.manbolo.com/2014/06/30/apple-on-hamburger-menus). Even when I was building the app, when importing new comics in, sometimes it wasn’t visible that it was necessary to go to the hamburger menu in order to actually proceed. In short, the app is not conforming to traditional app design, and it’s unsurprising certain users are getting confused.

As a result of that, not now, but definitely down the line, I want to redesign how iComics organizes collections, and subsequently displays lists of comics in order to make the app more intuitive and less daunting to new users. Right now, I’m looking at the official Podcasts app, as well as [the newly redesigned Music app in iOS 8.4](http://www.theverge.com/2015/4/13/8406747/apple-ios-8-4-new-music-app) as design inspiration.

I have no idea what they meant by ‘blurry text isn’t sharpened’. That could be in reference to PDF files, which is fair since I needed to take that functionality out due to memory issues (I’ll be putting it back in later!).

## Handling Scalability for Massive Comic Collections

To add further weight behind the decision of a redesign, I’ve had several users telling me that they use their iPads as dedicated iComics devices, and that they’ve literally filled every nook and cranny of the device’s storage with comics.

We’re talking literally thousands of comic files here. Thousands. Blimey.

As humbling and awesome as that is to hear, I’m also really nervous about how well the app performs with handling that sheer number of objects. This also highlights some pretty epic bottlenecks in the app’s visual design, such as the collections column being too thin, and the comics menu taking a very long time to scroll. Aside from that, the efficiency of the system that handles loading the thumbnails for each comic might not be up to that as well.

I’ve very obviously underestimated [the power level](https://www.youtube.com/watch?v=SiMHTK15Pik) of some of iComics’ more hardcore users in terms of the app’s visual and structural architecture. As such, if and when I get the chance to do a complete redesign, I’ll also be taking those considerations into any new layouts. This would include things like full-screen and possibly nested collections menus, scroll-bars for extra large lists, more efficient thumbnail handling, more efficient sorting options, and a much more aggressive cache-cleaning solution.

## The Upcoming Version 1.3

I was aiming to try and make v1.3 the version that featured all of the new comic downloading functionality, but given that that is still a fair while away, for the time being, I’m going to make v1.3 more of an incremental update. One feature I’ve been slowing working on these past few months is a custom cropper UI (Mirroring the cropping tool in Photos.app on iOS 8) to allow users to either set up thumbnails for comics more accurately (For example, if the comic’s original cover image features the spine) or post sections of pages on social media.

![TOCropViewController](/img/posts/2015/05/TOCropViewController.jpg)

Apart from that, v1.3 will also have a few bug fixes, including fixing the broken zoom-lock bug. 🙂

No ETA, but the cropper is VERY nearly finished, so it shouldn’t be too much longer.

## Possible YouTube Series

While the majority of the reviews I get for iComics are resoundingly positive 5-star reviews, and I absolutely appreciate each one of them, every now and then, I also get some real humdinger 1-star reviews.

![iComics One Star Review](/img/posts/2015/05/iComics_One_Star_Review.jpg)

Ideally, it’d be swell if I could reach out to these guys privately and try and work out why they don’t like the app. Sadly, Apple haven’t provided any mechanism for this, so unless they come forward themselves, there’s absolutely nothing I can do.

As such, in the interests of letting these guys know that their review was indeed heard, I’m considering starting a small YouTube series where I can provide an open-letter style reply to each of these reviews, and let them know what I plan to do about it. 🙂

If you think this is a terrible idea, let me know. XD

- - - - - -

So that’s the current state of pretty much everything in iComics-land right now. Hopefully this puts everything in perspective and answers any questions you may have had.

If you’ve got any other questions, or would like me to elaborate on any of these points, feel free to post a comment below, or shoot me an email. 🙂

Thanks! Hope you enjoy iComics! 🙂