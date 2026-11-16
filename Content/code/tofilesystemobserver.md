---
title: TOFileSystemObserver
tagline: A bullet-proof mechanism for detecting any changes made to the contents of a folder in iOS and macOS.
layout: CodeDetail
date: 2019-09-26 00:00:00
order: 11
owner: TimOliver
language: Objective-C
langColor: #438EFF
stars: ★ 42
role: Author
platforms: iOS, iPadOS, macOS
license: MIT
latest: 0.0.4
github: https://github.com/TimOliver/TOFileSystemObserver
image: /img/code/tofilesystemobserver/screenshot.jpg
path: /code/tofilesystemobserver/
---

TOFileSystemObserver keeps an eye on an app's Documents folder and reports every change the user makes to it while the app is running.

Since iOS 11, apps can show their Documents folder in the Files app, so users can add, move, rename, duplicate or delete files at any time, even with the app open right beside Files on an iPad. For an app that shows a library of documents, that means its interface and caches can fall out of date at any moment.

The library runs for the whole session and turns the system's file events into clear notifications: new imports (including waiting for large files to finish copying), moves between folders, renames, duplicates and deletions, at any folder depth. It also provides "live" objects for files and folders that update along with the file system.

It currently ships in iComics, but in hindsight, I think it's a bit overkill. Keeping track of every single file in an app is really complex. For iComics 2, I'm exploring a simpler approach that only watches the folders the user is currently looking at.
