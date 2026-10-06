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
```c
void DrawInsetBeveledRoundedRect( CGContextRef context, CGRect rect, CGFloat radius, UIColor *fillColor )
{
    //contract the bounds of the rectangle in to account for the stroke
    CGRect drawRect = CGRectInset(rect, 1.0f, 1.0f);

    //contract the height by 1 to account for the white bevel at the bottom
    drawRect.size.height -= 1.0f;

    //Save the current state so we don't persist anything beyond this operation
    CGContextSaveGState(context);

    //Generate the rounded rectangle paths
    CGPathRef boxPath = [[UIBezierPath bezierPathWithRoundedRect:drawRect cornerRadius:radius] CGPath];
    //For the stroke, offset by half a pixel to ensure proper drawing
    CGPathRef strokePath = [[UIBezierPath bezierPathWithRoundedRect:CGRectInset(drawRect, -0.5f, -0.5f) cornerRadius:radius] CGPath];

    /*Draw the bevel effect*/
    CGContextSaveGState(context);
    //Set the color to be slightly transparent white
    CGContextSetFillColorWithColor(context, [[UIColor colorWithWhite:1.0f alpha:0.8f] CGColor]);
    //Clip the region to only the visible portion to optimzie drawing
    CGContextClipToRect(context, CGRectMake(rect.origin.x, rect.origin.y+rect.size.height-radius, rect.size.width, radius));
    //draw the left corner curve
    CGRect corner = CGRectMake(rect.origin.x, (rect.origin.y+rect.size.height)-(2*radius)-1, (radius*2)+1, (radius*2)+1);
    CGContextFillEllipseInRect(context, corner);
    //draw the right corner
    corner.origin.x = rect.origin.x + rect.size.width - (radius*2)-1;
    CGContextFillEllipseInRect(context, corner);
    //draw the rectangle in the middle
    //set the blend mode to replace any existing pixels (or else we'll see visible overlap)
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    CGContextFillRect(context, CGRectMake(rect.origin.x+radius, rect.origin.y+rect.size.height-radius, rect.size.width-(2*radius),radius+1));
    CGContextRestoreGState(context);

    /*Draw the main region */
    CGContextSaveGState(context);
    //fill it with our colour of choice
    CGContextSetFillColorWithColor(context, [fillColor CGColor]);
    //use the stroke path so the boundaries line up with the stroke (else we'll see a gap on retina devices)
    CGContextAddPath(context, strokePath);
    //fill it
    CGContextFillPath(context);
    CGContextRestoreGState(context);

    /*Main fill region inner drop shadow*/
    /*(This is done by duplicating the path, offsetting the duplicate by 1 pixel, and using the EO winding fill rule to fill the gap between the two)*/
    CGContextSaveGState(context);
    //set the colour to be a VERY faint grey
    CGContextSetFillColorWithColor(context, [[UIColor colorWithWhite: 0.0f alpha: 0.08f] CGColor]);
    //clip the shadow to the top of the box (to reduce overhead)
    CGContextClipToRect(context, CGRectMake( drawRect.origin.x, drawRect.origin.y, drawRect.size.width, radius));
    //add the first instance of the path
    CGContextAddPath(context, boxPath);
    //translate the draw origin down by 1 pixel
    CGContextTranslateCTM(context, 0.0f, 1.0f);
    //add the second instance of the path
    CGContextAddPath(context, boxPath);
    //use the EO winding rule to fill the gap between the two paths
    CGContextEOFillPath(context);
    CGContextRestoreGState(context);

    /*Outer Stroke*/
    /*This is drawn outside of the fill region to prevent the fill region bleeding over in some cases*/
    CGContextSaveGState(context);
    //set the line width to be 1 pixel
    CGContextSetLineWidth(context, 1.0f);
    //set the the colour to be a very transparent shade of grey
    CGContextSetStrokeColorWithColor(context, [[UIColor colorWithWhite: 0.0f alpha: 0.18f] CGColor]);
    //set up the path to draw the stroke along
    CGContextAddPath(context, strokePath);
    //set the blending mode to replace underlying pixels on this layer (so the background will come through through)
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    //draw the path
    CGContextStrokePath(context);
    CGContextRestoreGState( context );

    //Restore the previous CG state
    CGContextRestoreGState( context );
}
```
Whew. And there you have it. Feel free to use this code in your projects, and if you make anything awesome, let me know. 🙂

Enjoy!