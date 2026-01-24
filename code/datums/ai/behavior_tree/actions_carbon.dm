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

	var/list/targets = get_nearby_entities(user, search_range)

	for(var/mob/living/L in targets)
		if(!user.should_target(L) || los_blocked(user, L, TRUE))
			continue

		var/dist = get_dist(user, L)
		if(dist < closest_dist)
			new_target = L
			closest_dist = dist

	if(new_target)
		if(user.ai_root)
			user.ai_root.target = new_target
			user.add_aggressor(new_target)

		user.retaliate(new_target) // Trigger aggro
		return NODE_SUCCESS

	return NODE_FAILURE

/bt_action/carbon_has_target/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(!ishuman(user))
		return NODE_FAILURE

	if(target && user.should_target(target))
		// Check if we can see the target
		if(get_dist(user, target) <= 7 && !los_blocked(user, target, TRUE))
			// Update last known location
			blackboard[AIBLK_LAST_KNOWN_TARGET_LOC] = get_turf(target)
			return NODE_SUCCESS

		// Target exists but we can't see them - let the target_persistence decorator handle this
		return NODE_SUCCESS

	// No valid target
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

	if(!prob(95) || !user.wander)
		return NODE_FAILURE

	// Simple random wander: pick a nearby tile and path to it
	if(user.ai_root && (!user.ai_root.path || !length(user.ai_root.path)))
		var/turf/T = get_ranged_target_turf(user, pick(GLOB.alldirs), 3)
		if(T && T.can_traverse_safely(user) && user.set_ai_path_to(T))
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
		user.ai_root.next_attack_tick = world.time + (user.ai_root.next_attack_delay || 12)
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

// ------------------------------------------------------------------------------
// MONSTER BAIT SUBDUE LOGIC
// ------------------------------------------------------------------------------

/bt_action/carbon_check_monster_bait/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(user.ai_root.blackboard[AIBLK_S_ACTION] && !length(user.sexcon.using_zones))
		user.ai_root.blackboard -= AIBLK_S_ACTION

	if(!target)
		return NODE_FAILURE
	
	if(target.pulledby && target.pulledby != user)
		user.ai_root.blackboard -= AIBLK_MONSTER_BAIT
		return NODE_FAILURE
	
	if(HAS_TRAIT(target, TRAIT_MONSTERBAIT))
		user.ai_root.blackboard[AIBLK_MONSTER_BAIT] = target
		return NODE_SUCCESS

	user.ai_root.blackboard -= AIBLK_MONSTER_BAIT
	return NODE_FAILURE

/bt_action/carbon_subdue_target
	var/blackboard_key = AIBLK_MONSTER_BAIT

/bt_action/carbon_subdue_target/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(user.doing) return NODE_RUNNING

	var/mob/living/carbon/victim = user.ai_root.blackboard[blackboard_key]

	if(!victim.getorganslot(ORGAN_SLOT_VAGINA))
		return NODE_FAILURE // Unviable for goblin reproduction. This is a placeholder for the future

	if(!ishuman(user) || !victim)
		return NODE_FAILURE

	if(victim.stat == DEAD)
		return NODE_FAILURE

	// If they are already restrained and we have them, we are done.
	if(victim.restrained())
		return NODE_SUCCESS

	// 1. If target is standing, we need to knock them down.
	if(!victim.restrained() && !victim.IsKnockdown() && !victim.IsUnconscious() && !victim.IsSleeping())
		// Move to range
		if(get_dist(user, victim) > 1)
			if(user.set_ai_path_to(victim))
				return NODE_RUNNING
		
		// Ensure we are using a blunt attack
		var/obj/item/W = user.get_active_held_item()
		var/found_blunt_mode = FALSE
		
		// 1. Check current weapon for blunt mode
		if(W)
			user.update_a_intents()
			for(var/datum/intent/I in user.possible_a_intents)
				if(I.blade_class == BCLASS_BLUNT || I.blade_class == BCLASS_SMASH)
					user.a_intent_change(I)
					found_blunt_mode = TRUE
					break
			
			if(!found_blunt_mode)
				// Current weapon has no blunt mode. Stow or drop it.
				if(!user.place_in_inventory(W))
					user.dropItemToGround(W)
				W = null
		
		// 2. If no weapon (or we just stowed it), check inventory for blunt weapon
		if(!W)
			var/obj/item/best_blunt = null
			for(var/obj/item/I in user.held_items + user.get_equipped_items(TRUE))
				if(!I || istype(I, /obj/item/clothing)) continue
				
				if(I.possible_item_intents)
					for(var/intent_path in I.possible_item_intents)
						var/bclass = initial(intent_path:blade_class)
						if(bclass == BCLASS_BLUNT || bclass == BCLASS_SMASH)
							best_blunt = I
							break
				if(best_blunt) break
			
			if(best_blunt)
				if(user.ensure_in_active_hand(best_blunt))
					W = best_blunt
					for(var/datum/intent/I in user.possible_a_intents)
						if(I.blade_class == BCLASS_BLUNT || I.blade_class == BCLASS_SMASH)
							user.a_intent_change(I)
							found_blunt_mode = TRUE
							break
		
		// 3. If still no weapon, use unarmed (Fists)
		if(!W)
			user.rog_intent_change(4)
			found_blunt_mode = TRUE
		
		// Target limbs to trip/disable
		user.zone_selected = pick(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM)
		if(user.doing) return NODE_RUNNING
		npc_click_on(user, victim)
		return NODE_RUNNING

	// 2. Target is DOWN. We need to restrain them.
	
	// Check if we are already grabbing them.
	var/obj/item/grabbing/G = user.get_active_held_item()
	if(!istype(G) || G.grabbed != victim)
		var/obj/item/grabbing/G_alt = user.get_inactive_held_item()
		if(istype(G_alt) && G_alt.grabbed == victim)
			G = G_alt
		else
			G = null
	
	// If we are holding a grab but it's not the victim, drop it.
	if(istype(G) && G.grabbed != victim)
		user.dropItemToGround(G)
		G = null

	if(!istype(G))
		// Not holding a grab.
		// Move to them first
		if(get_dist(user, victim) > 1)
			if(user.set_ai_path_to(victim))
				return NODE_RUNNING
			return NODE_FAILURE
			
		// Initiate Grab - Chest for pinning
		user.zone_selected = BODY_ZONE_CHEST
		if(user.get_active_held_item() && !user.get_inactive_held_item())
			user.swap_hand()
		else if(!user.get_active_held_item() && user.get_inactive_held_item())
			// Already have an empty active hand, do nothing
		else
			var/obj/held = user.get_active_held_item()
			if(held)
				user.dropItemToGround(held)

		user.rog_intent_change(3)

		if(user.doing) return NODE_RUNNING
		npc_click_on(user, victim)
		return NODE_RUNNING
	
	// We have a grab! Now check state.
	// We need AGGRESSIVE grab to shove/tackle.
	if(G.grab_state < GRAB_AGGRESSIVE)
		if(victim.IsStun() || victim.IsParalyzed() || victim.IsImmobilized() || victim.IsUnconscious() || victim.IsSleeping())
			G.grab_state = GRAB_AGGRESSIVE
			G.update_icon()
		else
			// Upgrade grab

			var/datum/intent/upgrade_intent = null
			var/datum/intent/I = locate(/datum/intent/grab/upgrade) in user.possible_a_intents
			if(I)
				upgrade_intent = I
			
			if(upgrade_intent)
				user.a_intent_change(I)
				if(user.doing) return NODE_RUNNING
				G.attack(victim, user)
				return NODE_RUNNING
			else
				return NODE_FAILURE

	// 3. Move ON TOP of them.
	if(user.loc != victim.loc)
		if(user.set_ai_path_to(victim))
			return NODE_RUNNING
		user.Move(get_turf(victim), get_dir(user, victim)) // Force step if pathing fails nearby
		return NODE_RUNNING

	// 4. Pin them (Tackle).
	var/is_pinned = (victim.IsStun() || victim.IsParalyzed() || victim.IsImmobilized() || victim.IsUnconscious() || victim.IsSleeping())
	
	if(!is_pinned)
		// Switch to Shove/Tackle intent
		var/datum/intent/shove_intent = null
		var/datum/intent/I = locate(/datum/intent/grab/shove) in user.possible_a_intents
		if(I)
			shove_intent = I
		
		if(shove_intent)
			user.a_intent_change(shove_intent)
			user.used_intent = shove_intent
			if(user.doing) return NODE_RUNNING
			G.attack(target, user)
			return NODE_RUNNING
		else
			return NODE_FAILURE

	// 5. Restrain them.
	var/obj/item/rope/R = user.find_item_in_inventory(/obj/item/rope)

	if(!R)
		R = new /obj/item/rope(user)
		if(!user.ensure_in_active_hand(R))
			user.dropItemToGround(R) // Should not happen but safety first
	else
		user.ensure_in_active_hand(R)
	
	// Apply restraints
	if(R && user.get_active_held_item() == R)
		if(user.doing) return NODE_RUNNING
		R.try_cuff_arms(victim, user)
		return NODE_RUNNING

	return NODE_RUNNING

// ------------------------------------------------------------------------------
// PURSUE AND SEARCH (replaces IS12 pursue/search timers)
// ------------------------------------------------------------------------------

// Moves to the last known location of a lost target
/bt_action/carbon_pursue_last_known/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(!ishuman(user) || !user.ai_root)
		return NODE_FAILURE

	// This action is only used when we DON'T have a current target
	if(user.ai_root.target)
		return NODE_FAILURE

	// Get last known location from the aggressors list
	// We'll store the last seen location when an aggressor attacks us
	var/turf/last_known_loc = blackboard[AIBLK_LAST_KNOWN_TARGET_LOC]
	if(!last_known_loc)
		return NODE_FAILURE

	// If we've reached the last known location, we're done pursuing
	if(get_turf(user) == last_known_loc)
		// Clear the last known location so we can transition to searching
		blackboard -= AIBLK_LAST_KNOWN_TARGET_LOC
		return NODE_SUCCESS

	// Move towards last known location
	if(user.set_ai_path_to(last_known_loc))
		return NODE_RUNNING

	return NODE_FAILURE

// Searches the area after reaching last known location
/bt_action/carbon_search_area/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(!ishuman(user) || !user.ai_root)
		return NODE_FAILURE

	// Only search if we don't have a target
	if(user.ai_root.target)
		return NODE_SUCCESS // Found target while searching!

	// Random search movement - more active than idle wander
	if(prob(40))
		var/list/dirs = shuffle(GLOB.cardinals.Copy())
		for(var/move_dir in dirs)
			var/turf/T = get_step(user, move_dir)
			if(user.set_ai_path_to(T))
				return NODE_RUNNING
			break

	return NODE_RUNNING

// Check aggressors list for potential targets (replaces IS12's aggressor checking in evaluate_target)
/bt_action/carbon_check_aggressors/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(!ishuman(user) || !user.ai_root)
		return NODE_FAILURE

	var/list/aggressors = blackboard[AIBLK_AGGRESSORS]
	if(!aggressors || !length(aggressors))
		return NODE_FAILURE

	// Clean up the aggressors list and build a list of visible ones
	var/list/visible_aggressors = list()
	var/list/to_remove = list()

	for(var/mob/living/L as anything in aggressors)
		// Remove dead or null entries
		if(!L || L.stat == DEAD)
			to_remove += L
			continue

		// Check if aggressor is in range and visible
		var/dist = get_dist(user, L)
		if(dist <= 7 && !los_blocked(user, L, TRUE))
			visible_aggressors += L
		else
			// They're out of range or not visible
			// If we have other visible aggressors OR we already have a different target, forget about this one
			if(length(visible_aggressors) > 0 || (user.ai_root.target && user.ai_root.target != L))
				to_remove += L

	// Clean up the list
	if(length(to_remove))
		aggressors -= to_remove

	// If we have no visible aggressors, fail
	if(!length(visible_aggressors))
		return NODE_FAILURE

	// Case 1: We have a target already
	if(user.ai_root.target)
		// If our current target is in the visible aggressors list, keep them
		if(user.ai_root.target in visible_aggressors)
			blackboard[AIBLK_LAST_KNOWN_TARGET_LOC] = get_turf(user.ai_root.target)
			return NODE_SUCCESS

		// Our current target is NOT in visible aggressors - switch to a visible one
		// Pick the closest visible aggressor
		var/mob/living/closest = null
		var/closest_dist = 999
		for(var/mob/living/L as anything in visible_aggressors)
			var/dist = get_dist(user, L)
			if(dist < closest_dist)
				closest = L
				closest_dist = dist

		if(closest)
			user.ai_root.target = closest
			blackboard[AIBLK_LAST_KNOWN_TARGET_LOC] = get_turf(closest)
			return NODE_SUCCESS

	// Case 2: We don't have a target - pick the closest visible aggressor
	else
		var/mob/living/closest = null
		var/closest_dist = INFINITY
		for(var/mob/living/L as anything in visible_aggressors)
			var/dist = get_dist(user, L)
			if(dist < closest_dist)
				closest = L
				closest_dist = dist

		if(closest)
			user.ai_root.target = closest
			blackboard[AIBLK_LAST_KNOWN_TARGET_LOC] = get_turf(closest)
			return NODE_SUCCESS

	return NODE_FAILURE

/bt_action/carbon_violate_target

/bt_action/carbon_violate_target/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(user.doing) return NODE_RUNNING

	var/mob/living/carbon/human/victim = target ? target : user.ai_root.blackboard[AIBLK_MONSTER_BAIT]

	if(!ishuman(user) || !victim || !victim.sexcon)
		return NODE_FAILURE

	// Only violate if they are not resisting or if they are restrained or incapacitated
	if(!victim.restrained() && !victim.IsUnconscious() && !victim.IsKnockdown() && !victim.IsSleeping() && !target.compliance && !target.surrendering)
		return NODE_FAILURE

	if(!user.sexcon)
		user.sexcon = new

	if(user.sexcon.is_spent())
		user.sexcon.stop_current_action()
		return NODE_SUCCESS

	if(user.getorganslot(ORGAN_SLOT_PENIS) && !user.sexcon.is_spent())
		user.sexcon.set_target(victim)
		user.sexcon.update_all_accessible_body_zones()
		victim.sexcon.update_all_accessible_body_zones()

		// Determine preferred action
		var/action_path = /datum/sex_action/vaginal_sex
		if(length(victim.sexcon.using_zones) && !length(user.sexcon.using_zones))
			if(BODY_ZONE_PRECISE_GROIN in victim.sexcon.using_zones)
				action_path = /datum/sex_action/force_blowjob
			if(BODY_ZONE_PRECISE_MOUTH in user.sexcon.using_zones)
				action_path = /datum/sex_action/anal_sex
			else
				return NODE_FAILURE // Uh oh
				
		var/datum/sex_action/action = SEX_ACTION(action_path)
		if(!action)
			return NODE_FAILURE

		var/used_zone = action_path == /datum/sex_action/force_blowjob ? BODY_ZONE_PRECISE_MOUTH : BODY_ZONE_PRECISE_GROIN
		var/used_bitflag = used_zone == BODY_ZONE_PRECISE_MOUTH ? MOUTH : GROIN
			
		// 1. Check if USER is accessible
		if(!action.check_location_accessible(user, user, used_zone))
			user.visible_message(span_warning("[user] starts stripping [user.p_their()] own clothing!"))
			if(do_mob(user, user, 30))
				var/stripped = FALSE
				var/list/stripping_candidates = list()
				// Strip self
				for(var/obj/I as anything in user.get_blocking_equipment(used_bitflag))
					stripping_candidates += I

				for(var/obj/item/I in stripping_candidates)
					if(user.dropItemToGround(I, TRUE, TRUE))
						stripped = TRUE
						break
				
				if(!stripped && user.underwear)
					var/obj/item/bodypart/chest = user.get_bodypart(BODY_ZONE_CHEST)
					if(chest)
						chest.remove_bodypart_feature(user.underwear.undies_feature)
					user.underwear.forceMove(get_turf(user))
					user.underwear = null
					stripped = TRUE
				
				if(stripped)
					user.sexcon.update_all_accessible_body_zones()
					return NODE_RUNNING
			return NODE_RUNNING

		// 2. Check if VICTIM is accessible
		if(!action.check_location_accessible(user, victim, used_zone))
			user.visible_message(span_warning("[user] starts stripping the clothing off of [victim]!"))
			if(do_mob(user, victim, 50))
				var/stripped = FALSE
				// Robust strip logic for victim
				var/list/stripping_candidates = list()

				// Prioritize outer layers
				for(var/obj/item/I in victim.get_blocking_equipment(used_bitflag))
					stripping_candidates += I

				for(var/obj/item/I in stripping_candidates)
					if(victim.dropItemToGround(I, TRUE, TRUE))
						stripped = TRUE
						break

				if(!stripped && victim.underwear)
					var/obj/item/bodypart/chest = victim.get_bodypart(BODY_ZONE_CHEST)
					if(chest)
						chest.remove_bodypart_feature(victim.underwear.undies_feature)
					victim.underwear.forceMove(get_turf(victim))
					victim.underwear = null
					stripped = TRUE

				if(stripped)
					victim.sexcon.update_all_accessible_body_zones()
					return NODE_RUNNING
				// If nothing was stripped, fall through to try the sex action anyway
			else
				return NODE_RUNNING // do_mob was interrupted

		// Move to same turf if adjacent (for sex positioning)
		position_for_sex(user, victim)

		// 3. Start/Continue action
		if(!user.ai_root.blackboard[AIBLK_S_ACTION])
			if(user.sexcon.arousal < 20)
				user.sexcon.set_arousal(22)
			user.sexcon.set_charge(SEX_MAX_CHARGE)
			user.sexcon.try_start_action(action_path)
			user.sexcon.adjust_force(2)
			user.ai_root.blackboard[AIBLK_S_ACTION] = "[action_path]"
			return NODE_RUNNING
		else
			// Check if finished or spent
			if(user.sexcon.just_ejaculated() || user.sexcon.is_spent())
				user.sexcon.stop_current_action()
				user.ai_root.blackboard -= AIBLK_S_ACTION
				return NODE_SUCCESS
			return NODE_RUNNING

	return NODE_FAILURE
