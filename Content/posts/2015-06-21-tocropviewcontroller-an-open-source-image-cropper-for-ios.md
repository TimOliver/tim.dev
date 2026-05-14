---
title: TOCropViewController – An open source image cropper for iOS
date: 2015-06-21 13:31:14
author: Tim Oliver
image: /img/posts/2015/06/TOCropViewController-on-Gold-MacBook.jpg
tags: development
path: /2015/06/21/tocropviewcontroller-an-open-source-image-cropper-for-ios/
---
Over the years, I’ve built up a pretty crazy [list of features that I want to add to iComics](https://github.com/iComics/iComics-Issues/issues). One feature on that list that’s been kicking around since pretty much day 1 has been the ability to crop page images.  
  
Photo cropping as a native feature is not new to iOS. It was originally introduced in iOS 5 wayyy back in 2011, and was touted during the unveiling of the iPhone 4S.

![iPhone-4S-Cropper](/img/posts/2015/06/iPhone-4S-Cropper.jpg)

Since then, it’s only gotten WAY cooler in iOS 8.

![iPhone-6-Cropper](/img/posts/2015/06/iPhone-6-Cropper.jpg)

I’ve wanted the ability to crop page images in iComics for mainly two reasons: to make comic thumbnails more configurable, and to make posting small portions of comic pages to social media possible. I’m also considering persistent image editing down the line as well, but that still requires a bit of research.

Sadly, Apple has never made the cropping feature of the Photos app accessible to third party apps. As a result of this, a LOT of third party cropping libraries have popped up over the years to get around the solution. Most notably, [Katsumi Kishikawa](https://github.com/kishikawakatsumi)<span style="line-height: 1.5;">, one of my colleagues from </span>[Realm](http://realm.io)<span style="line-height: 1.5;"> released quite possibly the </span>[best iOS 5-styled cropper library](https://github.com/kishikawakatsumi/PEPhotoCropEditor)<span style="line-height: 1.5;"> on GitHub.</span>

![PEPhotoCropper](/img/posts/2015/06/PEPhotoCropper.jpg)

Initially, I was looking forward to using this one in iComics. But sadly, when iOS 7 hit, I was forced to put that feature on the back burner while I redesigned my app. When I finally had the app ready, iOS 8 had come around, and the cropper’s design both started looking dated, and was behaving strangely on my iPhone 6 Plus. Katsumi’s told me that he does want to upgrade the cropper at some point, but sadly simply hasn’t had the time lately.

As a result of all of that, I decided that it might be worth to write a new cropper from scratch after all; something designed from the start to match what users were already expecting on iOS 8. After a quick proof-of-concept, I started writing some code in March this year, and posted the finished library to GitHub two weeks ago:

![TOCropViewController-WWDC](/img/posts/2015/06/TOCropViewController-WWDC.jpg)

Named [TOCropViewController](https://github.com/TimOliver/TOCropViewController), the goal of this library was to provide the ability to crop a UIImage object and either return it to an object, or immediately share it. It was designed with the iOS 8 Photos app in mind, taking advantage of the system translucency and springy iOS 7 animations. As a few extra niceties, it also allows rotating images in 90-degree chunks and aspect-locking the crop box.

In terms of how everything actually works, here’s a 3D breakout of what layers comprise the view:

![TOCropViewController Breakdown](/img/posts/2015/06/TOCropViewController-3D-Breakdown.jpg)For most normal cropping implementations, it makes sense to simply have 4 views overlaying the image, creating the square ‘hole’ in the middle denoting which region will be cropped. Since having to do that with both the translucent layer, and the dimming layer was looking to be quite complex, I opted to try a new approach: place a copy of the image above the layers, clipped to a view that was denoting the cropping region, and then automatically line up the foreground image with the background image. This ended up working flawlessly, creating the illusion that there is a ‘hole’ in the middle of the view, and minimising the amount of views on screen needed to create that effect.

In any case, this was definitely one of the harder views I’ve worked on. There were a LOT of alignment issues involving the crop box and the floating point precision of the scroll view, so I spent a fair bit of time simply making sure float values were being clipped to integer values properly throughout the class.

Now that the view is finished, I’m very happy with the results and can’t wait to get it up and running in iComics as soon as I can. If you’re also writing iOS software and would like to use this library, it’s [available on GitHub](https://github.com/TimOliver/TOCropViewController) under the MIT license.

Enjoy!