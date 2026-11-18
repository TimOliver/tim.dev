---
title: iComics 2, work, and the future of this blog
date: 2022-05-06 15:54:47
author: Tim Oliver
image: /img/posts/2022/05/iComics-2022.jpg
tags: personal, tech, icomics
path: /2022/05/06/icomics-2-work-and-the-future-of-this-blog/
---
I hope everyone’s been having a great 2022 so far. This week was [Golden Week](https://en.wikipedia.org/wiki/Golden_Week_(Japan)) in Japan, and I personally had a fantastic, relaxing week of doing some long overdue cleaning, catching up on emails and hanging with friends.

I figured I’d do a *super* quick update on what I’ve been up to lately, and what I’m hoping to do this year.

## Work

I haven’t mentioned it here yet, but I officially joined Instagram in February! 🎉 I’m working in a small team called IG Labs that is based out of the Meta office in Tokyo, building experimental new features for the Instagram iOS app. So far I’ve been having an absolutely fantistic time at the company. The company has done a fantastic job at writing code for the app frictionless, and the company culture is amazing. I spent a large part of 2021 preparing for the interviews, and when I have a bit more free time, I’ll talk about my journey to Instagram in another blog post. But in any case, I feel really fortunate to have started such an amazing new opportunity. And I’m hoping with this new work-life balance, I’ll be able to focus more time on my own projects as well.

## iComics 2

So. Yeah. iComics 2 progress has been pretty slow. The reason for this is that I’ve come up against an engineering challenge that made me stuck pretty badly. I’ve been R&Ding a solution to this problem since 2020, and I THINK I’ve nearly solved the problem. 😁

To quickly sum up the problem. The resolution of comic pages has steadily been growing over the years. When I first started iComics 1, most comic book pages had resoltutions of 1,000×1,500, which was really manageable. Nowadays, most comics are at least 3,000×4,500, and I’ve even seen some comics on Humble Bundle go as high as 9,000×14,000!

At the moment, iComics 1 just uses the regular iOS graphics system to extract the page from the ZIP file, and display it on screen with zero processing. Since iOS itself is built on top a 3D graphics engine, just like in video games, when super large images are shrunk to fit the screen of smaller devices (like an iPod touch), they start to look really “shimmery”.

Here’s an example of what a large image looks when shrunk down.

![](/img/posts/2022/05/iComics1-Sampling.jpg)

Now, the obvious solution to solve this would be to make a copy of the image and shrink it down to the same size as an iPod screen. However, if the user wanted to pinch in at all from that size, the image will be super blurry. To solve this, I’d need extra copies of the image at bigger sizes I could snap to as the user pinches.

And it turns out this was totally a solved problem in 3D video games all this time. I’d somehow arrived at the concept of [mipmapping](https://en.wikipedia.org/wiki/Mipmap) in a very roundabout way. 🤣

Unfortunately, UIKit, iOS’s main graphics API doesn’t support mipmapping to this level of control. And so after several months of research, I built a proof-of-concept of a mipmapped texture that solved the problem directly on top of [Metal](https://en.wikipedia.org/wiki/Metal_(API)), Apple’s lowlevel graphics API.

Here’s how it’s looking now. 😁

![](/img/posts/2022/05/iComics2-Sampling.jpg)

This is still a WIP however, and I’m still not 100% convinced this will do the job. But if I can successfully get this running in iComics 2, that will be the biggest hurdle I need to clear before launching it. Either way, I’m really excited about it.

## iComics 1

For the record, [I stand with Ukraine](https://standwithukraine.live/). Earlier in the year, I pulled iComics from the Russian App Store, and I donated about $500USD to the Ukraine. If you have any money to spare, I would encourage you to do the same.

I really want to do one more big push on iComics 1 and deliver a pile of the features I’ve promised as a final “hoorah” before committing fully to iComics 2. I’ve got dual page spread working in the app already, however, I wasn’t able to get my mipmapping solution I mentioned above working in such an old codebase.

Thankfully, for iComics 1, since it won’t need Mac support, I think I can create a modified version of the mipmapping system that will do the job “good enough” for dual page spread’s needs, and saving the ultra good stuff for iComics 2.

I’ll continue to stream working on iComics 1 code on Twitch. Please feel free to follow me and come say hi over at [http://twitch.tv/timXD](http://twitch.tv/timXD)!

## This Blog

I’ve been thinking about this lately. This blog is coming up on 10 years with its current appearence and I’m starting to think it’s time for a change. A big reason why I don’t blog a lot is because of the amount of “friction” I have when writing posts. I always have to Photoshop some kind of banner image, and WordPress, while great, can be quite slow to run at times. And since I’m running a self-hosted instance of WordPress, there is a fair bit of maintenance overhead, constantly installing security updates, and verifying all my plugins are still working.

Since I’m really only serving static content on this blog, I’m considering migrating the whole lot to [Jekyll](https://jekyllrb.com/). I’ll try and keep all of the current content and functionality (Including comments via Disqus!), so please stay tuned for that.

And on that note, have a fantastic May!
