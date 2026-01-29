#!/usr/bin/env python3
"""Calculate total trash HP for Dire Maul North"""

trash_mobs = [
    {"name": "Gordok Brute", "level": 58, "hp": 15791, "count": 30},
    {"name": "Gordok Brute", "level": 57, "hp": 15312, "count": 5},
    {"name": "Gordok Reaver", "level": 59, "hp": 16286, "count": 11},
    {"name": "Gordok Reaver", "level": 58, "hp": 15791, "count": 4},
    {"name": "Gordok Captain", "level": 60, "hp": 16117, "count": 2},
    {"name": "Gordok Captain", "level": 59, "hp": 15635, "count": 4},
    {"name": "Gordok Mage-Lord", "level": 58, "hp": 11055, "count": 14},
    {"name": "Gordok Mage-Lord", "level": 57, "hp": 10720, "count": 11},
    {"name": "Gordok Warlock", "level": 60, "hp": 11748, "count": 13},
    {"name": "Gordok Warlock", "level": 59, "hp": 11402, "count": 2},
    {"name": "Gordok Mastiff", "level": 59, "hp": 4397, "count": 62},
    {"name": "Gordok Mastiff", "level": 56, "hp": 4134, "count": 3},
    {"name": "Doomguard Minion", "level": 60, "hp": 4029, "count": 10},
    {"name": "Doomguard Minion", "level": 59, "hp": 3908, "count": 6},
    {"name": "Carrion Swarmer", "level": 58, "hp": 947, "count": 36},
    {"name": "Carrion Swarmer", "level": 56, "hp": 890, "count": 36},
    {"name": "Wandering Eye of Kilrogg", "level": 60, "hp": 336, "count": 2},
]

total_hp = 0
print("Dire Maul North - Trash HP Calculation")
print("=" * 60)

for mob in trash_mobs:
    mob_total = mob["hp"] * mob["count"]
    total_hp += mob_total
    print(f"{mob['name']:30s} (Lv{mob['level']:2d}): {mob['hp']:6d} x {mob['count']:3d} = {mob_total:9,d}")

print("=" * 60)
print(f"{'TOTAL TRASH HP:':30s}                          {total_hp:12,d}")
print(f"\n50% required = {total_hp * 0.5:,.0f}")
