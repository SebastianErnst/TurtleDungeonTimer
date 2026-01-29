#!/usr/bin/env python3
"""Calculate total trash HP for UBRS and LBRS"""

print("=" * 70)
print("UPPER BLACKROCK SPIRE (UBRS)")
print("=" * 70)

ubrs_trash = [
    {"name": "Scarshield Legionnaire", "level": 54, "hp": 8867, "count": 9},
    {"name": "Rage Talon Dragonspawn", "level": 59, "hp": 16286, "count": 9},
    {"name": "Blackhand Summoner", "level": 60, "hp": 8059, "count": 9},
    {"name": "Blackhand Veteran", "level": 59, "hp": 9771, "count": 26},
    {"name": "Blackhand Dreadweaver", "level": 59, "hp": 7818, "count": 8},
    {"name": "Rage Talon Dragonspawn", "level": 58, "hp": 15791, "count": 12},
    {"name": "Blackhand Veteran", "level": 60, "hp": 10072, "count": 8},
    {"name": "Blackhand Dreadweaver", "level": 60, "hp": 8059, "count": 11},
    {"name": "Blackhand Summoner", "level": 59, "hp": 7818, "count": 5},
    {"name": "Rookery Whelp", "level": 57, "hp": 3344, "count": 8},
    {"name": "Rage Talon Flamescale", "level": 58, "hp": 7580, "count": 7},
    {"name": "Rookery Whelp", "level": 56, "hp": 3242, "count": 12},
    {"name": "Rage Talon Flamescale", "level": 59, "hp": 7818, "count": 2},
    {"name": "Rookery Hatcher", "level": 59, "hp": 9771, "count": 7},
    {"name": "Rookery Hatcher", "level": 58, "hp": 9474, "count": 2},
    {"name": "Rookery Guardian", "level": 58, "hp": 11053, "count": 1},
    {"name": "Blackhand Elite", "level": 60, "hp": 16786, "count": 8},
    {"name": "Blackhand Elite", "level": 61, "hp": 17292, "count": 8},
    {"name": "Blackhand Thug", "level": 60, "hp": 16786, "count": 2},
    {"name": "Chromatic Whelp", "level": 57, "hp": 4831, "count": 27},
    {"name": "Chromatic Dragonspawn", "level": 60, "hp": 19984, "count": 9},
    {"name": "Blackhand Dragon Handler", "level": 59, "hp": 12902, "count": 5},
    {"name": "Rage Talon Fire Tongue", "level": 61, "hp": 20750, "count": 5},
    {"name": "Blackhand Assassin", "level": 61, "hp": 17292, "count": 11},
    {"name": "Rage Talon Dragon Guard", "level": 61, "hp": 20750, "count": 8},
    {"name": "Blackhand Iron Guard", "level": 60, "hp": 13429, "count": 6},
    {"name": "Blackhand Iron Guard", "level": 61, "hp": 13834, "count": 11},
    {"name": "Rage Talon Captain", "level": 62, "hp": 19422, "count": 5},
    {"name": "Rage Talon Fire Tongue", "level": 60, "hp": 20143, "count": 2},
]

ubrs_total = 0
for mob in ubrs_trash:
    mob_total = mob["hp"] * mob["count"]
    ubrs_total += mob_total
    print(f"{mob['name']:30s} (Lv{mob['level']:2d}): {mob['hp']:6d} x {mob['count']:3d} = {mob_total:9,d}")

print("=" * 70)
print(f"{'UBRS TOTAL TRASH HP:':30s}                          {ubrs_total:12,d}")
print(f"50% required = {ubrs_total * 0.5:,.0f}")

print("\n" + "=" * 70)
print("LOWER BLACKROCK SPIRE (LBRS)")
print("=" * 70)

lbrs_trash = [
    {"name": "Scarshield Legionnaire", "level": 55, "hp": 9151, "count": 31},
    {"name": "Scarshield Spellbinder", "level": 55, "hp": 7319, "count": 8},
    {"name": "Scarshield Acolyte", "level": 55, "hp": 7319, "count": 3},
    {"name": "Scarshield Acolyte", "level": 54, "hp": 7092, "count": 4},
    {"name": "Scarshield Raider", "level": 55, "hp": 9151, "count": 3},
    {"name": "Scarshield Worg", "level": 54, "hp": 3916, "count": 5},
    {"name": "Scarshield Spellbinder", "level": 54, "hp": 7092, "count": 9},
    {"name": "Scarshield Raider", "level": 56, "hp": 9448, "count": 3},
    {"name": "Scarshield Worg", "level": 53, "hp": 3792, "count": 9},
    {"name": "Scarshield Legionnaire", "level": 54, "hp": 8867, "count": 11},
    {"name": "Scarshield Warlock", "level": 54, "hp": 7092, "count": 5},
    {"name": "Scarshield Warlock", "level": 55, "hp": 7319, "count": 4},
    {"name": "Spirestone Enforcer", "level": 54, "hp": 14779, "count": 4},
    {"name": "Spirestone Ogre Magus", "level": 54, "hp": 11821, "count": 2},
    {"name": "Spirestone Battle Mage", "level": 57, "hp": 12249, "count": 3},
    {"name": "Spirestone Reaver", "level": 55, "hp": 15252, "count": 3},
    {"name": "Spirestone Warlord", "level": 57, "hp": 15312, "count": 3},
    {"name": "Spirestone Mystic", "level": 56, "hp": 12597, "count": 2},
    {"name": "Spirestone Warlord", "level": 58, "hp": 15791, "count": 6},
    {"name": "Spirestone Ogre Magus", "level": 55, "hp": 12199, "count": 3},
    {"name": "Spirestone Mystic", "level": 55, "hp": 12199, "count": 1},
    {"name": "Smolderthorn Axe Thrower", "level": 55, "hp": 9151, "count": 3},
    {"name": "Smolderthorn Shadow Priest", "level": 56, "hp": 7558, "count": 6},
    {"name": "Smolderthorn Mystic", "level": 55, "hp": 7319, "count": 5},
    {"name": "Smolderthorn Shadow Priest", "level": 55, "hp": 7319, "count": 11},
    {"name": "Smolderthorn Mystic", "level": 56, "hp": 7558, "count": 5},
    {"name": "Smolderthorn Shadow Hunter", "level": 56, "hp": 7779, "count": 4},
    {"name": "Smolderthorn Axe Thrower", "level": 56, "hp": 9448, "count": 6},
    {"name": "Smolderthorn Seer", "level": 57, "hp": 8023, "count": 3},
    {"name": "Smolderthorn Shadow Hunter", "level": 57, "hp": 8023, "count": 2},
    {"name": "Smolderthorn Headhunter", "level": 57, "hp": 10031, "count": 5},
    {"name": "Smolderthorn Berserker", "level": 57, "hp": 9187, "count": 8},
    {"name": "Smolderthorn Witch Doctor", "level": 57, "hp": 8023, "count": 5},
    {"name": "Smolderthorn Seer", "level": 56, "hp": 7779, "count": 7},
    {"name": "Smolderthorn Headhunter", "level": 56, "hp": 9724, "count": 5},
    {"name": "Smolderthorn Witch Doctor", "level": 56, "hp": 7779, "count": 2},
    {"name": "Smolderthorn Berserker", "level": 58, "hp": 9474, "count": 4},
    {"name": "Firebrand Darkweaver", "level": 56, "hp": 7779, "count": 8},
    {"name": "Firebrand Grunt", "level": 56, "hp": 9724, "count": 5},
    {"name": "Firebrand Invoker", "level": 56, "hp": 7779, "count": 5},
    {"name": "Firebrand Legionnaire", "level": 58, "hp": 9474, "count": 1},
    {"name": "Firebrand Invoker", "level": 57, "hp": 8023, "count": 5},
    {"name": "Firebrand Darkweaver", "level": 57, "hp": 8023, "count": 4},
    {"name": "Firebrand Grunt", "level": 57, "hp": 10031, "count": 17},
    {"name": "Firebrand Dreadweaver", "level": 58, "hp": 7580, "count": 4},
    {"name": "Firebrand Legionnaire", "level": 57, "hp": 9187, "count": 2},
    {"name": "Firebrand Pyromancer", "level": 57, "hp": 7349, "count": 3},
    {"name": "Spire Spiderling", "level": 55, "hp": 3050, "count": 32},
    {"name": "Spire Spiderling", "level": 56, "hp": 3149, "count": 9},
    {"name": "Spirestone Battle Mage", "level": 58, "hp": 12634, "count": 1},
    {"name": "Bloodaxe Raider", "level": 57, "hp": 9187, "count": 4},
    {"name": "Bloodaxe Worg", "level": 56, "hp": 3242, "count": 8},
    {"name": "Bloodaxe Veteran", "level": 59, "hp": 9771, "count": 10},
    {"name": "Bloodaxe Warmonger", "level": 58, "hp": 9474, "count": 7},
    {"name": "Bloodaxe Evoker", "level": 59, "hp": 7818, "count": 4},
    {"name": "Bloodaxe Summoner", "level": 58, "hp": 7580, "count": 6},
    {"name": "Bloodaxe Worg", "level": 57, "hp": 3344, "count": 8},
    {"name": "Bloodaxe Warmonger", "level": 57, "hp": 9187, "count": 5},
    {"name": "Bloodaxe Raider", "level": 58, "hp": 9474, "count": 3},
    {"name": "Bloodaxe Veteran", "level": 58, "hp": 9474, "count": 6},
    {"name": "Bloodaxe Evoker", "level": 58, "hp": 7580, "count": 7},
    {"name": "Bloodaxe Worg Pup", "level": 53, "hp": 3940, "count": 2},
    {"name": "Bloodaxe Summoner", "level": 57, "hp": 7349, "count": 3},
]

lbrs_total = 0
for mob in lbrs_trash:
    mob_total = mob["hp"] * mob["count"]
    lbrs_total += mob_total
    print(f"{mob['name']:30s} (Lv{mob['level']:2d}): {mob['hp']:6d} x {mob['count']:3d} = {mob_total:9,d}")

print("=" * 70)
print(f"{'LBRS TOTAL TRASH HP:':30s}                          {lbrs_total:12,d}")
print(f"50% required = {lbrs_total * 0.5:,.0f}")
