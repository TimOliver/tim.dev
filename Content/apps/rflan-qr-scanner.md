---
title: RFLAN QR Code Scanner
tagline: QR code scanner for RFLAN
layout: AppDetail
date: 2013-06-01 00:00:00
year: 2013
platform: iPhone, iPod
role: Hobbyist
company: Redflag LANfest
years: 2013
stack: Objective-C
status: Open Source
icon: /img/apps/rflan-qr-scanner/icon.png
path: /apps/rflan-qr-scanner/
---

This was a fun little project that grew out of some experimenting my friends and I did with the new ticketing features in iOS 6.

I used to volunteer at RFLAN, a PC gaming LAN held at one of Perth's universities. It was a paid event, so we had to check each attendee in as they arrived. We originally did this with a shared Google Sheet, which was incredibly slow.

When Apple released PassKit, we started playing with it to make passes for RFLAN, and realised scanning QR codes would be way faster than checking people in by hand. So we decided to build a simple check-in system of our own.

We changed our ticketing system to send each attendee a QR code, and I built this scanner app for the other organizers. It worked over the event's local Wi-Fi: scanning a code confirmed the attendee and checked them off in the database.

It worked incredibly well. We could check people in faster than they could line up!
