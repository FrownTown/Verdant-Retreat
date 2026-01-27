// ==============================================================================
// ADDITIONAL OBSERVERS
// ==============================================================================

// TARGET LOST OBSERVER
// Triggered when target changes to null or is lost
/datum/behavior_tree/node/decorator/observer/target_lost
	observed_signal = COMSIG_AI_TARGET_CHANGED

/datum/behavior_tree/node/decorator/observer/target_lost/on_signal(datum/source, atom/new_target)
	if(!new_target)
		triggered = TRUE
		if(istype(source, /mob/living))
			var/mob/living/L = source
			if(L.ai_root) L.ai_root.running_node = null

// SELF PRESERVATION OBSERVER
// Triggered when health is low
/datum/behavior_tree/node/decorator/observer/self_preservation
	observed_signal = COMSIG_AI_LOW_HEALTH

// SQUAD UPDATE OBSERVER
// Triggered when squad state changes
/datum/behavior_tree/node/decorator/observer/squad_update
	observed_signal = COMSIG_AI_SQUAD_CHANGED


// ==============================================================================
// ADDITIONAL SERVICES
// ==============================================================================

// HEALTH MONITOR SERVICE
// Checks health and fires COMSIG_AI_LOW_HEALTH if critically low
/datum/behavior_tree/node/decorator/service/health_monitor
	interval = 1 SECOND
	var/threshold = 0.3 // 30% health

/datum/behavior_tree/node/decorator/service/health_monitor/service_tick(mob/living/npc, list/blackboard)
	if(npc.health < npc.maxHealth * threshold)
		// Avoid spamming if already fleeing/handling it?
		// For now, just fire signal. Observer handles debounce/state check if needed.
		SEND_SIGNAL(npc, COMSIG_AI_LOW_HEALTH, npc.health)

// SQUAD MONITOR SERVICE
// Updates squad blackboard data and fires SQUAD_CHANGED if needed
/datum/behavior_tree/node/decorator/service/squad_monitor
	interval = 2 SECONDS

/datum/behavior_tree/node/decorator/service/squad_monitor/service_tick(mob/living/npc, list/blackboard)
	var/ai_squad/squad = blackboard[AIBLK_SQUAD_DATUM]
	
	// Check if we lost our squad
	if(squad && !(npc in squad.members))
		blackboard[AIBLK_SQUAD_DATUM] = null
		SEND_SIGNAL(npc, COMSIG_AI_SQUAD_CHANGED)
		return

	// If we are in a squad, check if role changed (handled by squad controller usually, but we can verify)
	// For now, just ensure blackboard matches reality
	if(squad)
		// Update mates list
		var/list/mates = squad.members - npc
		blackboard[AIBLK_SQUAD_MATES] = mates
		blackboard[AIBLK_SQUAD_SIZE] = length(squad.members)