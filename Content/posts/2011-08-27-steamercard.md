---
title: SteamerCard.
date: 2011-08-27 01:33:30
author: Tim Oliver
image: /img/posts/2011/08/steamercard.jpg
tags: development, video games
path: /2011/08/27/steamercard/
---
![SteamerCard circa 2008](/img/posts/2011/08/steamercard_igoogle.png)

For the majority of my blog posts in the previous couple of days, my good pal [Dean](http://blog.ppy.sh/) keeps point out to me that the SteamerCard entry (on the right of the page) is currently down. 😛

While I’m actively fixing it now, since I don’t think I’ve actually done this before, I thought I’d explain what SteamerCard is. 😀

Back in the summer of 2008, before I succumbed to buying an Xbox, I was really jealous of all of my friends who had Xbox Live! GamerCards. The whole concept of being able to embed your current gamer status as a discrete, interactive card really appealed to me for some real reason, and I was feeling sad there wasn’t much of an equivalent on the PC. That being said, considering how much I loved Steam, I thought that would be an excellent platform to have one on. 😀

So I decided to build SteamerCard as another service under the UberGames banner. 🙂 Unlike most other third party GamerCard services though, I wanted it to be a fully interactive HTML &lt;iframe&gt; element, and given the design considerations, completely ad-free.

The SteamerCard webapp is written entirely in a PHP/MySQL solution and works on a system of parsing the information from the Steam website with regular expressions. In the interests of reducing the number of requests made to the Steam site, the system caches the user’s information in its own local store, and updates itself on an hourly basis.

Unfortunately as of last month when the UberGames system was updated to PHP 5.3, the combination of deprecated code in its base classes caused the entire system to die. Given how heavily the base classes were integrated with the upper-level code, unfortunately it turned out that I couldn’t really resurrect the code without doing a near-complete rewrite.

So at the moment, I’ve pretty much decided to rewrite the majority of SteamerCard from scratch, whilst revamping as much of the old code in the process.

Looking back on the old design above, I’ve also decided to redo the visual look of SteamerCard while I’m at it:

![SteamerCard 2011 Design Mockup](/img/posts/2011/08/steamercard_11.jpg "SteamerCard 2011")

This time around, I’m building the whole thing in as much of an OOP fashion as possible, and I’m hoping to set up a system where other themes can be added as well. 🙂

Also, in a follow up to the blog I wrote last night, once it’s done, I’m considering open-sourcing SteamerCard when it’s finished. 😀