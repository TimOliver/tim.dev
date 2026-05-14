---
title: MySQL + phpMyAdmin Backups =  fail
date: 2009-03-04 22:02:35
author: Tim Oliver
tags: development, tech
path: /2009/03/04/mysql-phpmyadmin-backups/
---
![The System is Down](/img/posts/2009/03/ubergames_forum_fail.jpg)So… my father often says to me that you shouldn’t make mistakes yourself. You should watch as the people around you make mistakes and learn from them what not to do. That clearly wasn’t the case here. &gt;\_&lt;

This is the story of what I’ve been doing in the past 3 days hehe. I’ve been trying to migrate all of the content from our old mod, RPG-X’s forum, to the new UberGames forum me and some friends have been working on. The reasoning for this is to consolidate resources as well as effort.

So, before the migration, I got phpMyAdmin to dump the UberGames forum to a big SQL source file (roughly 30MB worth of letters ) and stored it on my hard drive, and then installed the upgrade script.

My first mistake, I didn’t Read The Flippity Manual (RTFM btw), and I executed the upgrade script from the wrong entry point. This subsequently made the script confused about what system the UG forum was (It figured it was Invision in the end O\_o ) and subsequently corrupted several tables in the process. This wasn’t too bad as the tables were really small, and I pasted the data back in from my backup.

Now the colossal fail. Once I’d sorted out the import script and executed it in vBulletin mode, the forum looked like it just exploded. In the process, a whole pile of data mingled as well (ie my account got overwritten by RedTechie’s…? O\_o ) and I’m still wondering if that was my fault, or some residual glitches from before.

Sadly… and here’s the kicker, when I went to revert the database, not only did it remove the RPG-X stuff, but it deleted a whole pile of UberGames posts with it, as well as all of the admin accounts, which meant I was no longer logged in… and it kind of collapsed in on itself. XP

Sooo….. I realised I had no choice but to restore the entire SQL database I made, since by this point, the database was riddled with corrupted tables.  
At this point, I found out I couldn’t just feed the data back into phpMyAdmin, because it was too big and caused timeouts. ![](http://www.rpg-x.net/images/smilies/sad.gif ":(")

So, RedTechie suggested I go and find a script that handles staggered MySQL queries, and use that. Thankfully, I found an awesome one called BigDump ([http://www.ozerov.de/bigdump.php)](http://www.ozerov.de/bigdump.php%29).

And now… icing on the cake, BigDump refused to load my file because it was encoded wrong. Turns out it can’t handle INSERT queries that try to insert all of the data at once… something called extended inserts.

So… long story short, I’ve spent up until now, writing a utlity in C# .NET that could take my SQL file, resequence it into 1 on 1 insertion queries and then debugged it until it worked.

What was meant to be an easy 4 hour task has dragged onto 3 days. Ugh… ![](http://www.rpg-x.net/images/smilies/sad.gif ":(")  
I guess I should be happy I learnt a tonne of new stuff in the meanwhile… but I’m not so sure.

So the moral of this story is:  
1\) ALWAYS (!!!) RTFM!!!!!!!! No matter how simple something looks, there’s always a way to screw it up.  
2\) When exporting SQL from phpMyAdmin, make sure to uncheck the ‘extended inserts’ checkbox.  
3\) Test backup restoration before assuming it’ll just work.  
4\) Save the alcohol-based celebrations until after it works. XD

So yeah…. the forum’s all back online, and I’ve taken proper backups now… so I’m ready to try again haha. ![](http://www.rpg-x.net/images/smilies/tongue.gif "Stick Out Tongue")

In the meantime, I might also release my ‘SQL Splitter’ program as well, in case anyone else runs into the same problem I had…