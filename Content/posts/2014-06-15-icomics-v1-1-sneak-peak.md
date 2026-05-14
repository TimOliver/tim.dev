---
title: iComics v1.1 Sneak Peek
date: 2014-06-15 00:14:02
author: Tim Oliver
image: /img/posts/2014/06/iComics_v1_1_Preview.jpg
tags: development
path: /2014/06/15/icomics-v1-1-sneak-peak/
---
Blimey. It’s been a fair little while since [my last post on iComics’ development](/2014/01/29/the-icomics-roadmap-jan-2014/ "The State of iComics – Jan 2014"). Since starting the crazy task of re-designing the entire app to the iOS 7 design aesthetic in February this year, I’ve already started to tease a few pictures of my progress here and there along the way, mainly uploading them to [my Instagram account](http://instagram.com/timoliver). But after a few emails from people asking for some proper clarification, I figured an actual blog post of the current progress might be best.

Alrighty. So here’s how iComics v1.1 is going! 🙂

##  The Comics Library Display

Just as frame of reference, here’s what the comics library looks like in the current App Store version of iComics.

![iComics iOS 6](/img/posts/2014/06/iComics_iOS6.jpg)In the current version of iComics, this layout is a completely stock-standard Apple table UI control. On both iPhone and iPad, each comic is given its own discrete row, with the iPad version padding out the row with the ‘Last Opened’ text.

To be completely frank, I loathe and despise this layout. When I was laying out the initial design for iComics, iOS 5 was the latest version in production, and as such, using the default Apple table layout was the easiest and quickest implementation at the time.

That all being said, I realise that giving each comic its own complete row, especially on the iPad, is a complete waste of screen real estate. And so, I’ve always thought of this list style as a temporary stopgap; something that would be ‘merely sufficient’ in enabling users to read comics, but something that would never stick around.

So without further ado… here’s how the comics library list looks like in v1.1!

![iComics v1.1 Grid View](/img/posts/2014/06/iComics_v1_1_GridView.jpg)As you can see, GONE is the silly single-row list of comics, replaced by proper grid of thumbnails, suitably large to take full advantage of the Retina display, and to ensure the entirety of the screen is properly used.

Now, even though in the time since I released iComics v1.0, there have been a number of similar grid UI solutions, (including an [official one by Apple](https://developer.apple.com/library/ios/documentation/uikit/reference/UICollectionView_class/Reference/Reference.html)), I ultimately decided that this is something I should build myself. As such, this grid layout is a custom solution I developed from scratch, starting at the end of 2012 and periodically worked on and tweaked over the entire course of 2013. It’s been tested on the iPad Air, all the way down to the original iPad (something that not even Apple’s control can do!), and has been tested and optimised to be as performant as possible. Also, it’s [completely open source](https://github.com/TimOliver/TOGridView)!

That all being said, I know that there will definitely be a few people who would still prefer the old table style library of iComics v1.0. There is certainly the possibility of sets of comics without notable cover art, that might require the title to be visible to be properly accessible, and as such, simply showing the thumbnails might be confusing.

And to that, I say, have no fear! 🙂

![iComics v1.1 List View](/img/posts/2014/06/iComics_v1_1_ListView.jpg)Not only can you display comics as just a grid of thumbnails, but by tapping the toggle switch next to the search bar, you can switch to the old comics list view. In addition, on the iPad, the list view now makes proper use of the entire screen, with 2 comics per row in portrait mode, and 3 comics in landscape mode. What’s exciting about this is that it’s NOT a completely separate set of code, but it’s actually the same set of UI code as the thumbnail grid with a few parameters changed, which means that there’s a very minimal hit on resources toggling between the two modes.

It’s taken a fair bit of effort, with a lot of testing (And a fair bit of profanity) to get this grid view working properly, but I definitely think it was worth it. I’m really happy with how nice it looks, and how much more nicely lists of comics are now presented. 🙂

## Comic book collections

Without a doubt, the most requested feature for iComics has been to group comics into separate collections instead of the one giant list it has right now, and I totally agree. When I released iComics v1.0, I viewed comic collections as an auxiliary component; something that would be nice to have, but not ESSENTIAL to the core experience of reading comics. Certainly not something worth holding back the release for. But that being said, I’ve always realised that given the volume of some peoples’ comic collections, it will definitely need to be the main priority for the next big release.

As such, I’ve resolved myself to no more updates to the app until collections is properly implemented, and implemented ‘right’.

Doing this sort of thing ‘right’ has not been easy, though. Originally, I was envisioning a system like in iBooks, where there was simply a ‘Collections’ button you tap, which presents a textual list of collections, and that would be it. But the majority of people of whom I showed that idea, thought it was absolutely terrible!

So, after looking at the designs of a myriad of other iOS apps, including [Gmail](https://itunes.apple.com/au/app/gmail-email-from-google/id422689480?mt=8), [YouTube](https://itunes.apple.com/au/app/youtube/id544007664?mt=8), [objc.io](https://itunes.apple.com/au/app/objc.io-best-practices-advanced/id683718429?mt=8), and even [Facebook](https://itunes.apple.com/au/app/facebook/id284882215?mt=8), doing a LOT of thinking, and a LOT of playing in Photoshop, I finally came up with a design that I’m happy with.

![iComics v1.1 Collections](/img/posts/2014/06/iComics_v1_1_Collections.jpg)

When you tap the ‘hamburger’ icon in the top left of the library menu, the collections menu slides in from the left side, over the top of the library menu. The collections menu behaves exactly the same as the comic library menu, with the ability to toggle between a grid and list mode, and sports a dark grey colour theme to make it very visually distinct. Having the collections menu styled in this sort of way is part of the reason why the grid redesign took priority; once the grid library style was complete, it was very quick and easy to copy it across to the collections menu.

The entire slide-out menu system is a custom implementation that I designed and built in January this year, and it sports a very iOS 7-style animation feel.

<iframe height="710" loading="lazy" src="//instagram.com/p/pG8OsQkifG/embed/" width="612"></iframe>

In any case, I’m really happy with the way the collections system is turning out. It’s not finished yet, but the majority of the major hurdles are already behind us. 🙂

## The comic reader view

The actual part of the app where you read comics, or the reader view, is the bread-and-butter part of the app. Its look and performance is the thing that sets iComics aside from the other comic reader apps, and as such, I wanted to make sure I got it right. 🙂

Here’s how it looks in the current App Store version.

![iComics Comic View iOS 6](/img/posts/2014/06/iComics_ComicView_iOS6.jpg)

And, after much playing with the design in Photoshop, and testing the capabilities of iOS 7, here’s how it looks now.

![iComics v1.1 Reader](/img/posts/2014/06/iComics_v1_1_Reader.jpg)

Just like the rest of iOS 7, it’s now much more flat, and takes full advantage of the iOS 7 translucency. Aside from the translucency, I’ve also modified a lot of the animations to behave a lot more like iOS 7’s built-in animations too. I can’t wait for you to see them. 😉

## Additional Stuff

In addition to the new grid view, collections and the new reader view, I’ve done a few extra things here and there to try and improve the overall experience. One other thing of note is I’ve removed the prompts that periodically appear when you open the app (Either to ask you to rate the app, or just notifications in general). In its place, I’ve embedded a dedicated news menu that’s attached directly to this blog.

![iComics v1.1 News Reader](/img/posts/2014/06/iComics_v1_1_News_Feed.jpg)

The menu will display all the posts from this blog that have been specifically tagged with the keyword ‘icomics’, and although it’s currently on the main collections menu, I’ve got plans to move it into the ‘Setttings’ menu once I’ve added a few more UI features down the road.

##  Where are we at now?

So, now that you’ve seen all the new UI elements, you must be wondering why it’s not shipped yet. The truth is, it’s still a little while away from shipping. As you can probably guess from the screenshots, the collections system isn’t properly finished yet, and there are still a few views here and there that look like iOS 6.

One thing that’s been a real challenge is iOS 7 itself. iOS 7 was a fundamental shift for the platform, and it was WAY more than just a simple reskin. With things like the status bar becoming transparent, a LOT of the core system assumptions that iComics was built around during the iOS 5 and 6 tenure were completely changed in iOS 7. As such, a great deal of work has gone into making sure the app behaves in the same consistent way we’ve come to expect, on iOS 7. Thankfully, at this point, I’ve managed to work my way around them, and I might even have some nice topics for future blog posts as a result. XD

At this point however, the majority of the hurdles are finished. All of the complicated UI code is finished, and the remainders are, (for the most part) relatively incidental. So while I don’t have a solid release date planned yet, I’m definitely confident that it will be soon!

In any case, this is what the future of iComics looks like. I hope you like it, and as always, thanks for your support!