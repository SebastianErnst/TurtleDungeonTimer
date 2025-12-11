# Turtle Dungeon Timer

Advanced dungeon and raid timer addon for Turtle WoW / Vanilla WoW (1.12).

## Features

- ⏱️ **Precise Timer** - Accurate timing with 5-second countdown
- 🎯 **Boss Tracking** - Automatic detection of boss kills via combat log
- 📊 **Best Times** - Persistent storage of your best runs
- ⚡ **Split Times** - See time between each boss kill
- 💀 **Death Counter** - Tracks player deaths during runs
- 📢 **Report System** - Share your times in Say/Party/Raid/Guild chat
- 📦 **All Content** - Pre-configured for all Classic dungeons and raids
- 🎨 **Clean UI** - Compact, collapsible interface with scrollable boss list

## Installation

1. Download or clone this repository
2. Copy the `TurtleDungeonTimer` folder to `World of Warcraft\Interface\AddOns\`
3. Restart WoW or type `/reload` in-game
4. Type `/tdt` to open the timer window

## Usage

### Commands

- `/tdt` or `/tdt toggle` - Toggle timer window
- `/tdt start` - Start timer countdown
- `/tdt stop` - Stop current timer
- `/tdt hide` - Hide timer window
- `/tdt help` - Show command list

### Quick Start

1. Open the timer with `/tdt`
2. Select your dungeon/raid from the dropdown
3. If the dungeon has variants (e.g., Scarlet Monastery), select the wing
4. Click **START** when you're ready to begin
5. The timer will automatically detect boss kills and update
6. Click **REPORT** to share your time in chat

### UI Elements

- **Header** - Click to collapse/expand boss list
- **Dungeon Selector** - Choose dungeon and variant
- **START Button** - Begin 5-second countdown
- **STOP Button** - Manually stop the timer
- **REPORT Button** - Share results to chat channel
- **Boss List** - Shows all bosses with kill times and splits
- **Deaths** - Displays death count during run

### Best Times

The addon automatically saves your best time for each dungeon/variant combination. Best times are displayed in the header and persist between sessions.

- **Green time** = Currently ahead of best time
- **Red time** = Currently behind best time
- **Yellow time** = Countdown in progress

## Supported Content

### Dungeons (20)
- Ragefire Chasm, Wailing Caverns, Deadmines, Shadowfang Keep
- Blackfathom Deeps, Stockade, Gnomeregan, Razorfen Kraul
- Scarlet Monastery (4 wings), Razorfen Downs, Uldaman
- Zul'Farrak, Maraudon (3 routes), Temple of Atal'Hakkar
- Blackrock Depths (3 routes), Lower/Upper Blackrock Spire
- Dire Maul (3 wings), Stratholme (2 routes), Scholomance

### Raids (7)
- Molten Core, Onyxia's Lair, Blackwing Lair
- Zul'Gurub, Ruins of Ahn'Qiraj, Temple of Ahn'Qiraj
- Naxxramas

## File Structure

```
TurtleDungeonTimer/
├── TurtleDungeonTimer.toc  # Addon manifest
├── Core.lua                # Main singleton and initialization
├── Data.lua                # Dungeon/raid database
├── UI.lua                  # Main UI creation
├── UIMenus.lua             # Dropdown menus and boss rows
├── Timer.lua               # Timer logic and updates
├── Events.lua              # Event handlers (boss kills, deaths)
└── Commands.lua            # Slash commands
```

## Technical Details

- **SavedVariables**: `TurtleDungeonTimerDB`
- **Lua Version**: 5.0 (Vanilla WoW compatible)
- **Interface**: 11200 (Patch 1.12)
- **Dependencies**: None

## Credits

Developed for the Turtle WoW community.

## License

Free to use and modify.
