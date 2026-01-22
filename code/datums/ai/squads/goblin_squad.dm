/ai_squad/goblin
	max_size = 6

/ai_squad/goblin/RunAI()
	// 1. Identify valid targets in range of the squad
	var/list/potential_targets = list()
	var/list/active_members = list()

	// Gather all members and what they see
	for(var/mob/living/M in members)
		if(M.stat != CONSCIOUS) continue
		active_members += M
		
		// Use the member's sensor range
		var/list/seen = get_nearby_entities(M, 7)
		for(var/mob/living/L in seen)
			if(L.stat == DEAD) continue
			if(isgoblinp(L)) continue // Ignore fellow goblins
			if(L in members) continue
			
			// Add to potential targets
			potential_targets |= L

	// 2. Assign targets to members (Spread Out Logic)
	if(!length(potential_targets))
		// No targets, clear assignments
		for(var/mob/living/M in active_members)
			if(M.ai_root)
				M.ai_root.blackboard.Remove(AIBLK_SQUAD_PRIORITY_TARGET)
	else
		// Filter targets based on priority (Bait > Armed > Others)
		var/list/bait_targets = list()
		var/list/armed_targets = list()
		var/list/other_targets = list()
		
		for(var/mob/living/T in potential_targets)
			if(HAS_TRAIT(T, TRAIT_MONSTERBAIT))
				bait_targets += T
			else if(T.get_active_held_item())
				var/obj/item/I = T.get_active_held_item()
				if(I.force > 5 || I.get_sharpness())
					armed_targets += T
				else
					other_targets += T
			else
				other_targets += T
		
		// Determine the pool to draw from based on highest priority available
		var/list/target_pool = list()
		if(length(bait_targets))
			target_pool = bait_targets
		else if(length(armed_targets))
			target_pool = armed_targets
		else
			target_pool = other_targets
			
		// Round-robin assignment
		var/target_idx = 1
		for(var/mob/living/M in active_members)
			if(!M.ai_root) continue
			
			var/mob/living/assigned = target_pool[target_idx]
			M.ai_root.blackboard[AIBLK_SQUAD_PRIORITY_TARGET] = assigned
			
			target_idx++
			if(target_idx > length(target_pool))
				target_idx = 1

	// Update center of mass for "surround" logic
	update_center_of_mass()
