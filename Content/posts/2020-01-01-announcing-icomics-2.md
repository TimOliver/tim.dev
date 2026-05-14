---
title: Announcing iComics 2.
date: 2020-01-01 23:54:56
author: Tim Oliver
image: /img/posts/2020/01/iComics-2.jpg
tags: development
path: /2020/01/01/announcing-icomics-2/
---
Hi everyone! Happy New Year! I hope you had a fantastic start to this decade. I’m extremely excited at all the potential in 2020, and I hope you are too.

I was doing a little reflecting recently and I came to a bit of a scary realisation. I’ve been hacking away on iComics, my little comic reader app for nearly 10 years now.

It was 2010 when I bought the very first iPad. I was so impressed at the potential it brought to the table. A full-colour, high-powered computer screen shaped like a normal piece of paper. Compared to laptops and PCs, it could be comfortably held and operated at any angle; an absolute game-changer when it came to reading comic books.

Having decided my niche would be a DRM-free comic reader, in December 2011, I started working on a proof-of-concept of the app to see if it was possible. At the start of 2012, I announced my intention to build a comic reader app, and launched the first version in late 2012.

I’ve since been adding to it piece by piece ever since. And while it’s no where as near as good as I had hoped it to be, I think it’s been a huge success. Not only has it provided a platform many people have found really useful, the knowledge I gained in the process has allowed me to make iOS engineering my full time profession.

So I really can’t overstate this enough. Building iComics has been one of the best and most rewarding experiences in my life. And to all the people who took a chance on me and bought it: thank you so very much.

But. Now that we’re looking down the barrel of a new decade, I’d like to talk about what my plans for iComics are from here.

To be frank, the quality of the codebase in iComics is pretty dismal. I had been developing iOS apps for 2 years when I started working on the app, and looking back, I knew very very little about how to properly build iOS apps, and that shows in the foundations of the app.

In addition, iOS hardware was much more limiting. The first iPad was non-Retina, had a single core CPU, and only had 256MB of memory. Positively the stone ages by today’s standards! And because of that, I architected iComics in a such a way that it’s not taking advantage of the amazing CPUs we have today.

And on top of that, I started building the app back when iOS 5 was brand new. Back then, iOS was no where near as feature rich as it is now, and in order to achieve a lot of things we take for granted today (Such as state restoration between launches) were things I built myself. In these days, that code is completely un-necessary, and in all realism, completely inferior to the native solutions Apple has provided over the years.

So. I’ve been thinking about this for several years now, but I want 2020 to be the year in which I take everything I’ve learned from iComics and use it to start building an even better comic reader.

And for now, I’ve decided to call it iComics 2. It is my intention to make it the de-facto comic reader app for iOS. 😀

## How will this affect iComics 1?

This won’t be a simple upgrade to iComics 1. It’s going to be a completely new app. For now, iComics 1 isn’t going anywhere, and I’m still working on an iOS 13 update to it right now.

But from now on, I want to start writing code with the mindset that it will be modular enough that it can be re-used in iComics 2 as well.

I don’t expect iComics 2 to reach feature parity for a long time, so I’m tentatively planning putting both on the App Store at the same time. Once iComics 2 has reached parity, I’ll take iComics 1 off the store.

## How will it be written?

Ideally, I don’t want to re-invent the wheel too much. The idea this isn’t a complete rewrite, more that I can cherry-pick and re-use as much as I can from iComics 1.

I’ve been working for the past few years by making new components as separate modular libraries, and then dropping them into the codebase. This has been fantastic way to promote code quality, and clean separation of concerns. In order to share code between iComics 1 and 2, I’ll be doing this a lot more, and designing all of the interfaces with that in mind.

## Which language will it be written in?

Every iOS developer who knows me knows I’m still a big proponent of Objective-C. I should write a blog post separately why this is, but the overall tl;dr is that I feel really experienced at Objective-C, and not so much in Swift. And so while Swift promises to be faster to develop for, and to yield safer, more stable code, I’m still convinced I can do a much better job at delivering quality software in Objective-C than Swift.

But that being said, I’ve been writing Swift for my day job for the past 3 years, and I’ve slowly started to see a lot of the big wins it has over Objective-C. Definitely the most appealing thing is the sheer amount of code you *don’t* have to write. A fantastic example of this was [when Brad Larson rewrote GPUImage in Swift](http://www.sunsetlakesoftware.com/2016/04/16/introducing-gpuimage-2-redesigned-swift), and managed to achieve 75% less code, but maintain feature parity with the Objective-C freamework. That was super compelling right there!

But no matter what sort of benefits/deficit arguments I could make, the truth is that it’s a complete no-brainer to start any new projects in Swift.

BUT. On that note. Since I still want to share code between iComics 2 and the 100% Objective-C iComics 1, I’m going to have to offer a compromise.

The main app, and all of its business logic will be Swift. However any third party libraries I build that are intended to be used in both apps will continue to be Objective-C.

## Monetization

iComics 1 has sold really well over the last few years. Far too well than it should have any right. I’ll definitely need to do a blog post at some point, but the app has definitely proved that up-front payments is still a viable business model on the App Store.

But as my goal for iComics 2 is to become the de-facto reader, I really feel the paywall needs to be completely removed. On the same note, I’ve discovered that a super cheap one-time payment isn’t really sustainable either.

So for now, I’m considering this. The app will be free while it’s not on feature parity with iComics 1. This will let people grab it and play with it super early, and begin to offer feedback. And if they like it, they can still buy a copy of iComics 1.

Once feature parity is met, I’m considering the tried and true method of having in-app ads, with the option of a yearly subscription to hide them. This is the model that [Overcast](https://overcast.fm) made popular and I definitely believe that when done right, this is can be a really nice experience.

I’m also debating that in addition to subscriptions, offering a one-time “lifetime” in-app purchase for those who hate subscriptions.

## Will it be open source?

I believe open source is a fantastic way to let people contribute, to have 100% transparency, and to serve as a learning tool for others.

That being said, since I am hoping on monetising this thing, I don’t want the source code to be so permissive that anyone could release their own product based on it without my permission.

As such, I’m exploring releasing it under the [Patron License](https://github.com/licensezero/patron-license) where it’d be free to use personally, but you’d be obligated to pay me if you wanted to build your own product out of it. 🙂

## The name

Let’s be real here. iComics as a name is terrible. ^\_^; Not even Apple names their new products in that format anymore.

I originally picked it because the original name I wanted was taken, and I considered it a “pledge” to make the quality of the software as good as Apple’s. However that kind of backfired to a horrifying degree in that the quality of the app has dropped, and also many would argue that the quality of Apple’s software has also dropped.

But thankfully. In the giant 32-bit app purge of 2017, the name I originally wanted became free again. And I was able to snap it up. 😀

So on that note, I won’t reveal the name just yet, but it will 100% have a different name than iComics 2 by launch.

## Keeping track of progress

I haven’t done a great job these past few years of keeping people up-to-date on the app. Between being super busy with work, and wanting to just code, writing blogs and making YouTube videos is just too much effort.

So instead, this year, I’m going to go back to just Instagram and Twitter. Ideally, I’ll try and find a way to link updates to directly inside the app.

I’ll also try my hardest to set up regular Twitch streams in case anyone wants to watch. 🙂

- - - - - -

So hopefully we’ll see how this goes this year. For now, I need to focus on the iOS 13 update to iComics, but I’ll keep everyone up to date on what I’m doing as much as I can.

In any case, if you have any suggestions or feedback, please let me know.

Have a great year! Hopefully it’ll be a blast!