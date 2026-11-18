---
title: YouTube Music macOS App
date: 2021-04-29 00:51:15
author: Tim Oliver
image: /img/posts/2021/04/YouTube-Music.jpg
tags: development, tech
path: /2021/04/29/youtube-music-macos-app/
---
I hope everyone’s been staying safe and having a relatively uneventful 2021 so far. I’ll do a proper status update at some point, but so far, on my end, things are good.

I thought I’d share a cool little project I’ve been working. It’s sort of a precursor to iComics 2; an excuse to do some R&amp;D on an existing project that I can then re-use later.

I use YouTube for most of the music I listen to while I work. The algorithms do a pretty good job at putting together playlists I like automatically, and it’s easy to leave on and forget. Sadly there’s never been an official macOS app; only the website. While this is “fine”, I always wanted a dedicated app so I could officially elevate it away from a browser tab.

Enter [YT Music](https://github.com/steve228uk/YouTube-Music), an open source spearheaded by Stephen Radford out of England. It takes the website, and wraps it in a very basic web view. It’s not a lot, but it works great. Unfortunately, as is the nature of open source, Steve has been busy over the last few years and hadn’t had a chance to ship a new version of the app.

Since I want to make a macOS version of iComics 2, I figured this would be a great chance to learn how to release a Mac app. So I talked to Steve, and we came up with a plan to automate new releases. The app already used [Sparkle](https://sparkle-project.org), but it was embedded in a pre-built framework that was quite cumbersome.

So, bit by bit, in my free time, I came up with an automated build system on top of GitHub Actions that could create new builds of the app with Steve’s signing certificate. While actually writing the script wasn’t the hard bit, the actual hard bit was trying to work out what steps are necessary, and which order they need to go in.

The process goes something like this:

1. Build the app
2. Sign the app
3. Notarize the app
4. Extract changes from the Changelog
5. Sign the app again for Sparkle
6. Embed changes into Sparkle RSS feed
7. Bundle the whole lot up
8. Publish on GitHub Actions

As an added bonus, I used this opportunity to [try and use Fastlane Swift](https://github.com/steve228uk/YouTube-Music/blob/master/fastlane/Fastfile.swift) for the first time. As Fastlane Swift is still *very* new, it was a great chance to see how it could be improved, and I even ended up filing a PR back to Fastlane.

In any case, now that I’ve learned how the build process should go, and written a script for it, this should be reusable for any other macOS build processes. It took a while, but I’m super happy that I was able to fix it, and answer every question I had in the process.

If you want to give the app a try, feel free to [download it here](https://github.com/steve228uk/YouTube-Music/releases/latest)

Enjoy!