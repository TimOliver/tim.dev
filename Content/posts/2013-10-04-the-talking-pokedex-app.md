---
title: The Talking Pokédex App
date: 2013-10-04 00:32:58
author: Tim Oliver
image: /img/posts/2013/10/iPokedex_iOS7.jpg
tags: development
path: /2013/10/04/the-talking-pokedex-app/
---
Back when I was working on [iPokédex](http://www.ubergames.net/projects/ipokedex), I had a pretty lofty, outrageous end-goal for the project: to get it to replicate the experience of a Pokédex from the TV show as closely as possible. Given the device on the TV show was a complete fantasy device in the year of 1998, I found the concept of owning a device with the remote possibility of realising that in 2008 incredibly exciting.

That being said, there was one aspect of a functioning Pokédex on iOS that was never quite possible for me to implement: the ability to synthesis audible speech.

<iframe height="480" loading="lazy" src="https://www.youtube.com/embed/vI9LFmstCcg" width="640"></iframe>

Now, iPhone and iPad have had built-in speech capabilities since as early as iOS 3.0 (Well, iPhoneOS 3.o back then) . At that point, it was mainly used for accessibility purposes (So people with poor eyesight could interact with the devices), but it became way more exposed when Apple brought out Siri in iOS 5.

Unfortunately, the speech synthesis API has always been a private one, meaning it’s not normally possible to use it without a small bit of hacking, and even still, if an app containing it was submitted to the App Store, it would instantly get rejected by the automatic submission process.

Nevertheless, I had a play with this private API back in 2011 to see what it could theoretically be capable of.

<iframe height="360" loading="lazy" src="//www.youtube.com/embed/Y9jiwrXMonM" width="640"></iframe>

Suffice it to say, when I got this working for the first time, I was incredibly blown away. XD

But alas, as the default iOS voice system was private, I knew that even though I had it working, it could NEVER see the light of day on the App Store.

In my attempt to make this possible, I filed a feature request with Apple’s Bug Report, asking for them to consider opening the API to the public. A few weeks later, I received a canned response from them saying they’ll think about it.

After that, I explored several third party solutions from companies specialising in speech synthesis. Sadly, licensing the tech from them would have been VERY expensive. All of them required an initial licensing fee of at least a couple hundred dollars, and a good deal of them also required a cut from all revenues received from app sales. Some even mandated that the app couldn’t be put on the App Store for free; it HAD to be paid.

It was at this point that I received [the cease and desist notice from The Pokémon Company](/2011/07/11/ipokedex-copyright-notice-from-tpci/), and so after all that, I never thought about it again…

… until now.

This week, [I discovered](https://twitter.com/TimOliverAU/status/385217605067223040) that as of iOS 7, Apple had actually made the speech synthesis API I had previously used in 2011, [completely open to third party developers](https://developer.apple.com/library/ios/documentation/AVFoundation/Reference/AVSpeechSynthesizer_Ref/Reference/Reference.html), with no extra licensing fees or royalties. Just like that, something that was incredibly expensive and hard in 2011, became completely free and simple in 2013.

Last night, I had a bit of a play with the new speech synthesis library in a test version of iPokédex on my iPod touch running iOS 7.

<iframe height="710" loading="lazy" src="//instagram.com/p/e-D5SisydU/embed/" width="612"></iframe>

So how about that. Even though it took 2 years, something I would have killed for in 2011 became possible in 2013. Better late than never right?

Either way, since I’ve moved on from iPokédex to [a much more awesome project](http://icomics.co) these days, I doubt I’ll have any pressing need to use it properly in the immediate future, but I still thought it was cool.

And also, you never know what the future might hold in store. ;D