---
title: A first look at iPokédex
date: 2011-02-05 13:45:04
author: Tim Oliver
image: /img/posts/2011/02/ipokedexlist.png
tags: development, tech
path: /2011/02/05/a-first-look-at-ipokedex/
---
![When you boot it up, this is the first thing you'll see. ^_^](/img/posts/2011/02/ipokedexlist.png)I just realized. I put up a post introducing iPokédex, but I only stuck up a temp pic of its logo. ^\_^;  
In this post, I’ll start to put up some of the features in it that are completed. In a later post, I might do a bit a bit of a rant on *why* I did that, but for now, just sit back and look at the purdy pictures. XD

So the picture on the right is the first thing the user will see when they boot up the app. The main set of navigation for this app is provided in the tab bar that runs along the bottom of the screen. Each tab bar button relates to a different set of information (eg, items, moves, types, egg groups etc) which can subsequently be drilled down to get even more information. The order of the tab items can be customized (ala the iPod app), so you can pick and choose what goes down there to your own liking. ^\_^

Since none of the standard code in the Apple iOS SDK can handle this normally, I ended up writing all of the tab control code myself (Approx 800 LOC ^\_^; ). Once iPokédex is done and out, I’ll see about posting it online somewhere. 🙂

Before settling on the tab bar solution, I had a couple of other ideas on how I’d go about doing that. That can probably wait for another blog post tho. XD

When it comes to displaying a list of Pokémon, there’s no denying there’s an absolute pile of them now. ^\_^; That being said, although the option to just scroll through them is there, it’s VITAL that you can actually search for the one you’re after. So, to help out with this, I’ve added 2 features to this menu: the ability to sort the list, as well as to manually search the Pokémon by name.  
To sort the list, you just tap the button in the top right corner. It’s possible to sort the Pokémon by which game dexes they appear in, which types they are, and then whether the results are displayed numerically, or alphabetically. Searching is as flexible as possible too, where you can enter in any part of the Pokémon’s name, as well as in either English or Japanese.

The app is still far from finished. Finishing off all of the submenus aside, its performance is still a tad chuggy. I’ve set myself a personal deadline of March 10 (When Pokémon Black comes out in English) to get this thing out. So I guess we’ll see how it goes. XD

![The list of items in iPokédex](/img/posts/2011/02/ipokedexitems.png)![Sorting the list of Pokémon](/img/posts/2011/02/ipokedexrefine.png)![Searching for Pokémon by name.](/img/posts/2011/02/ipokedexsearch.png)