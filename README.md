# ChatCleaner

A World of Warcraft addon that cleans up the chat, making it prettier and easier on the eye.

## Description

ChatCleaner filters and reformats chat messages to reduce clutter and improve readability. It handles:

- **Loot messages** - Consolidates multiple loot pickups into cleaner summaries
- **Money** - Formats gold/silver/copper with icons
- **Experience & Reputation** - Cleaner XP and rep gain messages
- **Achievements** - Streamlined achievement notifications
- **Spells & Abilities** - Consolidated spell learning messages
- **Auctions** - Cleaner auction house notifications
- **Quest updates** - Simplified quest progress messages
- **Channel names** - Shortened channel prefixes
- **Player names** - Class-colored names in chat
- **Item quality** - Color-coded item names by rarity

## Version Information

- **Original Version**: 2.0.59 (Retail WoW 10.0.0+)
- **Backported Version**: 3.3.5a WotLK Client
- **Target Platform**: Ascension WoW Private Server

## Installation

1. Download the addon
2. Extract to `Interface\AddOns\ChatCleaner`
3. Restart WoW or type `/reload`

## Commands

- `/chatcleaner` or `/cc` - Open options panel

## Credits

**Original Author**: Lars Norberg (Goldpaw)
- [PayPal](https://www.paypal.me/GoldpawsStuff)
- [Patreon](https://www.patreon.com/GoldpawsStuff)
- [CurseForge](https://www.curseforge.com/wow/addons/chatcleaner) (Project ID: 531109)
- [Wago](https://addons.wago.io/addons/chatcleaner) (ID: baNDwAGo)

**3.3.5 WotLK Backport**: migwynkriid
- Backported for use with the Ascension WoW private server (3.3.5a client)

## License

Custom License - See [LICENSE.txt](LICENSE.txt)

Copyright (c) 2021 Lars Norberg

Permission is hereby granted to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software. The above copyright notice and this permission notice shall be included in all copies. Artwork and media assets may not be redistributed.

## Backport Notes

This version has been modified to work with the 3.3.5a WotLK client. Changes include:

- Interface version set to 30300
- C_Timer polyfill for timer functionality
- C_AddOns compatibility shims
- Removed retail-only API calls (TextureLoadingGroupMixin, ChatFrame_ContainsMessageGroup, etc.)
- Disabled TaintLess library (retail-only)
- Fixed AddMessage parameters for 3.3.5 compatibility
- Safe pattern matching with nil checks
