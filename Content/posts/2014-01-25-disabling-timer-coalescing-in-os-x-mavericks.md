---
title: Disabling Timer Coalescing in OS X Mavericks
date: 2014-01-25 14:06:08
author: Tim Oliver
image: /img/posts/2014/01/Xcode5_iOS6_Terminal.jpg
tags: development, tech
path: /2014/01/25/disabling-timer-coalescing-in-os-x-mavericks/
---
If you’re an iOS developer, and you’re still developing apps that support iOS versions below iOS 7 (Like I am), then you might have noticed after upgrading to OS X Mavericks that the iOS 6 Simulator runs absolutely terribly. EVERY single animation in there runs at an incredibly choppy frame-rate, which makes most kinds of app testing relatively useless.

Today, I learnt from a little birdie that the reason for this issue is due to the new *Timer Coalescing* feature, introduced in Mavericks:

> In OS X Mavericks, Timer Coalescing groups low-level operations together, creating tiny periods of idle time that allow your CPU to enter a low-power state more often. With its activity reduced up to 72 per cent, the CPU uses less energy, giving your battery a break too. This happens so fast you won’t notice a thing. And your Mac still gets just as much done just as quickly.
> 
> [Apple – OS X Mavericks – Advanced Technologies](http://www.apple.com/osx/advanced-technologies/) (January 2014)

It would seem to make sense that as a result of Timer Coalescing, the timers that power the iOS 6 Simulator animations are getting coalesced themselves, and this is resulting in the strange behaviour (Curiously enough, the iOS 7 Simulator is fine though!).

In any case, apparently there is a console command that lets you disable Timer Coalescing across the system:

<script src="https://gist.github.com/TimOliver/8612227.js" type="text/javascript"></script>

I tested it on my Mavericks Retina MacBook Pro and I can confirm that it works, and the iOS 6 Simulator works perfectly again!

I probably should mention though, by disabling Timer Coalescing, this will lower the battery efficiency of Mavericks. Although, it’ll probably be no less than what it already was at with OS X Mountain Lion.

Enjoy!