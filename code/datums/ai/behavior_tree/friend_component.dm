/// Component that handles "friend" logic for AI mobs:
/// - Befriending/Unfriending
/// - Receiving commands (Say/Radial)
/// - Updating AI Blackboard based on commands
/datum/component/ai_friend_events
	var/datum/weakref/friend_ref
	var/command_cooldown_time = 2 SECONDS
	var/attack_word = "growls"

	COOLDOWN_DECLARE(command_cooldown)

/datum/component/ai_friend_events/Initialize()
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examined))
	RegisterSignal(parent, COMSIG_CLICK_ALT, PROC_REF(check_altclicked))
	RegisterSignal(parent, COMSIG_RIDDEN_DRIVER_MOVE, PROC_REF(on_ridden_driver_move))
	RegisterSignal(parent, COMSIG_MOVABLE_PREBUCKLE, PROC_REF(on_prebuckle))

/datum/component/ai_friend_events/proc/befriend(mob/living/new_friend)
	var/mob/living/old_friend = friend_ref?.resolve()
	if(old_friend)
		unfriend()
	
	friend_ref = WEAKREF(new_friend)
	
	// Update Blackboard
	var/mob/living/L = parent
	if(L.ai_root)
		L.ai_root.blackboard[AIBLK_FRIEND_REF] = friend_ref
		L.ai_root.blackboard[AIBLK_TAMED] = TRUE

	RegisterSignal(new_friend, COMSIG_MOB_SAY, PROC_REF(check_verbal_command))
	
	if(parent.Adjacent(new_friend))
		new_friend.visible_message("<b>[parent]</b> looks at [new_friend] in a friendly manner!", span_notice("[parent] looks at you in a friendly manner!"))

/datum/component/ai_friend_events/proc/unfriend()
	var/mob/living/old_friend = friend_ref?.resolve()
	if(old_friend)
		UnregisterSignal(old_friend, COMSIG_MOB_SAY)
	
	friend_ref = null
	
	// Update Blackboard
	var/mob/living/L = parent
	if(L.ai_root)
		L.ai_root.blackboard[AIBLK_FRIEND_REF] = null
		L.ai_root.blackboard[AIBLK_TAMED] = FALSE
		L.ai_root.blackboard[AIBLK_COMMAND_MODE] = "none" // Reset command

/datum/component/ai_friend_events/proc/on_prebuckle(mob/source, mob/living/buckler, force)
	var/mob/living/L = parent
	if(force || !L.ai_root)
		return
	
	if(WEAKREF(buckler) != friend_ref)
		return COMPONENT_BLOCK_BUCKLE

/datum/component/ai_friend_events/proc/on_ridden_driver_move(atom/movable/movable_parent, mob/living/user, direction)
	// Pause AI for a moment when ridden to prevent fighting control
	var/mob/living/L = parent
	if(L.ai_root)
		L.ai_root.next_think_tick = world.time + 1 SECONDS

/datum/component/ai_friend_events/proc/on_examined(datum/source, mob/user, list/examine_text)
	if(WEAKREF(user) == friend_ref)
		var/mob/living/L = parent
		if(L.stat == CONSCIOUS)
			examine_text += span_notice("[L.p_they(TRUE)] seem[L.p_s()] happy to see you!")

/datum/component/ai_friend_events/proc/check_altclicked(datum/source, mob/living/clicker)
	if(!COOLDOWN_FINISHED(src, command_cooldown))
		return
	
	if(!istype(clicker) || WEAKREF(clicker) != friend_ref)
		return
	
	INVOKE_ASYNC(src, PROC_REF(command_radial), clicker)

/datum/component/ai_friend_events/proc/command_radial(mob/living/clicker)
	var/list/commands = list(
		"stop" = image(icon = 'icons/testing/turf_analysis.dmi', icon_state = "red_arrow"),
		"follow" = image(icon = 'icons/mob/actions/actions_spells.dmi', icon_state = "summons"),
		"attack" = image(icon = 'icons/effects/effects.dmi', icon_state = "bite"),
	)

	var/choice = show_radial_menu(clicker, parent, commands, custom_check = CALLBACK(src, PROC_REF(check_menu), clicker), tooltips = TRUE)
	if(!choice || !check_menu(clicker))
		return
	
	set_command_mode(clicker, choice)

/datum/component/ai_friend_events/proc/check_menu(mob/user)
	if(!istype(user)) return FALSE
	if(user.incapacitated() || !can_see(user, parent))
		return FALSE
	return TRUE

/datum/component/ai_friend_events/proc/check_verbal_command(mob/speaker, speech_args)
	if(WEAKREF(speaker) != friend_ref)
		return

	if(!COOLDOWN_FINISHED(src, command_cooldown))
		return

	var/mob/living/L = parent
	if(L.stat != CONSCIOUS)
		return

	var/spoken_text = speech_args[SPEECH_MESSAGE]
	var/command
	if(findtext(spoken_text, "stop") || findtext(spoken_text, "stay"))
		command = "stop"
	else if(findtext(spoken_text, "follow") || findtext(spoken_text, "come"))
		command = "follow"
	else if(findtext(spoken_text, "attack") || findtext(spoken_text, "sic"))
		command = "attack"
	else
		return

	if(!can_see(parent, speaker))
		return
	
	set_command_mode(speaker, command)

/datum/component/ai_friend_events/proc/set_command_mode(mob/commander, command)
	COOLDOWN_START(src, command_cooldown, 2 SECONDS)
	var/mob/living/L = parent
	if(!L.ai_root) return

	switch(command)
		if("stop")
			L.visible_message(span_notice("[L] [attack_word] at [commander]'s command, and [L.p_they()] stop[L.p_s()] obediently, awaiting further orders."))
			L.ai_root.blackboard[AIBLK_COMMAND_MODE] = "stop"
			L.ai_root.target = null
			L.ai_root.path = null
			L.ai_root.move_destination = null
			
		if("follow")
			L.visible_message(span_notice("[L] [attack_word] at [commander]'s command, and [L.p_they()] follow[L.p_s()] slightly in anticipation."))
			L.ai_root.blackboard[AIBLK_COMMAND_MODE] = "follow"
			L.ai_root.blackboard[AIBLK_MINION_FOLLOW_TARGET] = commander
			if(L.buckled)
				L.resist()

		if("attack")
			L.visible_message(span_danger("[L] [attack_word] at [commander]'s command, and [L.p_they()] growl[L.p_s()] intensely."))
			L.ai_root.blackboard[AIBLK_COMMAND_MODE] = "attack"
			// The tree should handle acquiring a target, or we could set it here if the commander points?
			// For now, "attack" mode just enables the combat subtree to be very aggressive.

