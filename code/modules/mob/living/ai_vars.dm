// ==============================================================================
// MOB AI VARIABLES AND PROCS
// ==============================================================================

/mob
	var/datum/behavior_tree/node/ai_root

/mob/living/proc/RunAI()
	if(!ai_root || stat == DEAD)
		return FALSE
	ai_root.evaluate(src, ai_root.target, ai_root.blackboard)
	return TRUE

/mob/living/proc/RunMovement()
	if(!ai_root || stat == DEAD)
		return FALSE
	if(world.time < ai_root.next_move_tick)
		return FALSE
	if(!ai_root.path || !length(ai_root.path))
		return FALSE

	var/turf/next_step = ai_root.path[1]
	if(get_turf(src) == next_step)
		ai_root.path.Cut(1, 2)
		if(!length(ai_root.path))
			ai_root.move_destination = null
			return FALSE
		next_step = ai_root.path[1]

	if(next_step && get_dist(src, next_step) <= 1)
		Move(next_step, get_dir(src, next_step))
		ai_root.next_move_tick = world.time + ai_root.next_move_delay
		return TRUE
	else
		// Path is invalid, clear it
		set_ai_path_to(null)
		return FALSE

/mob/living/proc/set_ai_path_to(atom/destination)
	if(!ai_root)
		return FALSE
	
	if(!destination)
		ai_root.path = null
		ai_root.move_destination = null
		return FALSE

	// Don't repath if we are already going there and have a path
	if(ai_root.move_destination == destination && length(ai_root.path))
		return TRUE
	
	ai_root.path = A_Star(src, get_turf(src), get_turf(destination))
	ai_root.move_destination = destination
	
	return (length(ai_root.path) > 0)
