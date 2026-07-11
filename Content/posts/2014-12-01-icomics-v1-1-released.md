---
title: iComics v1.1 released!
date: 2014-12-01 00:05:11
author: Tim Oliver
image: /img/posts/2014/11/iComics_v11_Released.jpg
tags: development, events, icomics
path: /2014/12/01/icomics-v1-1-released/
---
Blimey. Sorry it took so long to write this! For the last two weeks, it’s been a flurry of updating the site, sending out press releases, and responding to a mountain of user feedback, so I finally got the time to write the release announcement. XD

So! Done! After 521 days since the last update, [iComics v1.1](http://icomics.co) was approved by Apple and made live on the App Store. 521 days is an absolutely ridiculous amount of time between updates to be sure, and I plan to a post-mortem of what happened at some point, but hopefully with the new look and feel, coupled with the new features, most people can agree it was worth the wait. I’ve already started getting some reviews in, and so far, they’ve all been resoundingly positive. Thanks a lot everyone!

Here’s some of the new stuff that’s included in iComics v1.1:

- **A complete redesign for iOS 7 (and iOS 8)  
    ![iComics-iOS7-Redesign](/img/posts/2014/12/iComics-iOS7-Redesign.jpg)** To match the new look and feel Apple dropped on us mid last year, iComics has been completely redesigned from the ground up to match the new design. Gone are all of the gradients and shadows (Well… mostly), replaced by a much cleaner interface and animation set that (hopefully) match the visual style and feel of iOS 7, but also sufficiently different to not look like ‘just another’ system app. Redesigning iComics was a huge task (I’d almost call this a remake) as it required having to rethink the design and layout of all elements as well as work out how they’d all integrate together. (Arguably this is the main reason the update took so long. XD)
- **Being able to organize comics in collections  
    ![iComics-Collections](/img/posts/2014/12/iComics-Collections.jpg)** The number one requested feature since the app launched, iComics now features an integrated collections feature. This lets you group comics in separate collections and then jump them as necessary. Collections also feature an ‘override’ feature that let you bulk apply settings to comics that get moved into it. For example, if a collection is for an Eastern comic, you can set it so any comic added to it will automatically read left. The collections UI features a custom built ‘slide-out’ style menu that is only visible when you want to manage your collections, keeping it out of the way at all other times.
- **Jumping from one comic to another  
    ![iComics-Hot-Jumping](/img/posts/2014/12/iComics-Hot-Jumping.jpg)**  
    Something I dubbed ‘hot jumping’, you can now choose to automatically move to the next comic in the list when you get to the end of your current one. There’s a setting to let you see a prompt before moving, as well as one that just automatically moves you to the next one.
- **A new visual layout for comic thumbnails  
    ![iComics-Grid-View](/img/posts/2014/12/iComics-Grid-View.jpg)**  
    In the previous version of iComics, the list of available comics was a standard Apple table. This was rather limiting in that only one comic could be shown per row, and the edit controls were all stock standard Apple designed. This was always going to be a stopgap measure until I came up with something better. Spaced out over 2013 (and a little time in 2014), I built a completely custom grid view layout to replace that list view. iComics now features two view modes for comics: a large thumbnail grid version, and a ‘list’ version that heralds back to the original table design. Both view modes are powered by the same grid UI code, allowing multiple list items on one row on iPad. The view is also being backed by a new thumbnail loader system that is capable of streaming thumbnail images from disk as the user scrolls, eliminating un-necessary memory use.
- **General improvements around the code**  
    Having started writing iComics in 2011, I’ve learnt A LOT on how the system and code works in the following years, including things like best practices for concurrent processing, GPU-powered image manipulation, and just tips and tricks that I didn’t know before. As a result, I’ve also enhanced a lot of the code in the backend, especially the comic importing code to be a lot quicker.

Now that v1.1 is out the door, I’m starting to have a think about v1.2. There’s a few things I really REALLY want to add quickly, so I’m intending on making v1.2 a minor release, hopefully ready before the end of the year.

One thing I really want to do with version 1.2 onwards is to make the development of iComics a bit more transparent, and a lot more open to user input. As such, some additional things I’m working on include a system so I can live stream development, as well as a public bug/feature tracker for upcoming versions.

But for the immediate time being, I plan to have a nice vacation for a little while so I can recharge for a bit. XD

In any case, thanks a lot to everyone who got iComics! Please don’t forget to leave a review on the App Store!

Cheers! 😀

![Tim-Oliver-Cheers](/img/posts/2014/12/Tim-Oliver-Cheers.jpg)