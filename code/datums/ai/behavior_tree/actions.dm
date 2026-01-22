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
			return NODE_SUCCESS
	else
		// Path is invalid, clear it
		user.set_ai_path_to(null)
		return NODE_FAILURE
	
	return NODE_RUNNING


// =============================================================================
// THINKING ACTIONS
// =============================================================================
/bt_action/check_think_valid/evaluate(mob/living/user, atom/target, list/blackboard)
	if(user.stat == DEAD || world.time < user.ai_root.next_think_tick)
		return NODE_FAILURE
	return NODE_SUCCESS
