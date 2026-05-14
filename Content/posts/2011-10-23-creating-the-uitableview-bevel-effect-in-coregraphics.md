---
title: Creating the iOS 5 UITableView bevel effect
date: 2011-10-23 02:43:37
author: Tim Oliver
image: /img/posts/2011/10/UITableView_Bevel_Example.png
tags: development
path: /2011/10/23/creating-the-uitableview-bevel-effect-in-coregraphics/
---
So, as you might be aware now, Apple decided to give a bit of an [overhaul to the grouped UITableViews](/2011/10/22/the-new-uitableview-in-ios5/) where each of the table sections now have a cool inset bevel effect as opposed to a solid gray line.

![](/img/posts/2011/10/UITableView_Bevel_Example.png)

When I was playing with iPokédex in the iOS 5 betas, I started thinking that the new table style started contrasting with the plain white boxes in the table header (eg for the main profile pic and the buttons).

So deciding to keep the entire list style as consistent as possible, I decided to replicate the bevel effect as a CoreGraphics function that I could then apply to all of my own custom subviews. While I was initially thinking of doing the whole thing as a static stretchable image in Photoshop, it became apparent that due to the various sizes of the elements, being able to programmatically set the size of the corner radii would ultimately be a lot easier (Hooray for programming making stuff lazier! XD).

So after a couple of hours of examining the effect pixel by pixel in Photoshop, I found out that it’s a pretty simple effect to draw, but it would require 4 layered steps to actually draw properly:  
  
![](/img/posts/2011/10/UITableView_Bevel_BreakDown.png)

The input parameters are pretty simple. We have a CGRect-defined region to draw in, a radius value to denote the size of the corners, and a UIColor to denote the actual fill colour of the region.

After using the draw region struct and radius to create a rounded rectangle CGPath, we can perform the following steps with it to draw the view (starting from the bottom):

1. **The underlying bevel effect (All white, with 80% opacity)**  
    This is the 1 pixel bevel effect draw outside of the stroke at the bottom of the effect. Despite what you might think, it’s not simply a matter of offsetting the fill region by 1 pixel. The path doesn’t actually move at all, rather it is scaled vertically by 1 pixel, so the bevel effect pokes out from underneath the main fill region. The point of this is that it makes the bevel effect perfectly blend into the rounded edges, rather than leaving a 1 pixel line all the way around (this is especially noticeable on retina devices). Whether this is possible to do via manipulating the current transformation matrix, I’m not sure, so I ended up creating the bevel by drawing 2 ellipses and a rectangle.
2. **The main fill region (Defined from the function parameters)**  
    Nothing special here. We just fill the CGPath with the CGColor fill colour of our choice.
3. **The inner shadow (All black, with 8% opacity)**  
    This one required a fair bit of research. I was initially going to use the CoreGraphics drop-shadow feature. However, after examining the shadow effect on both my iPad and my retina iPhone, I found out that the shadow isn’t blurry at all, (it’s just one pixel) so that would have been overkill. In the end, the easiest way I found was to add 2 instances of the CGPath, the second being 1 pixel lower than the first, and then use the [even-odd winding rule](http://developer.apple.com/library/ios/#documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_paths/dq_paths.html#//apple_ref/doc/uid/TP30001066-CH211-TPXREF106) to fill in the gap between the two.
4. **The outer stroke (All black with 18% opacity)**  
    And finally, to lock in the effect, the outer stroke. The stroke was just a normal stroke operation, but with the blending mode set to ‘copy’ so any pixels it drew over were replaced as opposed to blended. This ensured the background would show through the stroke properly, sealing in the effect.

And finally, after all of that, here’s how the code looked in the end. 🙂  
<script src="https://gist.github.com/TimOliver/6139167.js"></script>  
Whew. And there you have it. Feel free to use this code in your projects, and if you make anything awesome, let me know. 🙂

Enjoy!