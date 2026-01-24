// ==============================================================================
// BEHAVIOR TREE ACTIONS
// ==============================================================================
// This file contains the base bt_action class and generic action implementations.
// IS12-specific actions have been removed. Implement roguetown-specific actions here as needed.

//================================================================
// BASE ACTION DATUM
//================================================================
// All specific actions (like attacking, finding targets, etc.) inherit from this.
/bt_action
	parent_type = /datum

/bt_action/proc/evaluate(mob/living/user, atom/target, list/blackboard)
	return NODE_FAILURE

// Helper to simulate ClickOn with less overhead for AI
/proc/npc_click_on(mob/living/user, atom/target, params)
	if(!user || !user.ai_root || !target)
		return

	if(world.time <= user.next_click)
		return
	user.next_click = world.time + 1

	if(user.next_move > world.time)
		return

	if(user.incapacitated(ignore_restraints = 1))
		return
	
	if(user.restrained())
		user.changeNext_move(CLICK_CD_HANDCUFFED)
		return

	if(!user.atkswinging)
		user.face_atom(target)

	if(!user.Adjacent(target))
		return

	var/obj/item/W = user.get_active_held_item()
	
	// Simulate cooldowns based on intent
	if(W)
		var/adf = user.used_intent.clickcd
		if(istype(user.rmb_intent, /datum/rmb_intent/aimed))
			adf = round(adf * CLICK_CD_MOD_AIMED)
		else if(istype(user.rmb_intent, /datum/rmb_intent/swift))
			adf = max(round(adf * CLICK_CD_MOD_SWIFT), CLICK_CD_INTENTCAP)
		user.changeNext_move(adf)

	// Attack animation
	if(W && ismob(target))
		if(!user.used_intent.noaa)
			user.do_attack_animation(get_turf(target), user.used_intent.animname, W, used_intent = user.used_intent)

	user.resolveAdjacentClick(target, W, params)

// ==============================================================================
// MOVEMENT ACTIONS
// ==============================================================================

/bt_action/check_move_valid/evaluate(mob/living/user, atom/target, list/blackboard)
	if(user.stat == DEAD || user.doing || world.time < user.ai_root.next_move_tick)
		return NODE_FAILURE
	return NODE_SUCCESS

/bt_action/check_has_path/evaluate(mob/living/user, atom/target, list/blackboard)
	if(!user.ai_root || !user.ai_root.path || !length(user.ai_root.path))
		return NODE_FAILURE
	return NODE_SUCCESS

/bt_action/process_movement/evaluate(mob/living/user, atom/target, list/blackboard)
	var/turf/next_step = user.ai_root.path[1]
	if(get_turf(user) == next_step)
		user.ai_root.path.Cut(1, 2)
		if(!length(user.ai_root.path))
			user.set_ai_path_to(null)
			return NODE_SUCCESS
		next_step = user.ai_root.path[1]

	if(next_step && get_dist(user, next_step) <= 1)
		if(user.Move(next_step, get_dir(user, next_step)))
			user.ai_root.next_move_tick = world.time + user.ai_root.next_move_delay
			blackboard -= AIBLK_PATH_BLOCKED_COUNT
			return NODE_SUCCESS
		else
			// Movement failed - count failures and abandon if stuck
			var/blocked_count = blackboard[AIBLK_PATH_BLOCKED_COUNT] || 0
			blocked_count++
			blackboard[AIBLK_PATH_BLOCKED_COUNT] = blocked_count

			if(blocked_count >= 5)
				// Stuck for too long, clear path to force repath or abandon
				user.set_ai_path_to(null)
				blackboard -= AIBLK_PATH_BLOCKED_COUNT
				return NODE_FAILURE

			return NODE_RUNNING
	else
		// Path is invalid, clear it
		user.set_ai_path_to(null)
		blackboard -= AIBLK_PATH_BLOCKED_COUNT
		return NODE_FAILURE


// =============================================================================
// THINKING ACTIONS
// =============================================================================
/bt_action/check_think_valid/evaluate(mob/living/user, atom/target, list/blackboard)
	if(user.stat == DEAD || world.time < user.ai_root.next_think_tick)
		return NODE_FAILURE
	return NODE_SUCCESS
