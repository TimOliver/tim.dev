---
title: Nearly Getting Hacked
date: 2016-05-24 22:23:50
author: Tim Oliver
image: /img/posts/2016/05/Nearly_got_hacked.jpg
tags: events, personal
path: /2016/05/24/nearly-getting-hacked/
---
Earlier this evening, something somewhat disturbing, and extremely sobering happened.

I have a media PC, [a small Intel NUC](http://www.intel.com.au/content/www/au/en/nuc/overview.html) in my living room plugged into my TV on which I play a lot of movies/music. In order to control the NUC remotely from my laptop or desktop PC, I had [TeamViewer](https://www.teamviewer.com/en/) installed on it, and always running in the background. Even though it was on, I rarely ever used it.

This evening, as I was watching a video on YouTube on my NUC, the TeamViewer ‘thanks for using the free version!’ dialog box popped up. ‘Whatever’, I thought, ‘It must have just done a system update’. And closed it.

Right after that, the TeamViewer application window itself appeared and stated ‘Tim Oliver has connected’. Immediately after that, the audio on my NUC was muted.  
  
‘Uhhhh’, was my immediate reaction. I immediately started wondering what would have caused that. I was wondering if the NUC was playing up, but the fact that it had actually said ‘Tim Oliver has connected’ had me suspicious. I clicked on the TeamViewer window, on the ‘Tim Oliver’ in the clients list, and disconnected it.

Something didn’t seem right. There was no way another one of my devices had just made that connection; the only other device on at the time was my laptop. And TeamViewer wasn’t open on that.

Wanting to get to the bottom of things, I decided to open my account on the TeamViewer website and check if there was anything weird in the history.

![TeamViewerStrangeLogin](/img/posts/2016/05/TeamViewerStrangeLogin.jpg)

…Kamensk-Ural’skiy? RU…? Russia? Wait. That’s a login session from somewhere in Russia???

Oh crap. Oh crap. Oh crap.

Someone had actually logged into my TeamViewer from Russia, and FOR THE BRIEFEST OF MOMENTS had direct control of my NUC!

Very swiftly, I killed that session (That’s what that spinner in the screenshot is doing) and used [1Password](http://1password.com) to generate a new password for the account.

Still somewhat confused as to what was happening at the time, I fired off a tweet:

> Holy freaking crap. Someone located in Russia hacked my TeamViewer account and briefly gained screen control of my Media PC. O\_o
> 
> - Tim Oliver (@TimOliverAU) [May 24, 2016](https://twitter.com/TimOliverAU/status/735057876532658176)

<script async="" charset="utf-8" src="//platform.twitter.com/widgets.js"></script>

Nearly straight away, my good college Sam Ritchie tweeted back with a very plausible, if not chilling explanation:

> [@TimOliverAU](https://twitter.com/TimOliverAU) did you have the same password as your LinkedIn account? ?
> 
> - Sam Ritchie (@FakeSamRitchie) [May 24, 2016](https://twitter.com/FakeSamRitchie/status/735062689488068608)

<script async="" charset="utf-8" src="//platform.twitter.com/widgets.js"></script>

Uh-oh. UH-OH. Yes… yes I was. Before I switched to 1Password, I was re-using the same crappy password for most of the accounts I had. And I was STILL using the same email address and password combination for my LinkedIn account and TeamViewer accounts (Dating back to 2012!). So with the recent news that the LinkedIn data breach from 2012 [recently hit the black market](http://motherboard.vice.com/read/another-day-another-hack-117-million-linkedin-emails-and-password), it would seem very plausible that hackers were able to get my email and password combination and gain access to my TeamViewer account.

I am so relieved I caught that. It was sheer dumb luck that I was using the NUC at the same time that the person in Russia tried to log onto it. I leave my NUC on all the time, and they easily could have done that while I was in bed.

I did a bit of research to see what they could have done to my PC, and I found [this thread on reddit](https://www.reddit.com/r/hacking/comments/291525/someone_accessed_my_computer_through_teamviewer/). From the sound of it, left unchecked, they easily could have tried to access my PayPal through my browser, install malware or ransomware on the machine, or even worse. Thankfully, since it’s not my main PC, most other accounts were logged out on it (And protected by my 1Password database), but I’m still somewhat nervous what could have actually happened. At the very least, I probably would have had to format and re-install Windows on the NUC, which would have been a major pain in the butt.

In any case, I’m writing this blog post after I just went through and assigned an ultra long 1Password generated password to every account that was still using that recycled password, so I am now no longer officially using it at all.

Years of using the same password finally caught up with me and bit me in the butt. I’m just ultra happy that by a sheer fluke I was able to avoid any real disaster.

There’s a very clear-cut moral to this story: NEVER get complacent about internet security. Just because you haven’t gotten bitten yet doesn’t mean you should lower your guard.

Don’t recycle passwords. [Get a password manager](https://1password.com), and make sure there are 0 duplicate passwords across your accounts.

*[Anonymous Hacker](https://www.flickr.com/photos/brianklug/6870002408) photo by Brian Kulg.*
