// ==============================================================================
// MOB AI VARIABLES
// ==============================================================================

/mob
	var/datum/behavior_tree/node/parallel/root/ai_root

/mob/living
	var/mob/living/target

// ==============================================================================
// AI HELPER PROCS FOR MOBS
// ==============================================================================

/mob/living/proc/GiveTarget(atom/target)
	if(!ai_root || stat == DEAD)
		return FALSE
	if(ismob(target))
		ai_root.target = target
	else if(isturf(target) || isobj(target))
		ai_root.obj_target = target
	else
		return FALSE

/mob/living/proc/LoseTarget()	
	ai_root?.target = null

/mob/living/proc/RunAI()
	if(!ai_root || stat == DEAD)
		return FALSE
		
	ai_root.evaluate(src, ai_root.target, ai_root.blackboard)
	return TRUE
	
/*
/mob/living/proc/RunMovement()
	if(!ai_root || stat == DEAD)
		return FALSE
	
	return (ai_root.move_node.evaluate(src, ai_root.target, ai_root.blackboard) == NODE_SUCCESS)
*/

/mob/living/proc/set_ai_path_to(atom/destination)
	if(!ai_root)
		return FALSE

	SSai.WakeUp(src) // Assume if we got this called on us, we want to actually do it.

	if(!destination)
		// Unclaim old destination
		if(ai_root.move_destination)
			SSai.unclaim_turf(get_turf(ai_root.move_destination), src)
		ai_root.path = null
		ai_root.move_destination = null
		return FALSE

	// Don't repath if we are already going there and have a path
	if(ai_root.move_destination == destination && length(ai_root.path))
		return TRUE

	if(ai_root.target && (ai_root.move_destination == ai_root.target || ai_root.move_destination == get_turf(ai_root.target)))
		if(get_dist(src, ai_root.target) <= 1)
			// Unclaim old destination
			if(ai_root.move_destination)
				SSai.unclaim_turf(get_turf(ai_root.move_destination), src)
			ai_root.path = null
			ai_root.move_destination = null
			return FALSE

	// Unclaim old destination before setting new one
	if(ai_root.move_destination)
		SSai.unclaim_turf(get_turf(ai_root.move_destination), src)

	// For a 1 step path, just set it directly for performance, or null the destination if it's a dense object we're next to.
	if(get_dist(src, destination) <= 1)
		var/turf/T = get_turf(destination)
		if(T && get_turf(src) != T)
			var/target = ai_root.target
			var/obj_target = ai_root.obj_target
			if(!target && !obj_target)
				var/has_dense_object = FALSE
				for(var/atom/A in T)
					if(A.density)
						has_dense_object = TRUE
						break

				if(!T.density && !has_dense_object && T.CanPass(src, T))
					ai_root.path = list(T)
					ai_root.move_destination = T
					SSai.claim_turf(T, src)
					return TRUE
			else
				if(target && Adjacent(ai_root.target) || obj_target && Adjacent(ai_root.obj_target))
					ai_root.path = null
					ai_root.move_destination = null
					return FALSE

		ai_root.path = null
		ai_root.move_destination = null
		return FALSE

	ai_root.path = A_Star(src, get_turf(src), get_turf(destination))
	ai_root.move_destination = destination

	// Claim the destination turf
	if(ai_root.move_destination)
		SSai.claim_turf(get_turf(ai_root.move_destination), src)

	return (length(ai_root.path) > 0)


/mob/living/proc/add_aggressor(mob/living/aggressor)
	if(!aggressor)
		return

	if(!ai_root.blackboard[AIBLK_AGGRESSORS])
		ai_root.blackboard[AIBLK_AGGRESSORS] = list()
	ai_root.blackboard[AIBLK_AGGRESSORS] |= aggressor

	// Store last known location
	ai_root.blackboard[AIBLK_LAST_KNOWN_TARGET_LOC] = get_turf(aggressor)

// Check if mob can switch to a new target (respects delay to prevent thrashing)
/mob/living/proc/can_switch_target(atom/new_target, switch_delay = 2 SECONDS)
	if(!ai_root) return FALSE

	// If we have no current target, we can always switch
	if(!ai_root.target) return TRUE

	// If new target is same as current, no switch needed (return TRUE to allow reassignment)
	if(ai_root.target == new_target) return TRUE

	// Check last target switch time in blackboard
	var/last_switch = ai_root.blackboard[AIBLK_LAST_TARGET_SWITCH_TIME]
	if(!last_switch) return TRUE

	return (world.time - last_switch) >= switch_delay

// Record a target switch to enforce delay
/mob/living/proc/record_target_switch()
	if(ai_root)
		ai_root.blackboard[AIBLK_LAST_TARGET_SWITCH_TIME] = world.time
