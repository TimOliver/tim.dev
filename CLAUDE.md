# Dark Mode Popover (in progress)

## What was done
All changes are in `index.html`. The moon icon was moved out of `<nav>` into a `.theme-toggle` wrapper with a hover popover (Auto/Light/Dark buttons), CSS for the popover, and a JS IIFE for `localStorage` persistence + `data-theme` on `<html>`.

## Pending tweak
Move the `.theme-toggle` back **inside** `<ul id="menu">` as an `<li>`, positioned before the RSS icon (last item). Remove `margin-left: auto` from `.theme-toggle` since it won't need to self-align when inside the menu.
