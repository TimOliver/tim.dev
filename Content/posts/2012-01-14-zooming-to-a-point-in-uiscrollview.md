---
title: Zooming to a point in UIScrollView
date: 2012-01-14 18:01:05
author: Tim Oliver
image: /img/posts/2012/01/UIScrollViewZoomToPoint.jpg
tags: development, tech
path: /2012/01/14/zooming-to-a-point-in-uiscrollview/
---
*(Updated March 2015) I’ve rewritten the code for zooming to a CGPoint in a UIScrollView to be even better in a new blog post. [Go check it out!](/2015/03/31/zoom-to-a-point-in-a-uiscrollview-2015-edition/ "Zoom to a point in a UIScrollView (2015 Edition)")*

![](/img/posts/2012/01/iOS_ZoomToPoint.jpg)If there’s one piece of functionality that has become basically boilerplate on iOS, it’s the concept of double-tapping a zoomable UIScrollView to quickly zoom in on a given point. When I was writing the code for displaying pages in iComics, I assumed that this would be a really simple thing to do. I mean, surely all you’d need is a [UITapGestureRecognizer](http://developer.apple.com/library/ios/#documentation/uikit/reference/UITapGestureRecognizer_Class/Reference/Reference.html) attached to a UIScrollView that passes the location of any double-taps to the scroll view… right?

[Nope.](http://www.youtube.com/watch?v=gvdf5n-zI14) XD

Turns out that although there is a UIScrollView method called ‘[zoomToRect](http://developer.apple.com/library/ios/documentation/uikit/reference/UIScrollView_Class/Reference/UIScrollView.html#//apple_ref/occ/instm/UIScrollView/zoomToRect:animated:)‘ (which lets you zoom to a specific CGRect region of a UIScrollView), out-of-the-box, there is no official way to procedurally zoom into a specific CGPoint. This actually surprised me greatly since I would have thought it would be a standard part of UIKit.

In any case, I did a bit of searching around on Google, looking for some code that would let me do this easily. I found a few bits of code here and there, however they were written in such a way that unless the minimum and maximum scales of the scroll view were set up in a specific way (Uh, which in iComics’ case, they weren’t), the zooming wouldn’t work properly at all.

So, cutting to the chase, I decided to just roll my own category for UIScrollView to add that functionality to it. All it does is take a CGPoint (relative to the bounds of the scroll view itself) and a scale, and translates those to a CGRect that can then be passed to UIScrollView’s drawToRect method. 🙂

Here’s what it looks like:  
<script src="https://gist.github.com/TimOliver/6138097.js"></script>  
Looking at it, it should be pretty straightforward to figure out how it works. If you see anything wrong with it, let me know in the comments. As always, feel free to use this code in any of your projects, and let me know if you make anything awesome with it. 🙂