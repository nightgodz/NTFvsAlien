/*!
 * Copyright (c) 2020 Aleksej Komarov
 * SPDX-License-Identifier: MIT
 */

/// How many chat payloads to keep in history
#define CHAT_RELIABILITY_HISTORY_SIZE 5
/// How many resends to allow before giving up
#define CHAT_RELIABILITY_MAX_RESENDS 3

#define MESSAGE_TYPE_SYSTEM "system"
#define MESSAGE_TYPE_LOCALCHAT "localchat"
#define MESSAGE_TYPE_RADIO "radio"
#define MESSAGE_TYPE_INFO "info"
#define MESSAGE_TYPE_WARNING "warning"
#define MESSAGE_TYPE_DEADCHAT "deadchat"
#define MESSAGE_TYPE_OOC "ooc"
#define MESSAGE_TYPE_LOOC "looc"
#define MESSAGE_TYPE_ADMINPM "adminpm"
#define MESSAGE_TYPE_COMBAT "combat"
#define MESSAGE_TYPE_ADMINCHAT "adminchat"
#define MESSAGE_TYPE_MENTORCHAT "mentorchat"
#define MESSAGE_TYPE_PRAYER "prayer"
#define MESSAGE_TYPE_ADMINLOG "adminlog"
#define MESSAGE_TYPE_STAFFLOG "stafflog"
#define MESSAGE_TYPE_ATTACKLOG "attacklog"
#define MESSAGE_TYPE_DEBUG "debug"

//debug printing macros (for development and testing)
/// Used for debug messages to the world
#define debug_world(msg) if (GLOB.Debug2) to_chat(world, \
	type = MESSAGE_TYPE_DEBUG, \
	text = "DEBUG: [msg]")
/// Used for debug messages to the player
#define debug_usr(msg) if (GLOB.Debug2&&usr) to_chat(usr, \
	type = MESSAGE_TYPE_DEBUG, \
	text = "DEBUG: [msg]")
/// Used for debug messages to the admins
#define debug_admins(msg) if (GLOB.Debug2) to_chat(GLOB.admins, \
	type = MESSAGE_TYPE_DEBUG, \
	text = "DEBUG: [msg]")
/// Used for debug messages to the server
#define debug_world_log(msg) if (GLOB.Debug2) log_world("DEBUG: [msg]")
/// Adds a generic box around whatever message you're sending in chat. Really makes things stand out.
#define examine_block(str) ("<div class='examine_block'>" + str + "</div>")
/// Makes a fieldset with a name in the middle top part. Can apply additional classes
#define fieldset_block(title, content, classes) ("<fieldset class='" + classes + "'><legend align='center' style='max-width: 95%; text-align: center;'><div style='margin: 0em 0.2em -0.4em 0.2em;' >" + title + "</div></legend>" + content + "</fieldset>")
/// Makes a horizontal line with text in the middle
#define separator_hr(str) ("<div class='separator'>" + str + "</div>")
/// Header for use in examine blocks
#define examine_header(str) ("<span class='blockheader'>" + str + "</span>")
/// A horizontal line for use in examine blocks
#define EXAMINE_SECTION_BREAK "<hr>"
