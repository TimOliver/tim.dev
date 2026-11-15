---
title: Beeline
tagline: An extremely lean implementation on the classic iOS router pattern.
layout: CodeDetail
date: 2021-07-17 00:00:00
order: 11
owner: TimOliver
language: Swift
langColor: #F05138
stars: ★ 65
role: Author
platforms: iOS, macOS, tvOS
license: MIT
latest: 1.0.1
github: https://github.com/TimOliver/Beeline
image: /img/code/beeline/screenshot.jpg
path: /code/beeline/
---

Beeline is a small library I built to centralize all of an app's navigation in a single object.

The idea came from iComics. Opening a comic from inside the library was easy enough, but when a request to open a comic came from outside the app, it wasn't clear who should own that presentation. Beeline's answer is one top-level object in charge of all navigation, with view controllers passing their navigation requests up the chain to it.

I think it's a really neat way to decouple navigation from view controllers, and I'm now exploring whether the same idea could double as a form of dependency injection.
