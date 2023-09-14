# Friday Night Funkin: Restructure Engine
This engine started as a self-test to see how far I could get coding a FNF engine from (mostly) scratch, and now it's something much bigger

## Features
- Not technically a mod of Base FNF, meaning a lot of accumulated clutter isn't present in the code
- Revamped input system and hold note system
- Notes are spawned based on scroll speed and position, rather than at a fixed time before they need to be pressed
- Hold notes are now one object as opposed to being segmented
- Accuracy display, Notes-per-second display, judgement counter
- Revamped BPM and scroll speed system; Scroll speed can change without affecting the distance between notes
- Optional alternate scroll speed system which calculates based on beats instead of time
- Camera and health icon bumping uses tweens instead of lerping
- Stepmania chart support, including mines, rolls, pauses, and scroll speed changes
- Options menu allowing tons of customization, accessible from the main menu as well as in-game
- Noteskin system which allows different skins to be selected from the options menu, as well as multiple types for each skin
- Customizable credits menu
- Characters, stages, events, weeks, etc. are all loaded externally, including base game ones
- Polymod support with a built-in mod menu and mod creation tools
- Packages system which makes it easy to create and switch between total conversion mods
- Hscript support for many aspects of the game, as well as many of the menus
- Notes, sustains, and strumline notes all have variables to assist with modchart creation and effects
- Completely revamped chart editor based on ArrowVortex
- Video support made possible by PolybiusProxy and KadeDev
- Texture Atlas support made possible by CheemsAndFriends and DotWith
- Possibly some other stuff I'm forgetting