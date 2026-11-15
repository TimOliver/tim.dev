---
title: TOCropViewController
tagline: A view controller for iOS that allows users to crop portions of UIImage objects.
layout: CodeDetail
date: 2015-06-06 00:00:00
order: 1
owner: TimOliver
language: Objective-C
langColor: #438EFF
stars: ★ 4.9k
role: Author
platforms: iOS, iPadOS
license: MIT
latest: 3.2.0
github: https://github.com/TimOliver/TOCropViewController
image: /img/code/tocropviewcontroller/screenshot.jpg
path: /code/tocropviewcontroller/
---

This is probably the most impactful piece of software I've ever (accidentally) created.

While building iComics, I needed an image cropper, so users could share parts of a page, or fine-tune a comic's thumbnail in their library.

There were a few open source cropping libraries around, but none had been updated for iOS 7's new design language. Seeing a real gap, I decided to put the effort into making a _really good_ cropping library, and then open source it so everyone could benefit.

It took a couple of months to build, and I published it on GitHub in 2015. It was optimized to the nth degree so it ran smoothly even on an iPad 2, and felt fluid and intuitive to use.

What I didn't realize until much later was just how many iOS developers needed something like this. The use cases for a cropping library turned out to be huge, from photo editing apps to setting profile pictures in social apps.

Fast forward to today, and TOCropViewController is used in apps from huge companies including Google, Discord and TikTok. According to 42Matters, apps containing it have been downloaded from the App Store over 40 billion times.

I'm incredibly thrilled and humbled to have made something so many developers have found useful. One day, I'd love to try a native Swift rewrite to see how much faster I can make it.
