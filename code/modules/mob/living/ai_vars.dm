// ==============================================================================
// MOB AI VARIABLES AND PROCS
// ==============================================================================

/mob
	var/datum/behavior_tree/node/parallel/root/ai_root

/mob/living
	var/mob/living/target

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
		ai_root.path = null
		ai_root.move_destination = null
		return FALSE

	// Don't repath if we are already going there and have a path
	if(ai_root.move_destination == destination && length(ai_root.path))
		return TRUE

	if(ai_root.target && (ai_root.move_destination == ai_root.target || ai_root.move_destination == get_turf(ai_root.target)))
		if(get_dist(src, ai_root.target) <= 1)
			ai_root.path = null
			ai_root.move_destination = null
			return FALSE
	
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
	
	return (length(ai_root.path) > 0)
