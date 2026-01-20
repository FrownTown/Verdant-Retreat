// ==============================================================================
// CARBON/HUMAN BEHAVIOR TREE ACTIONS
// ==============================================================================

// ------------------------------------------------------------------------------
// CARBON TARGETING
// ------------------------------------------------------------------------------

/bt_action/carbon_find_target
	var/search_range = 7

/bt_action/carbon_find_target/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(!ishuman(user))
		return NODE_FAILURE

	// Check if current target is still valid
	if(target && user.should_target(target) && get_dist(user, target) <= search_range)
		return NODE_SUCCESS

	// Find new target
	var/mob/living/new_target = null
	var/closest_dist = search_range + 1

	for(var/mob/living/L in view(search_range, user))
		if(!user.should_target(L))
			continue

		var/dist = get_dist(user, L)
		if(dist < closest_dist)
			new_target = L
			closest_dist = dist

	if(new_target)
		if(user.ai_root)
			user.ai_root.target = new_target
		user.retaliate(new_target) // Trigger aggro
		return NODE_SUCCESS

	return NODE_FAILURE

/bt_action/carbon_has_target/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(!ishuman(user))
		return NODE_FAILURE

	if(target && user.should_target(target) && get_dist(user, target) <= 15)
		return NODE_SUCCESS

	if(user.ai_root)
		user.ai_root.target = null
		user.back_to_idle()
	return NODE_FAILURE

/bt_action/carbon_target_in_range
	var/range = 1

/bt_action/carbon_target_in_range/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(!ishuman(user) || !target)
		return NODE_FAILURE

	if(user.Adjacent(target))
		return NODE_SUCCESS

	return NODE_FAILURE

// ------------------------------------------------------------------------------
// CARBON MOVEMENT
// ------------------------------------------------------------------------------

/bt_action/carbon_move_to_target/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(!ishuman(user) || !target)
		return NODE_FAILURE

	// If adjacent, no need to move
	if(user.Adjacent(target))
		return NODE_SUCCESS

	// Use the helper to set the path
	if(user.set_ai_path_to(target))
		return NODE_RUNNING

	return NODE_FAILURE

/bt_action/carbon_idle_wander/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(!ishuman(user))
		return NODE_FAILURE

	// Simple random wander: pick a nearby tile and path to it
	if(user.ai_root && (!user.ai_root.path || !length(user.ai_root.path)))
		var/turf/T = get_ranged_target_turf(user, pick(GLOB.cardinals), 3)
		if(T && user.set_ai_path_to(T))
			return NODE_RUNNING

	return NODE_RUNNING

// ------------------------------------------------------------------------------
// CARBON COMBAT
// ------------------------------------------------------------------------------

/bt_action/carbon_attack_melee/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(!ishuman(user) || !target)
		return NODE_FAILURE

	if(!user.Adjacent(target))
		return NODE_FAILURE

	if(user.ai_root && world.time >= user.ai_root.next_attack_tick)
		user.face_atom(target)
		user.monkey_attack(target)
		user.ai_root.next_attack_tick = world.time + (user.ai_root.next_attack_delay || 10)
		return NODE_SUCCESS

	return NODE_RUNNING

/bt_action/carbon_equip_weapon/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(!ishuman(user))
		return NODE_FAILURE

	// Already has a weapon
	if(user.get_active_held_item())
		return NODE_SUCCESS

	// Try to find and equip a weapon
	if(HAS_TRAIT(user, TRAIT_CHUNKYFINGERS) || !(user.mobility_flags & MOBILITY_PICKUP))
		return NODE_FAILURE

	for(var/obj/item/I in view(1, user))
		if(!isturf(I.loc))
			continue
		if(user.blacklistItems[I])
			continue
		if(I.force > 7 && user.equip_item(I))
			return NODE_SUCCESS

	return NODE_FAILURE

// ------------------------------------------------------------------------------
// CARBON FLEE
// ------------------------------------------------------------------------------

/bt_action/carbon_should_flee/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(!ishuman(user) || !target)
		return NODE_FAILURE

	if(!user.flee_in_pain || target.stat != CONSCIOUS)
		return NODE_FAILURE

	var/paine = user.get_complex_pain()
	if(paine >= ((user.STAEND * 10) * 0.9))
		return NODE_SUCCESS

	return NODE_FAILURE

/bt_action/carbon_flee/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(!ishuman(user) || !target)
		return NODE_FAILURE

	var/const/NPC_FLEE_DISTANCE = 8
	if(get_dist(user, target) >= NPC_FLEE_DISTANCE)
		user.back_to_idle()
		return NODE_SUCCESS

	var/turf/flee_turf = get_ranged_target_turf(user, get_dir(target, user), NPC_FLEE_DISTANCE)
	if(flee_turf && user.set_ai_path_to(flee_turf))
		return NODE_RUNNING
	
	return NODE_FAILURE
