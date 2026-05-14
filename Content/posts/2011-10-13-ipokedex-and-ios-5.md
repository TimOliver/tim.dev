---
title: iPokédex and iOS 5
date: 2011-10-13 23:25:12
author: Tim Oliver
image: /img/posts/2011/10/borked_ipokedex.png
tags: development, tech
path: /2011/10/13/ipokedex-and-ios-5/
---
![It still works.... kinda](/img/posts/2011/10/borked_ipokedex.png)

*(日本語版なら[こちらです](/2011/10/17/izukan-to-ios/ "iずかんとiOS5")！）*  
**TL;DR iPokédex has become slightly broken in iOS 5. No, [I can’t fix it](/2011/07/21/on-ipokedex-getting-pulled/ "On iPokédex getting pulled"). If you want to help out, register your interest by [signing this petition](http://www.change.org/petitions/keep-pokedroid-and-other-applications-like-it-2)!**  
Hey guys! 🙂

iOS 5 is finally out! As I write this, I’m currently taking my iPad through the long backup and upgrade process. As excited as I am about iOS 5 (I can tell you, there’s some AWESOME new stuff in there :D), I’ve actually been dreading this day. Why exactly? Well I’ve known for some time that iOS breaks [iPokédex](http://www.ubergames.net/projects/ipokedex) in a pretty epic way. I probably could have mentioned it earlier, but I decided I should wait until the NDA is good and done with. ^\_^;

Now, while the app itself is still stable, due to a bit of my dodgy coding and lack of foresight (this was my first major version upgrade as a developer!), an issue has arisen where if you press ‘Sort’, you’ll no longer be able to dismiss the sorting menu. While the ‘OK’ button and the ‘Cancel’ buttons are still being drawn, the code I’ve written that re-positions them to be placed under the scroller view has stopped working (so they’re appearing behind it right now, out of reach). At the moment, the only way to dismiss the dialog is to fully quit out of the app (ie, remove it from the multitasking bar) and start it up again. 🙁

As far as functionality and usability goes, this is a pretty bad thing, and if I had submitted the app to the App Store with a bug like this in it, it would have most certainly been rejected. ^\_^;  
I’ve already started receiving emails from users who have upgraded to iOS 5 and have found the error.

Code-wise, this is a VERY easy thing to fix (it’s like 1/3 of a line of code). I’ve already fixed it in the version I carry around on my iPhone. XD  
Sadly, however, as I was [requested by the Pokémon Company to take the app down](/2011/07/21/on-ipokedex-getting-pulled/), I am unable to distribute this fix to anyone else. 🙁

I’m really sorry about this guys. The user experience is going to start deteriorating and there’s nothing I can do about it. And I fear it’s going to become more frustrating to watch as time passes, and more emails from users start piling in. ^\_^;

Either way, I’m not going to give up until the very end. The lawyer I talked to at TPCI was very kind to me and told me they might take iPokédex over to licensing to see if they might be interested in working something out. I haven’t heard back anything at all on that front in a while now, but as it’s most likely the final avenue, I’m more than happy to wait.

In the meantime, if you’d like to help out, there may be a way for you to do so. 🙂 When [Nolan Lawson’s app Pokédroid was pulled](http://nolanlawson.com/2011/05/26/on-pokedroids-removal/), a dedicated young lady named Amber set up a petition to try and convince TPCI otherwise. The petition goes on the record to state that since these kinds of apps are free, and that the information contained within is easily accessible on a multitude of sites, there shouldn’t really be a compelling reason for TPCI to want to shut these apps down. Now, while the lawyer from TPCI explained to me that it’s a pretty open and shut case in that TPCI has simply decided not to allow unauthorized apps, I think the petition is a good idea, if not to simply raise awareness on the amount of interest there is on having some kind of official Pokémon reference app.

At the moment, the petition only has a handful of signatures, so [head on over there and sign it](http://www.change.org/petitions/keep-pokedroid-and-other-applications-like-it-2)!

In any case guys, if you’re a heavy user of iPokédex, I’d recommend hanging off upgrading to iOS 5 as long as you can. ^\_^;