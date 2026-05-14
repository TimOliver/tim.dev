---
title: DesktopTweet v1.0 Released!
date: 2010-02-14 23:24:46
author: Tim Oliver
image: /img/posts/2010/02/desktoptweet_logo.png
tags: development
path: /2010/02/14/desktoptweet-v1-0-released/
---
![DesktopTweet Logo](/img/posts/2010/02/desktoptweet_logo.png)Whew! After several weeks worth of coding and debugging, it’s finally finished!

So here it is folks! Presenting [DesktopTweet v1.0](http://www.desktoptweet.com/)!! 😀

Sorry about the wait there; the last version of DesktopTweet I released was back in July of last year. With work and other higher priority commitments, it’s taken this long to finally push out a new version. ^\_^;  
But I’m hoping it’ll be worth the wait. 🙂

I had a lot of great suggestions on how to improve DesktopTweet over last time, and I did my best to try and add as many new features as I could. 🙂

Some new features of DesktopTweet v1.0 include:

- Support for the [TweetPhoto](http://www.tweetphoto.com/) and [TwitrPix](http://www.twitrpix.com/) image services (Taking the total number up to 7 now).
- Ability to also choose to tweet the whole screen, or an image from your hard drive (JPEG/GIF/PNG).
- 2 new hotkeys for the above commands.
- The option to override the ‘Printscreen’ and ‘Alt-Printscreen’ key commands so they get sent to DesktopTweet.
- While writing the tweet, images can be saved to file as PNG, or copied to the clipboard.
- There is now a choice of having images uploaded, but not posting a tweet link on Twitter.
- If the upload unexpectedly fails, a choice for saving the picture to disk will appear.
- Tied up some loose odds and ends in the code.

Getting 7 image services to play nicely under one POST submission class was a really tricky thing, and most of my time spent debugging DesktopTweet was just ensuring that all of the services were receiving and responding to the submissions correctly. ^\_^;  
But on that note, I got in touch (and conversely was contacted by) developers from TweetPhoto, TwitrPix and Tweetgoo, and they were all very kind in helping me out in any way they could to get DesktopTweet working right with their services. For that, I would like to extend a special thanks to them. 😀

In reflection, one new feature I really wanted to add was the ability to submit basic tweets directly to Twitter without picture services; the advantage of that being that if I tied a hotkey to it, it would let me shoot out tweets faster. Unfortunately, since Twitter are trying their best to deprecate basic authentication and with all of these services are still using it, at the moment, it would require the user have to effectively log-in twice to be able to do that. However, after managing to get in touch with the developers of Twitter API, I was informed that they are currently working on a ‘Twitter OAuth delegation protocol’ that would effectively solve that. So I’ll have to keep an eye out for that in future. 🙂

Overall, I’m pretty glad how DesktopTweet turned out with this release, and I hope a lot of people find the new features useful. 😀

So head on over to the [DesktopTweet](http://www.desktoptweet.com/) site and start downloading!!

Enjoy!