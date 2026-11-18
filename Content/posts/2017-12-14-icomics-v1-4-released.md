---
title: iComics v1.4 Released
date: 2017-12-14 16:45:59
author: Tim Oliver
image: /img/posts/2017/12/iComics-iPhoneX.jpg
tags: development, tech, icomics
path: /2017/12/14/icomics-v1-4-released/
---
***tl;dr: iComics v1.4 with support for iPhone X and the new iPad Pro is out! I’m also planning to give streaming iComics dev another try. [Follow me here](http://twitch.tv/timxd).***

In case you missed it, I updated iComics to v1.4 and shipped it late last month. Sorry it took so long, but hopefully it fixed a lot of the issues people were having.

While a bit of an incremental update, iComics v1.4 fixed a lot of stuff under the hood:

- It now renders properly on both the new iPhone X, and the new 10.5″ iPad Pro.
- It integrates with the new Files app, which should fix the download issue with comics being unelectable in the Google Drive app.
- Fixed an issue where the app would crash if you tried to save a copy of a page to the Camera Roll (Sorry about that one!)
- Updated all of the third party dependencies, notably Realm, in order to improve stability and performance.
- Tweaked Realm’s settings in order to mitigate a crash that was occurring on devices with smaller RAM pools.
- Fixed all of the broken links in iComics, including the App File Sharing tutorial and the link to this blog.

Please give the new version of iComics a try and let me know what you think. 🙂

## Why iComics Development is so Slow

I’m very sorry that development of the app has been going slowly. I basically took a hiatus this year in order to 100% focus on the work at my company. While I don’t regret dedicating all of my time to the company, I am a bit disappointed in myself that I didn’t fix a lot of the issues people were reporting in iComics sooner. My circumstances recently drastically changed, and so I’m hoping that will now let me spend a lot more time on it. Thanks for your understanding. 🙂

## The Future of iComics

I’ve been working on this app for a while, and it’s starting to show. All of the architectural considerations were made during the era of the iPad 1, where iOS devices were single core, and had very limited RAM. I’m no where near done with this app, but it’s gotten to the point where it’s very tricky to add new features, and the code is very unpleasant to look at.

My current plan for the app is to finish up adding a custom file downloading system. I spent the last year two years compiling libraries to allow integration with FTP, SFTP, SMB, and WebDav, and designing a UI system that can interoperate with those protocols, and as well as the public APIs of Dropbox, Box, Google Drive and Microsoft OneDrive.

I recently decided that I’m going to pull all of that code out of iComics and treat it as a separate module. ‘Downloading files’ is a very generic feature, and so I feel like this is one that should be done separately, in such a way that it could be reused in any other app that needs generic file handling. To that end, I’ve created the GitHub repo TOFileKit and will be working on open-sourcing all of the work I’ve done in there, open source.

Once this work is done, and iComics has the full file downloading support, I plan to release one more version, before I cut loose and re-implement a whole new app and engine from scratch. iComics 2.0. 🙂

## Streaming Development of iComics

In order to make progress of iComics more transparent, as well as to allow anyone who’s interested to see how it works, as well as motivating myself better, I’m planning on starting to stream iComics development sessions. It’s something I’ve been wanting to do for a while, but until recently, I hadn’t put the time into learning how to do it. XD

With Twitch finally enabling creative non-game related streams, and with the recent release of the Justin.tv usernames, I’m going to properly get into Twitch streaming now.

If you’re interested, feel free to follow me at [twitch.tv/timXD](https://twitch.tv/timXD)

As aways, thanks for using iComics! Have a happy holiday and see you next year!