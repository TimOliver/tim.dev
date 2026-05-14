---
title: The new UITableView in iOS 5
date: 2011-10-22 00:10:36
author: Tim Oliver
image: /img/posts/2011/10/iPokedex_UITableView_Compare.png
tags: development
path: /2011/10/22/the-new-uitableview-in-ios5/
---
It was immediately obvious from the get-go that Apple had decided to change a couple of the standard UIKit elemnts in iOS 5. Does anyone here actually like the new extra curvey ON/OFF toggle views? XD

Anyway. When I was playing around with iPokédex in one of the early iOS 5 betas, I quickly noticed that another UIKit element had received a somewhat subtle, but very welcome UI overhaul: the grouped UITableView!

Here’s a picture of what iPokédex looks like when it was compiled and run under the different versions of iOS. 🙂

![](/img/posts/2011/10/iPokedex_UITableView_Compare.png)Can you see the difference? It turns out in iOS 5, the groups of table cells now sport an inset bevel effect; with a 1 pixel white highlight along the bottom, a border colour that matches the background colour (as opposed to plain grey) and a VERY soft shadow running along the inner top. 😀

It’s quite a subtle effect (Especially the inner shadow. That’s really hard to see. XD), so here’s what it looks like up close:

![](/img/posts/2011/10/iOS_UITableView_Compare_Closeup.png)

The border is a really nice touch. Instead of being a solid grey line, it’s now a semi-opaque black one, making the border instantly blend into whatever view is behind it.

Now, this actually isn’t a brand new effect. It’s been standard on the iPad’s grouped UITableView since (as far as I can recall) iPhone OS 3.2, but it appears to have now made the jump to iPhone/iPod touch. From what I can tell, the effect occurs if you change the background of the UITableView (including colour or setting a background view) to anything other than the default grey striped pattern (It keeps the solid grey border otherwise). I’m still checking if you can override that option.

In any case, I am VERY glad that this change came about. Back when I was designing iPokédex, I got really frustrated that you couldn’t easily override the border colour for the grouped table views (You basically had to[ redraw the tables yourself](http://cocoawithlove.com/2009/04/easy-custom-uitableview-drawing.html)). In a lot of the iPokédex menus that were using dark background colours, the gray sometimes made it look like the cells were just ‘fuzzy’. This new effect looks way cooler and it instantly fits with every menu I tested it with in iPokédex. I cannot wait to try it out in some of my future apps. 😀

And, after discovering this new style, I didn’t stop there. I decided that for the purposes of consistency, the UI white box elements in the header should have this awesome effect applied to them as well.

And so, after a lot of playing around in Core Graphics, I managed to write a function that draws the same effect, and applied it to all of the top UI elements. 😀

![Ooh. Shiny.](/img/posts/2011/10/iPokedex_iOS5.png)Personally, I think that looks way cooler than just plain old white boxes. And once I’ve cleaned it up a bit, I plan to post the draw code for it up here. 🙂

I dunno about you guys, but I’m looking forward to finding out more of the awesome new tidbits in the iOS 5 SDK. 😀