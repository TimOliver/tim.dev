---
title: IGListKit
tagline: A data-driven UICollectionView framework for building fast and flexible lists.
layout: CodeDetail
date: 2016-09-07 00:00:00
order: 3
owner: Instagram
language: Objective-C
langColor: #438EFF
stars: ★ 13.1k
role: Top contributor
platforms: iOS, macOS, tvOS
license: MIT
latest: 5.2.0
github: https://github.com/Instagram/IGListKit
image: /img/code/iglistkit/screenshot.jpg
path: /code/iglistkit/
---

I first came across IGListKit when one of its creators gave a talk about it at iOS Conf SG 2017. It might look like a fairly unassuming library from the outside, but it's the literal backbone of Instagram and Threads on iOS.

IGListKit streamlines turning immutable view models into fast, dynamic scrolling lists. View models drive section controllers, which in turn drive the individual cells. Because the view models are immutable, a diffing engine can work out exactly what changed and update only that part of the screen.

It sits neatly on top of UICollectionView, where juggling sections and cells through a single interface can quickly get overwhelming. In fact, there's a good chance it inspired Apple's own Diffable Data Sources, released in iOS 13.

When I joined Instagram, I noticed there hadn't been a public release in quite a while, despite a really vibrant community on GitHub. So I joined the team of engineers running the repo, and spent a few years bringing it up to modern iOS standards: adding Swift Package Manager support, integrating the latest UICollectionView fixes and improvements, and getting unit test coverage back up to 99%.
