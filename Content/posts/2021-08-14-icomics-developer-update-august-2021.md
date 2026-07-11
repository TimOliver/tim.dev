---
title: iComics Developer Update (August 2021)
date: 2021-08-14 01:03:14
author: Tim Oliver
image: /img/posts/2021/08/Free-Comic-Book-Day-2021.jpg
tags: events, tech, icomics
path: /2021/08/14/icomics-developer-update-august-2021/
---
Hey everyone! I hope you’ve been well and staying safe!

In case you missed it, today is Free Comic Book Day! Yayyy! As has been tradition for a while, [iComics](http://icomics.co/app) is free for today. If you’ve been on the fence about it for a while, go grab it now! Don’t feel bad for getting it for free, but if you end up liking it, please give it a review on the App Store!

If you need some places to get some comic books to read for it, at the moment I can recommend:

- [The Isekai Pack at Humble Bundle](https://www.humblebundle.com/books/isekai-kodansha-books?hmb_source=&hmb_medium=product_tile&hmb_campaign=mosaic_section_1_layout_index_2_layout_type_threes_tile_index_1_c_isekaikodansha_bookbundle)
- [The Judge Dredd Pack at Humble Bundle](https://www.humblebundle.com/books/judge-dredd-perps-punks-partners-2000ad-books?hmb_source=&hmb_medium=product_tile&hmb_campaign=mosaic_section_1_layout_index_1_layout_type_threes_tile_index_3_c_judgedreddfriendsrebellionpublishingtbd_bookbundle)
- [The DRM-free selection at Comixology](https://www.comixology.com/DRM-Free-Comics/page/2794?tid=W140717001&utm_source=cmx_hompage&utm_medium=DRM_Free&utm_campaign=W140710001_DRM_Free)
- [The selection at DriveThruComics](https://www.drivethrucomics.com)

If you know anymore good places for DRM-free comics, please let me know in the comments!

And while I’m at it, let me do a brief developer update as well.

## iComics (The OG one)

Earlier this year, I replaced [iComics’ archive file reader](https://github.com/iComics/XADMaster) (The thingy that can open up ZIPs/RARs/7ZIPs to get at the page image files) to the latest version provided by the folks at [MacPaw](https://macpaw.com). This included support for much needed newer formats like RAR5, but sadly introduced some other issues into the app. Thanks to the folks who reported those; I’ve fixed some of them and shipped a release, but I’m aware there’s still some lingering issues.

As usual, with everything going on at the moment, I can’t spare the time to fix these issues just yet, but I’ll try and get to them as soon as I can. The biggest issue I can see is if you [import a solid archive](https://documentation.help/WinRAR/HELPArcSolid.htm), that seems to behave strangely, so I’d recommend just avoiding those for now.

In any case, I hope you enjoy the latest update, and please let me know if you find any other bugs.

## iComics 2

[As I announced at the very start of 2020](/2020/01/01/announcing-icomics-2/), before all of the craziness started, I’m working on a ground-up rewrite of iComics, tentatively called iComics 2.

The reasoning why this isn’t simply a new version on top of OG iComics is for a few reasons:

- iComics 1 is written in [Objective-C](https://en.wikipedia.org/wiki/Objective-C), whereas iComics 2 is written in [Swift](https://en.wikipedia.org/wiki/Swift_(programming_language)), which is faster to write and is able to guarantee less crashes.
- iComics 1 was written during the time of the [OG iPad](https://en.wikipedia.org/wiki/IPad_(1st_generation)), and so at a foundational level, it’s not capable of scaling to the capabilities of iOS devices today. Changing it to this extent is a rewrite in itself.
- In order to make things a bit more legit than they are now, I’m planning to publish iComics 2 as a company, not as an individual, and so it will be under a separate Apple account on the App Store.

Progress on iComics 2 has been slow, but has been extremely promising. I had a lot of momentum for it in the first half of 2020, but I’m sure you can imagine that given the current circustances, I ended up taking a break from it, and only started it back up about 2 months ago.

The reason it’s been slow is because of a lot of unsolved questions I’ve had on how to make it scale to modern devices, like the M1 iPad. Spreading out page loading to all of the cores is easy, but the challenge then is how to not accidentally consume all the RAM if all of the cores try and load in massive images at the same time.

Thankfully, these past few weeks have been super fruitful, and I’ve managed to find good solutions to all of the problems I’ve been having. So while I don’t have anything visual to show yet, I hope I will soon.

In any case, for the folks still hanging out for iComics 2, thanks for your patience. I hope it will be worth it. 😀

## Conclusion

In any case, I hope you have a fantastic Free Comic Book Day! And if you have any feedback on either iComics 1 or 2, please leave a comment!

Take care, and stay safe!