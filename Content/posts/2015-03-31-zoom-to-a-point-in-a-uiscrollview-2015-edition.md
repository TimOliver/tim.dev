---
title: Zoom to a point in a UIScrollView (2015 Edition)
date: 2015-03-31 21:16:07
author: Tim Oliver
image: /img/posts/2015/03/UIScrollView-ZoomToPoint2015.jpg
tags: development
path: /2015/03/31/zoom-to-a-point-in-a-uiscrollview-2015-edition/
---
A long, LONG time ago, I wrote a blog post on [zooming to a point in UIScrollView](/2012/01/14/zooming-to-a-point-in-uiscrollview/). Even today, 3 years later, zooming to a point still isn’t a default feature of [UIScrollView](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIScrollView_Class/), and so with that functionality still being in hot demand, that original post has ended up becoming one of the most active links on my blog.

Sadly, over the years, I started receiving reports from various people using that sample code that in a lot of different scenarios, that code was actually broken. While it would work fine if the scroll view was completely zoomed out (Which was fine for iComics’ needs), if you were zoomed in at all, then the resulting zoom behavior would be incorrect. Not only that, I discovered a unique scenario in iComics where if the scroll view’s content size was of a particular shape and VERY slightly zoomed in (To a decimal fraction amount), then that code would utterly break, and the scroll view content would fly off-screen.

As a result of that catastrophic error, this year, I decided to delete that original zooming code, and rewrite the lot from scratch. Not only would this fix the broken functionality, but it also made a new feature of iComics v1.2.5, where tapping multiple times results in different zoom levels, possible.

<script src="https://gist.github.com/TimOliver/71be0a8048af4bd86ede.js"></script>

This time, the zoom code is smart enough to realize when it’s zoomed in, and to compensate accordingly. I also incorporated iOS 7’s new animation API, so it ‘feels’ a lot smoother too than the ‘linear’ animation of the previous code.

As always, this code is in the public domain. No attribution is required, but please let me know if you do end up using it. 🙂