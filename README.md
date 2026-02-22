# Turtle Dungeon Timer

**Version:** 0.15.20  
**Author:** Zasamel  
**Interface:** 11200 (WoW 1.12 - Vanilla)

A dungeon timer for Turtle WoW with boss tracking, best times, and group synchronization.

---

## Features

- ⏱️ **Precise Timing**: Second-accurate measurement for dungeon runs
- 📊 **Boss & Trash Tracking**: Automatic detection of all kills via combat log
- 💀 **Death Counter**: Tracks group deaths with automatic detection
- 📜 **Run History**: Saves the last 500 runs with complete details
- 🔄 **Group Sync**: Synchronizes timer, boss kills, and resets across the group
- 🎯 **World Buff System**: Detects 21 world buffs and optionally removes them during runs
- 📤 **Export System**: Base64-encoded export strings for external tracking tools
- 🖱️ **Minimap Button**: Quick access via minimap icon
- 🗳️ **Voting System**: Democratic ready checks and reset votes

---

## Installation

### Via TWoW Launcher (recommended)
The easiest way - updates are applied automatically:

1. Copy the GitHub URL
2. Open TWoW Launcher → "Addons" → "+ Add new addon"
3. Paste the URL
4. Restart the game

### Manual Installation

1. Download the .zip and extract it
2. Move the folder to:
   ```
   <WoW-Directory>\Interface\AddOns\TurtleDungeonTimer
   ```
3. **Important**: Folder must be named "TurtleDungeonTimer" (remove "-main" if present)
4. Restart game or type `/reload`

---

## Usage

### Commands

```
/tdt              -- Open/close timer window
/tdt help         -- Show help
/tdt version      -- Show version
```

### Run Workflow

1. **Start Preparation**: Click "START" button (group leader only)
2. **Select Dungeon**: Choose dungeon and variant from the list
3. **World Buffs**: Decide "With World Buffs" or "Without World Buffs"
   - **With World Buffs**: All buffs allowed during the run
   - **Without World Buffs**: All world buffs continuously removed
4. **Ready Check**: Group votes if everyone is ready
5. **Enter Dungeon**: Countdown starts automatically upon entering
6. **Start Run**: Timer starts after countdown (0) or on first pull
7. **Kill Bosses & Trash**: Timer automatically tracks all kills
8. **Complete Run**: All required bosses + trash dead = run is saved

**⚠️ Important**: Run aborts if someone leaves or joins the group!

### Minimap Button

- **Left-Click**: Open/close timer window
- **Drag**: Move position around minimap

---

## Supported Dungeons

- **Black Morass**
- **Blackrock Spire** (Upper/Lower)
- **Dire Maul** (North/East/West)
- **Karazhan Crypt**
- **Scholomance**
- **Stormwind Vault**
- **Stratholme** (Living/Undead)

---

## Known Limitations

- Boss detection based on exact combat log names
- Sync system requires same addon version across group
- Only the last 500 runs are saved
- Export function only (no import possible)

---

## Troubleshooting

### Timer doesn't start
- Check if a dungeon is selected
- Ensure at least 1 boss is defined
- Check if run is already completed

### Boss kills not detected
- Boss name must exactly match the definition
- Combat log must contain "X dies." or "X has died."
- Enable Lua errors: `/console scriptErrors 1`

### Sync not working
- All group members must have the addon installed
- Addon version must match for everyone
- Check version with: `/tdt version`

### World Buffs not detected
- Buff name must match exactly
- Check occurs 0.5s after timer start
- 21 world buffs are tracked (see WorldBuffs.lua)

---

## Changelog

### v0.15.1 (Current)
- ✨ World Buff System: 21 buffs including all Sayge's Fortune variants
- 🎨 Compact World Buff dialog with hover tooltip
- 🔧 Dynamic World Buff list instead of hardcoded values
- 🗳️ Improved voting system for ready checks
- 📊 History browser with overlay system
- 🐛 Various bug fixes and performance improvements

### v0.15.0
- 🎉 First public alpha version
- ⏱️ Core timer functionality
- 🔄 Group sync system
- 📤 Export feature
- 🗺️ Minimap button

---

## Credits

- **Development**: Zasamel
- **Testing**: TurtleWoW Dungeon-Runner Community

---

## License

MIT License - See LICENSE file for details
