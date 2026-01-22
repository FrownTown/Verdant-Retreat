// ==============================================================================
// GOBLIN BEHAVIOR TREE ACTIONS
// ==============================================================================

// ------------------------------------------------------------------------------
// SQUAD COORDINATION
// ------------------------------------------------------------------------------

/bt_action/goblin_squad_coordination
	var/key = AIBLK_SQUAD_DATUM

/bt_action/goblin_squad_coordination/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(!user.ai_root) return NODE_FAILURE
	
	// If we have a squad priority target assigned (by RunAI), use it.
	var/mob/living/squad_target = blackboard[AIBLK_SQUAD_PRIORITY_TARGET]
	
	// Check if this target is ignored
	var/list/ignored = user.ai_root.blackboard["ignored_targets"]
	if(ignored && squad_target && ignored[squad_target])
		// Target is ignored, do not accept assignment
		return NODE_SUCCESS

	if(squad_target)
		// If we don't have a target, or our current target is different (and we are not busy with a bait target), switch.
		// Note: If we are already engaging a bait target (AIBLK_MONSTER_BAIT), we might want to stick to it?
		// For now, squad priority overrides unless we are deep in a sequence.
		if(user.ai_root.target != squad_target)
			user.ai_root.target = squad_target
			// Also check if this target is bait, set the key if so
			if(HAS_TRAIT(squad_target, TRAIT_MONSTERBAIT))
				user.ai_root.blackboard[AIBLK_MONSTER_BAIT] = squad_target
	
	return NODE_SUCCESS

// ------------------------------------------------------------------------------
// SUBDUE / DRAG LOGIC
// ------------------------------------------------------------------------------

/bt_action/goblin_drag_away
	var/min_drag_dist = 7
	var/blackboard_key = "drag_start_loc"

/bt_action/goblin_drag_away/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	var/mob/living/carbon/victim = user.ai_root.blackboard[AIBLK_MONSTER_BAIT]
	
	if(!victim || victim.stat == DEAD)
		user.ai_root.blackboard.Remove(blackboard_key)
		user.set_ai_path_to(null)
		return NODE_FAILURE

	// Check if we are grabbing the victim (check BOTH hands)
	var/obj/item/grabbing/G = user.get_active_held_item()
	if(!istype(G) || G.grabbed != victim)
		G = user.get_inactive_held_item()
		if(!istype(G) || G.grabbed != victim)
			G = null
	
	if(!G)
		// We lost the grab! Try to re-grab.
		if(get_dist(user, victim) > 1)
			if(user.set_ai_path_to(victim))
				return NODE_RUNNING
			return NODE_FAILURE // Cannot reach victim to re-grab
		
		// Adjacent, try to grab
		// Ensure we have a free hand
		if(user.get_active_held_item() && user.get_inactive_held_item())
			var/obj/item/I = user.get_active_held_item()
			if(istype(I, /obj/item/rope)) // Don't drop cuffs
				user.swap_hand()
				I = user.get_active_held_item()
			if(I)
				if(!user.place_in_inventory(I))
					user.dropItemToGround(I)
			
		user.rog_intent_change(3)
		
		if(user.doing) return NODE_RUNNING
		user.ClickOn(victim)
		return NODE_RUNNING

	// We have the grab G. Proceed with dragging.
	
	// Determine where we started
	var/turf/start_loc = user.ai_root.blackboard[blackboard_key]
	if(!start_loc)
		start_loc = get_turf(user)
		user.ai_root.blackboard[blackboard_key] = start_loc

	// Check if we are done
	if(get_dist(user, start_loc) >= min_drag_dist)
		// Success!
		user.set_ai_path_to(null)
		return NODE_SUCCESS

	// Logic to define move_destination
	var/atom/move_target = user.ai_root.move_destination
	
	// Validate current move target
	if(move_target && (user.ai_root.target != move_target || user.ai_root.target != get_turf(move_target)))
		if(get_dist(user, move_target) <= 0 || get_turf(user) == move_target)
			move_target = null // Reached
		else if(is_blocked_turf(move_target))
			move_target = null // Blocked
	
	// If no valid move target, find one
	else
		// Check for nearby threats
		var/list/threats = list()
		var/list/nearby = get_nearby_entities(user, 7)
		for(var/mob/living/L in nearby)
			if(L == user || L == victim) continue
			if(L.stat == DEAD) continue
			if(isgoblinp(L)) continue
			threats += L
		
		if(length(threats))
			// Flee away from threats
			var/avg_x = 0
			var/avg_y = 0
			for(var/mob/living/T in threats)
				avg_x += T.x
				avg_y += T.y
			
			var/turf/center = locate(avg_x / length(threats), avg_y / length(threats), user.z)
			var/flee_dir = get_dir(center, user)
			move_target = get_ranged_target_turf(user, flee_dir, 3)
		else
			if(!move_target) // No threats. Pick random direction
				var/list/dirs = shuffle(GLOB.alldirs.Copy())
				for(var/d in dirs)
					var/turf/T = get_ranged_target_turf(user, d, 10)
					if(T && !is_blocked_turf(T))
						move_target = T
						break
			
			if(move_target)
				if(user.set_ai_path_to(move_target))
					return NODE_RUNNING
				else
					user.set_ai_path_to(null)
					return NODE_RUNNING
			else
				// We have a target, ensure we are moving to it
				if(!user.ai_root.path || !length(user.ai_root.path))
					if(user.set_ai_path_to(move_target))
						return NODE_RUNNING
					else
						user.set_ai_path_to(null)
						return NODE_RUNNING
	
		return NODE_RUNNING
		
// ------------------------------------------------------------------------------
// POST VIOLATE
// ------------------------------------------------------------------------------

/bt_action/goblin_post_violate

/bt_action/goblin_post_violate/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	// 1. Re-equip weapon/armor from floor
	for(var/obj/item/I in get_turf(user))
		user.place_in_inventory(I)

	// 2. Handle victim
	var/mob/living/victim = user.ai_root.blackboard[AIBLK_MONSTER_BAIT]
	if(victim)
		// Clear bait status
		user.ai_root.blackboard.Remove(AIBLK_MONSTER_BAIT)
		user.ai_root.blackboard.Remove(AIBLK_SQUAD_PRIORITY_TARGET)
		user.ai_root.blackboard.Remove("drag_start_loc")
		
		// Add to ignore list
		var/list/ignored = user.ai_root.blackboard["ignored_targets"] ? user.ai_root.blackboard["ignored_targets"] : list()

		ignored[victim] = world.time
		user.ai_root.blackboard["ignored_targets"] = ignored
		
		// Stop targeting
		if(user.ai_root.target == victim)
			user.ai_root.target = null
			user.back_to_idle()
	
	return NODE_SUCCESS

// ------------------------------------------------------------------------------
// DISARM / STRIP LOGIC
// ------------------------------------------------------------------------------

/bt_action/goblin_disarm

/bt_action/goblin_disarm/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	// Target MUST be monster bait
	var/mob/living/carbon/victim = user.ai_root.blackboard[AIBLK_MONSTER_BAIT]
	if(!victim) return NODE_FAILURE
	
	// Target MUST be incapacitated
	if(!victim.IsKnockdown() && !victim.IsUnconscious() && !victim.IsSleeping() && !victim.restrained())
		return NODE_FAILURE
		
	// Check for weapons to strip
	// Prioritize hands -> Belt -> Back -> Armor
	var/obj/item/to_strip = null
	
	// Hands
	to_strip = victim.get_active_held_item()
	if(!to_strip) to_strip = victim.get_inactive_held_item()
	
	// Belt
	if(!to_strip) to_strip = victim.get_item_by_slot(SLOT_BELT)
	
	// Back
	if(!to_strip) to_strip = victim.get_item_by_slot(SLOT_BACK)
	
	if(to_strip)
		// Only strip if it's a weapon (arbitrary check: force > 0)
		if(to_strip.force > 0 || istype(to_strip, /obj/item/gun) || istype(to_strip, /obj/item/rogueweapon))
			
			// If we are too far, move in
			if(get_dist(user, victim) > 1)
				if(user.set_ai_path_to(victim))
					return NODE_RUNNING
				return NODE_FAILURE
				
			// Strip it
			if(user.doing) return NODE_RUNNING
			
			user.visible_message(span_danger("[user] tries to rip [to_strip] off of [victim]!"))
			if(do_mob(user, victim, 20))
				if(to_strip && to_strip.loc == victim) // Verify still there
					if(!victim.dropItemToGround(to_strip))
						victim.unequip_everything() // aggressive!
						// Maybe too aggressive.
					else
						to_strip.throw_at(get_ranged_target_turf(user, pick(GLOB.alldirs), 5), 5, 1)
					return NODE_RUNNING
			return NODE_RUNNING
			
	return NODE_SUCCESS // No weapons found, move on
