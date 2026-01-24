/ai_squad/goblin/RunAI()
	..() // Call parent to share aggressors and apply tactics

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

	// 2. Filter targets based on priority (Bait > Armed > Others)
	if(!length(potential_targets))
		// No targets, clear priority target
		blackboard -= AIBLK_SQUAD_PRIORITY_TARGET
		return

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

	// 3. Select the priority target (focus fire on highest priority)
	var/mob/living/priority_target = null
	if(length(bait_targets))
		priority_target = pick(bait_targets)
	else if(length(armed_targets))
		priority_target = pick(armed_targets)
	else if(length(other_targets))
		priority_target = pick(other_targets)

	if(!priority_target)
		blackboard -= AIBLK_SQUAD_PRIORITY_TARGET
		return

	// Store in squad blackboard
	blackboard[AIBLK_SQUAD_PRIORITY_TARGET] = priority_target

	// 4. Assign tactical roles for coordinated attack
	assign_tactical_roles(priority_target)

	// Update center of mass for "surround" logic
	update_center_of_mass()
