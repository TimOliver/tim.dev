---
title: "iPokédex: Why??"
date: 2011-06-14 21:37:06
author: Tim Oliver
image: /img/posts/2011/06/ipokedex_icon.png
tags: development
path: /2011/06/14/ipokedex-why/
---
![iPokédex's BW Icon](/img/posts/2011/06/ipokedex_icon.png)Blimey! It really is hard to find the time to write a blog. ^\_^;

I covered this in my [intro to iPokédex post](/2010/12/15/ipokedex-my-current-iphone-project/) a little bit, but I’d like to go into more detail about certain aspects of the app. In this case, I want to talk about how I got the idea of making a Pokédex app into my head. XD

My original motivation for building iPokédex came around at the end of 2009. At this point, I’d gotten mighty addicted to [my import copy of Pokémon HeartGold](/2010/03/19/pokemans-heartgold-gotta-buy-em-all/), but I was finding it quite frustrating in certain points. With now over 493 Pokémon, I had no idea what half of them were, what their movesets were or how to evolve them. And not only that, but since the game was in Japanese, even the ones whose names I did know got me confused. XD Ultimately playing the game (even in Japanese ^\_^;) was doable, but it meant I needed to have a strategy guide on hand for those unexpected moments. My trusty iPhone 3G and an open browser window to [Bulbapedia](http://bulbapedia.bulbagarden.net/) worked in a pinch, but since Bulbapedia wasn’t designed for Safari on a tiny smartphone screen, getting to the right info usually took a bit of time. At this point, I started thinking about a native iPhone equivalent Pokédex app…

At around that time, I discovered [Pokedex](http://www.theiphoneappreview.com/2009/09/pokedex-pokemon-iphone-app/) on the iPhone App Store. At 2 bucks it looked to be a hefty investment (Well. [As far as iPhone apps go](http://theoatmeal.com/blog/apps) XD), but I took the plunge hoping it would be worth it.

Needless to say… it wasn’t. ^\_^; The app worked by wirelessly linking to [Bulbapedia](http://bulbapedia.bulbagarden.net/) and pulling down information on the fly. This was ultimately a very bad thing since not only was it a VERY slow experience for the end user (and required constant internet), it completely violated Bulbapedia’s terms of usage whilst simultaneously hammering their server bandwidth for the privilege. X\_X

As the [comments in that Pokedex app review](http://www.theiphoneappreview.com/2009/09/pokedex-pokemon-iphone-app/#comments) link indicate, this didn’t sit well with the majority of online Pokémon fans and Apple pulled the app soon afterwards (Not too sure if I got a refund for that… ^\_^;), and we were back at square 1 with no Pokédex apps on the iPhone App Store. 🙁

Feeling majorly burned at that point, and with no other Pokédex apps available, I decided to build my own, tailored to my requirements, and based on my own experiences with the games. Since I wanted to use Bulbapedia’s content, and since I obviously didn’t want to do anything that would anger Nintendo, I decided that no matter what, the app would be released free of charge and I wouldn’t profit off it. Chalk it down to a gesture of good will, a learning experience, or a nice feather in my CV or whatever, iPokédex was never meant to make any money. 🙂

So starting at the beginning of 2010, without even having a name for the app yet, just as a bit of a casual thing, I started off by building the database for iPokédex. It took basically the whole of 2010 (REALLY casually) to complete the database, which was manually built by combining elements from Bulbapedia and veekun into my own schema. To extract the data from Bulbapedia, I used a combination of PHP scripts to perform [HTML scraping](http://en.wikipedia.org/wiki/Web_scraping) of each of the necessary pages, manually touching up entries along the way. For veekun, I downloaded the [open sourced database code](http://git.veekun.com/pokedex.git), baked it into its own SQLite database on my HD, and then used SQL queries to export the data in the right format for my schema. 🙂

Once the database was locked in, I started building the app in Xcode. Since I was (still am?) a n00b at Apple’s code and frameworks, it took a pretty long while to figure out how to make it all fit together, but after much Googling and profanity (winning combo!), I prevailed. Thankfully, once you get the hang of it, Xcode is a very powerful development platform, and it makes developing apps on the Mac ultimately a lot easier than I was anticipating.

Originally, since I was figuring every permutation of ‘i’ and ‘Pokédex’ would have been taken by now, I was originally planning to call the app ‘iZukan’ (The Japanese name for Pokédex).  
Thankfully, while I was screwing around on iTunes Connect, trying to set up the App Store entry for it, I found that ‘iPokédex’, with the accented é was still available! I chalked that one down to not many people knowing how to write that letter on a PC. XD As a result, the app was officially named iPokédex, and the former name, iZukan was used for its Japanese localization (Written in hiragana as iずかん).

Overall, due to its casual nature and my epic n00biness at writing iPhone apps, iPokédex was in inception for about one and a half years before it actually got released. At this point, I’m still absolutely gobsmacked it even got this far, given the size and complexity of such a thing. ^\_^; Either way, I do not intend for my next app to take this long or be this huge… XD

For my next post, I’m considering talking about what I learned by looking at the other Pokédex apps on the App Store and how I was able to improve on those concepts a bit. 😀