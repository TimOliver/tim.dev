---
title: iComics v1.1 Post-mortem
date: 2014-12-30 23:30:20
author: Tim Oliver
image: /img/posts/2014/12/iComics_v11_Postmortem.jpg
tags: development, icomics
path: /2014/12/30/icomics-v1-1-post-mortem/
---
So it’s been about a month and a half since iComics v1.1 shipped, and v1.2 is in review with Apple right now. I was so busy getting it ready to ship that I clean forgot about 2 important milestones for the app: On September 25th, the app has been on the App Store for TWO years now, and on November 1st, its codebase has been around for three years. Blimey! XD

In any case, now’s as good a time as any to reflect on how v1.1’s development went, what went well, and what sucked about it.

To be absolutely frank, I’m not thrilled about how long v1.1 took. All in all, the app ended up going 521 days; very close to a year and a half without any updates. Absolutely unacceptable for an app trying to stay relevant on the App Store, and I wasn’t surprised at all when a bunch of users had told me they’d jumped ship to other readers in the interim (Though a few told me they jumped back after the update).

In any case, there are a few things I want to highlight.

## The iOS 7 redesign

Not going to tiptoe lightly on this one. Apple suddenly dropping a completely new system design basically derailed iComics’ development. Compiling the app under the iOS 7 SDK yielded a completely broken UI mess, and with Apple imposing a restriction that apps had to ship with the iOS 7 SDK pretty soon after release, it wasn’t possible to push out an update until the lot was completely redesigned and reimplemented. Design aesthetics aside, the reimplementation of a lot of core system ‘assumptions’ as well, including things like how apps interact with the status bar, and the order of system calls when the device plays a rotation animation meant a great deal of the old code had to be heavily modified or even scrapped to get the app ‘feeling’ like it did in iOS 6 under iOS 7.

A lot of other apps with heavily customized iOS 6 designs, like [Tweetbot](https://itunes.apple.com/au/app/tweetbot-3-for-twitter.-elegant/id722294701?mt=8) took the chance to use iOS 7 as a new starting point for themselves; rebuilding the apps from scratch with the new UI and shipping as a completely separate version. I was tempted to do the same for iComics, but I eventually decided that v1.0 wasn’t feature-rich enough to warrant ditching it and making users pay again. Unfortunately, this also meant things like keeping compatibility with the old version was also a challenge.

In the end, I think it was the right thing for Apple to redesign iOS when they did (I still don’t agree with a lot of the design choices in iOS 7/8. Also, most of the system icons still look like ass. XD), but it did make my job significantly harder for a while there.

## Heavy reliance on custom elements

Given recent events, I’m changing my mind on this one.

I have a bit of a nasty habit of reinventing the wheel a lot. If there are no third party code bases that I find satisfactory, or if I even find Apple’s own implementation of certain code unsatisfactory, I’ll often go out and write my own from scratch. Some prime examples inside iComics include [TOWebViewController](https://github.com/TimOliver/TOWebViewController) and [TOGridView](https://github.com/TimOliver/TOGridView) respectively. Writing my own libraries is certainly advantageous as it gives me 100% over how the elements behave, which lets me craft the overall experience of the app to my complete satisfaction.

The downside however, is the sheer amount of time it takes to build and test said libraries. Both of those libraries mentioned above took literally weeks to implement. And when iOS 8 came out, both required additional fine-tuning then as well. At this point, I definitely think they’re the right libraries for the job. TOGridView is, in my opinion far more performant that UICollectionView, and TOWebViewController has also shipped in other apps at this point. But admittedly, I could have easily just gone with stock Apple controls, or another web controller off GitHub and the app would have been finished earlier. I guess the question is, I would certainly notice the difference in quality, but would the users notice?

That being said, like I mentioned above, since iOS 8 came out, I’m starting to lean towards writing custom controls than using Apple’s a lot more often. When iOS 8 dropped, a LOT of UI code, specifically involving layering view controllers (that iOS 8 reimplemented) that worked fine in iOS 7 broke horrendously in iOS 8. Popup bubbles wouldn’t dismiss, or presenting a full-screen view controller would run really slowly as the background controllers weren’t removed. I flagged all of these as bugs with Apple, which are still open in Apple’s bug tracker tooth’s day. Ultimately, I was able to solved these issues only by stopping my reliance on the Apple controls I was using and recycling some code from iComics v1.0. Not the greatest solution, and certainly something Apple shouldn’t be proud of. Hopefully those bugs will get addressed in iOS 9.

- - - - - -

Either way, with all that said and done, I’m REALLY happy iComics v1.1 is shipped and out the door. People seem to be enjoying it, and the revenue stream has been slowly increasing (REALLY good to hear), so it was definitely not for naught.

Once v1.2 is approved, I’ll have to start looking at v1.3. But I’m still not sure [what to add first](http://bugs.icomics.co)…. 🙂