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
// STUB ACTIONS - TO BE IMPLEMENTED FOR ROGUETOWN
// ==============================================================================
// The following are placeholders for common AI behaviors that you'll want to implement:
//
// Finding Targets:
// - /bt_action/find_target - Scan for enemies/targets within range
// - /bt_action/has_target - Check if we have a valid target
// - /bt_action/target_in_range - Check if target is in attack range
//
// Movement:
// - /bt_action/move_to_target - Move towards current target
// - /bt_action/move_random - Wander randomly
// - /bt_action/flee - Run away from target
//
// Combat:
// - /bt_action/attack_melee - Perform melee attack
// - /bt_action/attack_ranged - Perform ranged attack
//
// State Checks:
// - /bt_action/is_injured - Check if health is low
// - /bt_action/is_dead - Check if dead
//
// Example implementation:
/*
/bt_action/find_target/evaluate(mob/living/user, mob/living/target)
	if(!user || !user.ai_root)
		return NODE_FAILURE

	// Your target-finding logic here
	var/mob/living/new_target = null
	// ... search logic ...

	if(new_target)
		user.ai_root.target = new_target
		return NODE_SUCCESS
	return NODE_FAILURE
*/
