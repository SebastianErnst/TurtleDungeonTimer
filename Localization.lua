-- ============================================================================
-- Turtle Dungeon Timer - Localization System
-- ============================================================================
-- Provides multi-language support for all chat messages and UI text
-- Automatically detects client language and falls back to English

TurtleDungeonTimer.L = {}
local L = TurtleDungeonTimer.L

-- ============================================================================
-- Language Detection
-- ============================================================================
local clientLocale = GetLocale() or "enUS"
local currentLanguage = "enUS"

-- Map WoW locales to our language codes
local localeMapping = {
    ["enUS"] = "enUS",
    ["enGB"] = "enUS",
    ["deDE"] = "deDE",
    ["frFR"] = "frFR",
    ["esES"] = "esES",
    ["ruRU"] = "ruRU",
    ["zhCN"] = "zhCN",
    ["zhTW"] = "zhTW"
}

-- Force English language (override client locale)
-- Set this to nil to use automatic client locale detection
TurtleDungeonTimer.forceLanguage = "enUS"

currentLanguage = TurtleDungeonTimer.forceLanguage or localeMapping[clientLocale] or "enUS"

-- ============================================================================
-- Translation Tables
-- ============================================================================
local translations = {}

-- English (Default/Fallback)
translations.enUS = {
    -- General
    ["ADDON_NAME"] = "Turtle Dungeon Timer",
    ["YES"] = "Yes",
    ["NO"] = "No",
    
    -- Preparation System
    ["PREP_ONLY_LEADER"] = "Only the group leader can prepare the run!",
    ["PREP_NO_DUNGEON"] = "No dungeon selected!",
    ["PREP_STARTING"] = "Starting run preparation for %s...",
    ["PREP_RUN_READY"] = "Run ready! You can now enter the instance.",
    ["PREP_ALL_SAME_VERSION"] = "Everyone has the same version",
    ["PREP_VERSION_MISMATCH"] = "Version mismatch! Not everyone has the same version.",
    ["PREP_ALL_HAVE_ADDON"] = "Everyone has the addon",
    ["PREP_ADDON_CHECK"] = "Addon Check",
    ["PREP_VERSION_CHECK"] = "Version Check",
    ["PREP_RESETTING_INSTANCE"] = "Resetting instance...",
    ["PREP_INSTANCE_RESET"] = "Instance has been reset",
    ["PREP_RESET_SKIPPED"] = "Reset skipped (5/hour limit)",
    
    -- Ready Check
    ["READY_CHECK_START"] = "Starting Ready Check...",
    ["READY_CHECK_LEADER_AUTO"] = "You (Leader) are automatically ready",
    ["READY_CHECK_ALL_RESPONDED"] = "Everyone has responded!",
    ["READY_CHECK_RESULTS"] = "Ready Check Results",
    ["READY_CHECK_READY"] = "Ready",
    ["READY_CHECK_NOT_READY"] = "Not Ready",
    ["READY_CHECK_NO_RESPONSE"] = "No Response",
    
    -- World Buffs
    ["WORLD_BUFFS_DETECTED"] = "World Buffs detected! Run will be marked as 'With World Buffs'. (%d players)",
    
    -- Sync Messages
    ["SYNC_DATA_FROM"] = "Run data synchronized from %s: %s",
    ["SYNC_VERSION_WARNING"] = "Warning: %s has incompatible addon version (%s). Sync might fail!",
    ["SYNC_NO_RESPONSES"] = "No responses received",
    ["SYNC_COUNTDOWN_INTERRUPTED"] = "Countdown was interrupted - waiting for group data...",
    ["SYNC_GROUP_IN_COUNTDOWN"] = "Group is in countdown - timer will start soon",
    ["SYNC_TIMER_CONTINUED"] = "Timer continued after reload (Offline time: %s)",
    ["RUN_ABORTED_GROUP_CHANGE"] = "Run aborted! Group composition changed (player joined/left).",
    
    -- Trash Scanner
    ["TRASH_NO_TARGET"] = "No target!",
    ["TRASH_NO_NAME"] = "Could not read target name!",
    ["TRASH_TARGET_IS_PLAYER"] = "Target is a player, skipped.",
    ["TRASH_NO_DUNGEON"] = "No dungeon selected! Select a dungeon first.",
    ["TRASH_COUNT_INCREASED"] = "Count increased: %s - HP: %d (Count: %d)",
    ["TRASH_SAVED"] = "Saved: %s - HP: %d",
    ["TRASH_TOTAL_MOBS"] = "%s now has %d different mobs saved.",
    ["TRASH_DELETED"] = "%d mobs for %s deleted.",
    ["TRASH_NO_DATA"] = "No data for %s available.",
    ["TRASH_ALL_DELETED"] = "ALL data deleted! (%d dungeons, %d mobs)",
    ["TRASH_NO_EXPORT_DATA"] = "No data to export!",
    ["TRASH_EXPORT_HEADER"] = "TDT Trash Scanner Export",
    ["TRASH_EXPORT_INFO"] = "Export for %d dungeons with %d mobs",
    ["TRASH_COPY_TO_DATA"] = "-- Copy this data to Data.lua:",
    
    -- Boss Kills
    ["BOSS_KILL_DETECTED"] = "Boss kill detected: %s",
    
    -- Export
    ["EXPORT_NO_DATA"] = "No data to export.",
    
    -- UI Tooltips
    ["TOOLTIP_ALL_SAME_VERSION"] = "- Everyone has the addon (same version)",
    ["TOOLTIP_PREPARE_RUN"] = "Prepare Run",
    ["TOOLTIP_PREPARE_RUN_DESC"] = "Start a fresh run with dungeon reset.",
    ["TOOLTIP_STOP_TIMER"] = "Stop Timer",
    ["TOOLTIP_REQUIREMENTS"] = "Requirements:",
    ["TOOLTIP_ALL_HAVE_ADDON"] = "- Everyone has the addon (same version)",
    ["TOOLTIP_NO_ONE_IN_DUNGEON"] = "- No one must be in the dungeon",
    ["TOOLTIP_ONLY_LEADER"] = "Only the group leader can start the run",
    ["TOOLTIP_RUN_HISTORY"] = "Run History",
    ["TOOLTIP_RUN_HISTORY_DESC"] = "Shows past runs and best times",
    
    -- UI Elements
    ["UI_PREPARE_RUN_TITLE"] = "Prepare Run - Select Dungeon",
    ["UI_NO_BOSS_DATA"] = "No boss data available",
    ["UI_NO_DUNGEON_SELECTED"] = "No dungeon selected",
    ["UI_LEADER_SELECT_DUNGEON"] = "No active Dungeon",
    ["UI_RESET_VOTE_QUESTION"] = "Do you want to start a reset vote\nin the group?",
    ["UI_RESET_VOTE_MESSAGE"] = "%s wants to reset the timer.",
    ["UI_EXPORT_QUESTION"] = "Do you want to export\nyour run?",
    ["UI_SKIP_BUTTON"] = "Skip",    ["UI_CANCEL_BUTTON"] = "Cancel",
    ["UI_YES_BUTTON"] = "Yes",
    ["UI_NO_BUTTON"] = "No",
    ["UI_CLOSE_BUTTON"] = "Close",
    ["UI_EXPORT_BUTTON"] = "Export",
    ["UI_WORLDBUFFS_DETECTED"] = "World buffs detected",
    ["TOOLTIP_WORLDBUFFS_TITLE"] = "World Buffs",
    ["TOOLTIP_WORLDBUFFS_DESC"] = "Players with active World Buffs:",
    ["UI_WORLDBUFF_CONFIRM_TITLE"] = "World Buffs Detected!",
    ["UI_WORLDBUFF_CONFIRM_QUESTION"] = "Start run with or without World Buffs?",
    ["UI_WORLDBUFF_PLAYERS_TITLE"] = "Players with World Buffs:",
    ["UI_WORLDBUFF_LIST_TITLE"] = "World Buffs tracked:",
    ["UI_WITH_WORLDBUFFS"] = "With World Buffs",
    ["UI_WITHOUT_WORLDBUFFS"] = "Without World Buffs",
    ["UI_WORLDBUFF_TRACKING_INFO"] = "Info: If World Buffs are activated after the timer starts (first combat or countdown ends), this run will be permanently marked as 'With World Buffs'.",
    ["UI_WORLDBUFF_REMOVAL_INFO"] = "Note: If 'Without World Buffs' is selected, all current World Buffs will be removed from all group members.",
    ["WORLDBUFF_REMOVED_BY_LEADER"] = "World Buffs removed by group leader %s.",
    ["READY_CHECK_WITH_WB"] = "This run has active World Buffs!",
    ["READY_CHECK_WITHOUT_WB"] = "This run is WITHOUT active World Buffs",
    ["READY_CHECK_WB_REMOVED"] = "All current World Buffs will be removed as this run is without World Buffs.",
    ["UI_READY_CHECK_TITLE"] = "Ready Check",
    ["UI_READY_CHECK_QUESTION"] = "Are you ready for the dungeon run?",
    ["UI_READY_CHECK_DUNGEON"] = "Start dungeon run for %s?",
    ["UI_COUNTDOWN_TITLE"] = "Run starts in...",
    ["UI_COUNTDOWN_GO"] = "GO!",
    ["UI_NEW_DUNGEON_DETECTED"] = "New Dungeon Detected",
    ["UI_NEW_DUNGEON_MESSAGE"] = "You are entering %s.\\n\\nReset current run?",
    ["UI_EXPORT_TITLE"] = "Export Run Data",
    ["UI_EXPORT_DESCRIPTION"] = "Export string is also printed in chat for easy copying.",    
    ["UI_ABORT_RUN_TITLE"] = "Abort Run?",
    ["UI_ABORT_RUN_MESSAGE"] = "Do you want to abort the current run?",
    ["UI_ABORT_VOTE_MESSAGE"] = "%s wants to abort the run.",
    ["UI_ABORT_VOTE_QUESTION"] = "Do you agree?",
    ["UI_ABORT_REQUEST_SENT"] = "You have submitted an abort request",
    ["UI_ABORT_BY_GROUP"] = "Run was aborted (group decision)",
    ["UI_ABORT_DECLINED"] = "Abort was declined",
    ["UI_ABORT_VOTE_STATUS"] = "Abort Vote: %d/%d (YES: %d)",
    ["UI_ABORT_BY_GROUP_SYNC"] = "Run was aborted by the group",
    
    -- Debug Messages (keep in English for consistency)
    ["DEBUG_PREFIX"] = "[Debug]",
    ["DEBUG_SYNC_PREFIX"] = "[Debug Sync]",
    ["DEBUG_TRASH_PREFIX"] = "[TDT Trash Debug]",
    ["DEBUG_TIMER_ALREADY_RUNNING"] = "Timer is already running!",
    ["DEBUG_COUNTDOWN_STARTED"] = "Countdown started!",
    ["DEBUG_TIMER_STARTED_DIRECT"] = "Timer started directly!",
    ["DEBUG_NO_BOSSES_LOADED"] = "No bosses loaded!",
    
    -- TrashScanner Messages
    ["TRASH_SCANNER_TARGET_PLAYER"] = "Target is a player, skipped.",
    ["TRASH_SCANNER_NO_DUNGEON"] = "No dungeon selected! Select a dungeon first.",
    ["TRASH_SCANNER_COUNT_INCREASED"] = "Count increased: %s - HP: %d (Count: %d)",
    ["TRASH_SCANNER_SAVED"] = "Saved: %s - HP: %d",
    ["TRASH_SCANNER_DELETED_COUNT"] = "%d mobs deleted for %s.",
    ["TRASH_SCANNER_NO_DATA"] = "No data available for %s.",
    ["TRASH_SCANNER_ALL_DELETED"] = "ALL data deleted! (%d dungeons, %d mobs)",
    ["TRASH_SCANNER_EXPORT_INFO"] = "Export for %d dungeons with %d mobs",
    ["TRASH_SCANNER_DUNGEON_INFO"] = "%s: %d different mobs, %d total counted",
    ["TRASH_SCANNER_TOTAL_INFO"] = "Total: %d dungeons, %d different, %d counted",
    ["TRASH_SCANNER_DELETED_MOB"] = "Deleted: %s (HP: %d)",
    ["TRASH_SCANNER_DELETED_MOB_COUNT"] = "Deleted: %s (Count was 1)",
    
    -- TrashCounter Messages
    ["TRASH_COUNTER_DONE"] = "Trash done! %d bosses remaining.",
    
    -- Timer Messages
    ["TIMER_RESET"] = "Timer has been reset",
    
    -- Preparation Messages
    ["PREP_LEADER_ONLY_PREPARE"] = "Only the group leader can prepare the run!",
    ["PREP_NO_DUNGEON_SELECTED"] = "No dungeon selected!",
    ["PREP_STARTING_FOR"] = "Starting run preparation for %s...",
    ["PREP_RESETTING_INSTANCE_MSG"] = "Resetting instance...",
    ["PREP_RESET_SKIPPED_LIMIT"] = "Reset skipped (5/hour limit)",
    ["PREP_INSTANCE_RESET_SUCCESS"] = "Instance has been reset",
    ["PREP_RUN_READY_MSG"] = "Run ready! You can now enter the instance.",
    ["PREP_RESET_CURRENT_RUN"] = "Resetting current run...",
    ["PREP_DUNGEON_CHANGED"] = "%s has selected a different dungeon: %s (you have: %s)",
    ["PREP_ADDON_CHECK"] = "Addon Check",
    ["PREP_MISSING"] = "(missing)",
    ["PREP_ALL_HAVE_ADDON"] = "All have the addon",
    ["PREP_NOT_ALL_HAVE_ADDON"] = "Not all group members have the addon installed!",
    ["PREP_VERSION_CHECK"] = "Version Check",
    ["PREP_EXPECTED_VERSION"] = "(expected: v%s)",
    ["PREP_ALL_SAME_VERSION"] = "All have the same version",
    ["PREP_VERSION_MISMATCH"] = "Version mismatch! Not all have the same version.",
    ["PREP_STARTING_READY_CHECK"] = "Starting Ready Check...",
    ["PREP_LEADER_AUTO_READY"] = "You (Leader) are automatically ready",
    ["PREP_ALL_RESPONDED"] = "All have responded!",
    ["PREP_READY_CHECK_RESULTS"] = "Ready Check Results",
    ["PREP_NO_RESPONSE"] = "(No Response)",
    ["PREP_ALL_READY"] = "All are ready!",
    ["PREP_FAILED"] = "Preparation failed:",
    ["PREP_NOT_ALL_READY"] = "Not all are ready! Prepare yourself and try again.",
    ["PREP_ENTERED_COUNTDOWN"] = "%s has entered the instance! Countdown starts in 10 seconds...",
    ["PREP_COUNTDOWN_CANCELLED"] = "Countdown cancelled - Timer started!",
    ["PREP_RUN_STARTED"] = "Run started! Good luck!",
    ["PREP_FAILED_REASON"] = "Preparation failed: %s",
}

-- German (Deutsch)
translations.deDE = {
    -- General
    ["ADDON_NAME"] = "Turtle Dungeon Timer",
    
    -- Preparation System
    ["PREP_ONLY_LEADER"] = "Nur der Gruppenführer kann den Run vorbereiten!",
    ["PREP_NO_DUNGEON"] = "Kein Dungeon ausgewählt!",
    ["PREP_STARTING"] = "Starte Run-Vorbereitung für %s...",
    ["PREP_RUN_READY"] = "Run bereit! Ihr könnt jetzt die Instanz betreten.",
    ["PREP_ALL_SAME_VERSION"] = "Alle haben die gleiche Version",
    ["PREP_VERSION_MISMATCH"] = "Version mismatch! Nicht alle haben die gleiche Version.",
    ["PREP_ALL_HAVE_ADDON"] = "Alle haben das Addon",
    ["PREP_ADDON_CHECK"] = "Addon Check",
    ["PREP_VERSION_CHECK"] = "Version Check",
    ["PREP_RESETTING_INSTANCE"] = "Setze Instanz zurück...",
    ["PREP_INSTANCE_RESET"] = "Instanz wurde zurückgesetzt",
    ["PREP_RESET_SKIPPED"] = "Reset übersprungen (5/Stunde Limit)",
    
    -- Ready Check
    ["READY_CHECK_START"] = "Starte Ready Check...",
    ["READY_CHECK_LEADER_AUTO"] = "Du (Leader) bist automatisch ready",
    ["READY_CHECK_ALL_RESPONDED"] = "Alle haben geantwortet!",
    ["READY_CHECK_RESULTS"] = "Ready Check Ergebnisse",
    ["READY_CHECK_READY"] = "Ready",
    ["READY_CHECK_NOT_READY"] = "Not Ready",
    ["READY_CHECK_NO_RESPONSE"] = "Keine Antwort",
    
    -- World Buffs
    ["WORLD_BUFFS_DETECTED"] = "World Buffs erkannt! Run wird als 'Mit World Buffs' markiert. (%d Spieler)",
    
    -- Sync Messages
    ["SYNC_DATA_FROM"] = "Run-Daten synchronisiert von %s: %s",
    ["SYNC_VERSION_WARNING"] = "Warnung: %s hat inkompatible Addon-Version (%s). Sync könnte fehlschlagen!",
    ["SYNC_NO_RESPONSES"] = "Keine Antworten erhalten",
    ["SYNC_COUNTDOWN_INTERRUPTED"] = "Countdown wurde unterbrochen - warte auf Gruppendaten...",
    ["SYNC_GROUP_IN_COUNTDOWN"] = "Gruppe ist im Countdown - Timer startet gleich",
    ["SYNC_TIMER_CONTINUED"] = "Timer nach Reload fortgesetzt (Offline Zeit: %s)",
    ["RUN_ABORTED_GROUP_CHANGE"] = "Run abgebrochen! Gruppenzusammensetzung hat sich geändert (Spieler beigetreten/verlassen).",
    
    -- Trash Scanner
    ["TRASH_NO_TARGET"] = "Kein Target vorhanden!",
    ["TRASH_NO_NAME"] = "Konnte Target-Name nicht lesen!",
    ["TRASH_TARGET_IS_PLAYER"] = "Target ist ein Spieler, übersprungen.",
    ["TRASH_NO_DUNGEON"] = "Kein Dungeon ausgewählt! Wähle zuerst einen Dungeon aus.",
    ["TRASH_COUNT_INCREASED"] = "Count erhöht: %s - HP: %d (Count: %d)",
    ["TRASH_SAVED"] = "Gespeichert: %s - HP: %d",
    ["TRASH_TOTAL_MOBS"] = "%s hat jetzt %d verschiedene Mobs gespeichert.",
    ["TRASH_DELETED"] = "%d Mobs für %s gelöscht.",
    ["TRASH_NO_DATA"] = "Keine Daten für %s vorhanden.",
    ["TRASH_ALL_DELETED"] = "ALLE Daten gelöscht! (%d Dungeons, %d Mobs)",
    ["TRASH_NO_EXPORT_DATA"] = "Keine Daten zum Exportieren!",
    ["TRASH_EXPORT_HEADER"] = "TDT Trash Scanner Export",
    ["TRASH_EXPORT_INFO"] = "Export für %d Dungeons mit %d Mobs",
    ["TRASH_COPY_TO_DATA"] = "-- Kopiere diese Daten in Data.lua:",
    
    -- Boss Kills
    ["BOSS_KILL_DETECTED"] = "Boss-Kill erkannt: %s",
    
    -- Export
    ["EXPORT_NO_DATA"] = "Keine Daten zum Exportieren.",
    
    -- UI Tooltips
    ["TOOLTIP_ALL_SAME_VERSION"] = "- Alle haben das Addon (gleiche Version)",
    ["TOOLTIP_PREPARE_RUN"] = "Run vorbereiten",
    ["TOOLTIP_PREPARE_RUN_DESC"] = "Startet einen frischen Run mit Dungeon-Reset.",
    ["TOOLTIP_STOP_TIMER"] = "Timer stoppen",
    ["TOOLTIP_REQUIREMENTS"] = "Requirements:",
    ["TOOLTIP_ALL_HAVE_ADDON"] = "- Alle haben das Addon (gleiche Version)",
    ["TOOLTIP_NO_ONE_IN_DUNGEON"] = "- Niemand darf im Dungeon sein",
    ["TOOLTIP_ONLY_LEADER"] = "Nur der Gruppenführer kann den Run starten",
    ["TOOLTIP_RUN_HISTORY"] = "Run-Historie",
    ["TOOLTIP_RUN_HISTORY_DESC"] = "Zeigt vergangene Runs und Bestzeiten",
    
    -- UI Elements
    ["UI_PREPARE_RUN_TITLE"] = "Run vorbereiten - Dungeon wählen",
    ["UI_NO_BOSS_DATA"] = "Keine Boss-Daten verfügbar",
    ["UI_NO_DUNGEON_SELECTED"] = "Kein Dungeon ausgewählt",
    ["UI_LEADER_SELECT_DUNGEON"] = "Kein Dungeon aktiv",
    ["UI_RESET_VOTE_QUESTION"] = "Möchtest du eine Reset-Abstimmung\nin der Gruppe starten?",
    ["UI_RESET_VOTE_MESSAGE"] = "%s möchte den Timer zurücksetzen.",
    ["UI_EXPORT_QUESTION"] = "Möchtest du deinen Run\nexportieren?",
    ["UI_SKIP_BUTTON"] = "Überspringen",    ["UI_CANCEL_BUTTON"] = "Abbrechen",
    ["UI_YES_BUTTON"] = "Ja",
    ["UI_NO_BUTTON"] = "Nein",
    ["UI_CLOSE_BUTTON"] = "Schließen",
    ["UI_EXPORT_BUTTON"] = "Exportieren",
    ["UI_WORLDBUFFS_DETECTED"] = "World buffs detected",
    ["TOOLTIP_WORLDBUFFS_TITLE"] = "World Buffs",
    ["TOOLTIP_WORLDBUFFS_DESC"] = "Spieler mit aktiven World Buffs:",
    ["UI_WORLDBUFF_CONFIRM_TITLE"] = "World Buffs erkannt!",
    ["UI_WORLDBUFF_CONFIRM_QUESTION"] = "Soll der Run mit oder ohne World Buffs starten?",
    ["UI_WORLDBUFF_PLAYERS_TITLE"] = "Spieler mit World Buffs:",
    ["UI_WORLDBUFF_LIST_TITLE"] = "Getrackte World Buffs:",
    ["UI_WITH_WORLDBUFFS"] = "Mit World Buffs",
    ["UI_WITHOUT_WORLDBUFFS"] = "Ohne World Buffs",
    ["UI_WORLDBUFF_TRACKING_INFO"] = "Info: Falls World Buffs nach dem Timer-Start aktiviert werden (erster Kampf oder Countdown 0), wird dieser Run dauerhaft als 'Mit World Buffs' markiert.",
    ["UI_WORLDBUFF_REMOVAL_INFO"] = "Hinweis: Bei Auswahl von 'Ohne World Buffs' werden alle aktuellen World Buffs von allen Gruppenmitgliedern entfernt.",
    ["WORLDBUFF_REMOVED_BY_LEADER"] = "World Buffs wurden vom Gruppenführer %s entfernt.",
    ["READY_CHECK_WITH_WB"] = "Dieser Run hat aktive World Buffs!",
    ["READY_CHECK_WITHOUT_WB"] = "Dieser Run ist OHNE aktive World Buffs",
    ["READY_CHECK_WB_REMOVED"] = "Alle aktuellen World Buffs wurden entfernt, da dieser Run ohne World Buffs ist.",
    ["UI_READY_CHECK_TITLE"] = "Ready Check",
    ["UI_READY_CHECK_QUESTION"] = "Bist du bereit für den Dungeon-Run?",
    ["UI_READY_CHECK_DUNGEON"] = "Dungeonrun für %s starten?",
    ["UI_COUNTDOWN_TITLE"] = "Run startet in...",
    ["UI_COUNTDOWN_GO"] = "LOS!",
    ["UI_NEW_DUNGEON_DETECTED"] = "Neuer Dungeon erkannt",
    ["UI_NEW_DUNGEON_MESSAGE"] = "Du betrittst %s.\\n\\nAktuellen Run resetten?",
    ["UI_EXPORT_TITLE"] = "Run-Daten exportieren",
    ["UI_EXPORT_DESCRIPTION"] = "Export-String wird auch im Chat ausgegeben zum einfachen Kopieren.",    
    ["UI_ABORT_RUN_TITLE"] = "Run abbrechen?",
    ["UI_ABORT_RUN_MESSAGE"] = "Möchten Sie den aktuellen Run abbrechen?",
    ["UI_ABORT_VOTE_MESSAGE"] = "%s möchte den Run abbrechen.",
    ["UI_ABORT_VOTE_QUESTION"] = "Stimmen Sie zu?",
    ["UI_ABORT_REQUEST_SENT"] = "Du hast eine Abbruch-Anfrage gestellt",
    ["UI_ABORT_BY_GROUP"] = "Run wurde abgebrochen (Gruppenbeschluss)",
    ["UI_ABORT_DECLINED"] = "Abbruch wurde abgelehnt",
    ["UI_ABORT_VOTE_STATUS"] = "Abbruch Vote: %d/%d (JA: %d)",
    ["UI_ABORT_BY_GROUP_SYNC"] = "Run wurde von der Gruppe abgebrochen",
    
    -- Debug Messages (keep in English for consistency)
    ["DEBUG_PREFIX"] = "[Debug]",
    ["DEBUG_SYNC_PREFIX"] = "[Debug Sync]",
    ["DEBUG_TRASH_PREFIX"] = "[TDT Trash Debug]",
    ["DEBUG_TIMER_ALREADY_RUNNING"] = "Timer läuft bereits!",
    ["DEBUG_COUNTDOWN_STARTED"] = "Countdown gestartet!",
    ["DEBUG_TIMER_STARTED_DIRECT"] = "Timer direkt gestartet!",
    ["DEBUG_NO_BOSSES_LOADED"] = "Keine Bosse geladen!",
    
    -- TrashScanner Messages
    ["TRASH_SCANNER_TARGET_PLAYER"] = "Target ist ein Spieler, übersprungen.",
    ["TRASH_SCANNER_NO_DUNGEON"] = "Kein Dungeon ausgewählt! Wähle zuerst einen Dungeon aus.",
    ["TRASH_SCANNER_COUNT_INCREASED"] = "Count erhöht: %s - HP: %d (Count: %d)",
    ["TRASH_SCANNER_SAVED"] = "Gespeichert: %s - HP: %d",
    ["TRASH_SCANNER_DELETED_COUNT"] = "%d Mobs für %s gelöscht.",
    ["TRASH_SCANNER_NO_DATA"] = "Keine Daten für %s vorhanden.",
    ["TRASH_SCANNER_ALL_DELETED"] = "ALLE Daten gelöscht! (%d Dungeons, %d Mobs)",
    ["TRASH_SCANNER_EXPORT_INFO"] = "Export für %d Dungeons mit %d Mobs",
    ["TRASH_SCANNER_DUNGEON_INFO"] = "%s: %d verschiedene Mobs, %d gesamt gezählt",
    ["TRASH_SCANNER_TOTAL_INFO"] = "Gesamt: %d Dungeons, %d verschiedene, %d gezählt",
    ["TRASH_SCANNER_DELETED_MOB"] = "Gelöscht: %s (HP: %d)",
    ["TRASH_SCANNER_DELETED_MOB_COUNT"] = "Gelöscht: %s (Count war 1)",
    
    -- TrashCounter Messages
    ["TRASH_COUNTER_DONE"] = "Trash erledigt! Noch %d Bosse übrig.",
    
    -- Timer Messages
    ["TIMER_RESET"] = "Timer wurde zurückgesetzt",
    
    -- Preparation Messages
    ["PREP_LEADER_ONLY_PREPARE"] = "Nur der Gruppenführer kann den Run vorbereiten!",
    ["PREP_NO_DUNGEON_SELECTED"] = "Kein Dungeon ausgewählt!",
    ["PREP_STARTING_FOR"] = "Starte Run-Vorbereitung für %s...",
    ["PREP_RESETTING_INSTANCE_MSG"] = "Setze Instanz zurück...",
    ["PREP_RESET_SKIPPED_LIMIT"] = "Reset übersprungen (5/Stunde Limit)",
    ["PREP_INSTANCE_RESET_SUCCESS"] = "Instanz wurde zurückgesetzt",
    ["PREP_RUN_READY_MSG"] = "Run bereit! Ihr könnt jetzt die Instanz betreten.",
    ["PREP_RESET_CURRENT_RUN"] = "Setze aktuellen Run zurück...",
    ["PREP_DUNGEON_CHANGED"] = "%s hat einen anderen Dungeon ausgewählt: %s (du hast: %s)",
    ["PREP_ADDON_CHECK"] = "Addon Check",
    ["PREP_MISSING"] = "(fehlt)",
    ["PREP_ALL_HAVE_ADDON"] = "Alle haben das Addon",
    ["PREP_NOT_ALL_HAVE_ADDON"] = "Nicht alle Gruppenmitglieder haben das Addon installiert!",
    ["PREP_VERSION_CHECK"] = "Version Check",
    ["PREP_EXPECTED_VERSION"] = "(erwartet: v%s)",
    ["PREP_ALL_SAME_VERSION"] = "Alle haben die gleiche Version",
    ["PREP_VERSION_MISMATCH"] = "Version mismatch! Nicht alle haben die gleiche Version.",
    ["PREP_STARTING_READY_CHECK"] = "Starte Ready Check...",
    ["PREP_LEADER_AUTO_READY"] = "Du (Leader) bist automatisch ready",
    ["PREP_ALL_RESPONDED"] = "Alle haben geantwortet!",
    ["PREP_READY_CHECK_RESULTS"] = "Ready Check Ergebnisse",
    ["PREP_NO_RESPONSE"] = "(Keine Antwort)",
    ["PREP_ALL_READY"] = "Alle sind ready!",
    ["PREP_FAILED"] = "Vorbereitung fehlgeschlagen:",
    ["PREP_NOT_ALL_READY"] = "Nicht alle sind ready! Bereite dich vor und versuche es erneut.",
    ["PREP_ENTERED_COUNTDOWN"] = "%s hat die Instanz betreten! Countdown startet in 10 Sekunden...",
    ["PREP_COUNTDOWN_CANCELLED"] = "Countdown abgebrochen - Timer gestartet!",
    ["PREP_RUN_STARTED"] = "Run gestartet! Viel Erfolg!",
    ["PREP_FAILED_REASON"] = "Vorbereitung fehlgeschlagen: %s",
}

-- ============================================================================
-- Translation Function
-- ============================================================================
-- Usage: TurtleDungeonTimer.L["KEY"] or TDT_L("KEY", arg1, arg2, ...)
setmetatable(L, {
    __index = function(t, key)
        local langTable = translations[currentLanguage]
        local fallbackTable = translations.enUS
        
        -- Try current language first
        if langTable and langTable[key] then
            return langTable[key]
        end
        
        -- Fallback to English
        if fallbackTable and fallbackTable[key] then
            return fallbackTable[key]
        end
        
        -- Return key itself if no translation found
        return key
    end
})

-- ============================================================================
-- Helper Function for Formatted Messages
-- ============================================================================
-- Returns the translated text without formatting
-- Usage: TDT_L("KEY") or string.format(TDT_L("KEY"), value1, value2, ...)
-- GLOBAL function for use in all addon files
function TDT_L(key)
    return TurtleDungeonTimer.L[key]
end

-- ============================================================================
-- Localized Chat Message Helper
-- ============================================================================
-- Prints a localized message with the addon prefix
-- Usage: TDT_Print("KEY", color, arg1, arg2, ...)
-- GLOBAL function for use in all addon files
function TDT_Print(key, color, ...)
    local prefix = "|cff00ff00[" .. TurtleDungeonTimer.L["ADDON_NAME"] .. "]|r "
    
    -- Format text with arguments if provided
    local text = TurtleDungeonTimer.L[key]
    if arg and table.getn(arg) > 0 then
        text = string.format(text, unpack(arg))
    end
    
    local r, g, b = 1, 1, 1
    if color == "error" then
        r, g, b = 1, 0, 0
    elseif color == "warning" then
        r, g, b = 1, 0.6, 0
    elseif color == "success" then
        r, g, b = 0, 1, 0
    elseif color == "info" then
        r, g, b = 0, 1, 1
    end
    
    DEFAULT_CHAT_FRAME:AddMessage(prefix .. text, r, g, b)
end

-- ============================================================================
-- Add New Languages Here
-- ============================================================================
--[[
-- French (Example)
translations.frFR = {
    ["ADDON_NAME"] = "Turtle Dungeon Timer",
    ["PREP_ONLY_LEADER"] = "Seul le chef de groupe peut préparer la course!",
    -- ... add more translations
}

-- Spanish (Example)
translations.esES = {
    ["ADDON_NAME"] = "Turtle Dungeon Timer",
    ["PREP_ONLY_LEADER"] = "¡Solo el líder del grupo puede preparar la carrera!",
    -- ... add more translations
}
]]--
