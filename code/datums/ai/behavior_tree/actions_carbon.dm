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
		if(!user.should_target(L) || los_blocked(user, L))
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

	if(!prob(95) || !user.wander)
		return NODE_FAILURE

	// Simple random wander: pick a nearby tile and path to it
	if(user.ai_root && (!user.ai_root.path || !length(user.ai_root.path)))
		var/turf/T = get_ranged_target_turf(user, pick(GLOB.cardinals), 3)
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

// ------------------------------------------------------------------------------
// MONSTER BAIT SUBDUE LOGIC
// ------------------------------------------------------------------------------

/bt_action/carbon_check_monster_bait/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(!target)
		return NODE_FAILURE
	
	if(target.pulledby && target.pulledby != user)
		user.ai_root.blackboard.Remove(AIBLK_MONSTER_BAIT)
		return NODE_FAILURE
	
	if(HAS_TRAIT(target, TRAIT_MONSTERBAIT))
		user.ai_root.blackboard[AIBLK_MONSTER_BAIT] = target
		return NODE_SUCCESS
	
	user.ai_root.blackboard.Remove(AIBLK_MONSTER_BAIT)
	return NODE_FAILURE

/bt_action/carbon_subdue_target
	var/blackboard_key = AIBLK_MONSTER_BAIT

/bt_action/carbon_subdue_target/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(user.doing) return NODE_RUNNING

	var/mob/living/carbon/victim = user.ai_root.blackboard[blackboard_key]

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
				if(!user.equip_to_appropriate_slot(W))
					user.dropItemToGround(W)
				W = null
		
		// 2. If no weapon (or we just stowed it), check inventory for blunt weapon
		if(!W)
			var/obj/item/best_blunt = null
			for(var/obj/item/I in user.contents)
				if(istype(I, /obj/item/clothing)) continue
				
				if(I.possible_item_intents)
					for(var/intent_path in I.possible_item_intents)
						var/bclass = initial(intent_path:blade_class)
						if(bclass == BCLASS_BLUNT || bclass == BCLASS_SMASH)
							best_blunt = I
							break
				if(best_blunt) break
			
			if(best_blunt)
				user.put_in_hands(best_blunt)
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
		user.ClickOn(victim)
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
		user.ClickOn(victim)
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
	var/obj/item/rope/R = locate(/obj/item/rope) in user.contents

	if(!R)
		R = new /obj/item/rope(user)
		user.put_in_hands(R)
		
		// If we couldn't put it in hands (e.g. hands full with grab and something else)
		if(user.get_active_held_item() != R && user.get_inactive_held_item() != R)
			// Try to put in other hand
			var/obj/item/offhand = user.get_inactive_held_item()
			if(offhand && !istype(offhand, /obj/item/grabbing)) // Don't drop the grab!
				user.dropItemToGround(offhand)
			user.put_in_hands(R)
	
	// Apply restraints
	if(R)
		if(user.get_active_held_item() != R)
			if(user.get_inactive_held_item() == R)
				user.swap_hand()
			else
				user.put_in_hands(R)
		
		if(user.get_active_held_item() == R)
			if(user.doing) return NODE_RUNNING
			R.try_cuff_arms(victim, user)
			return NODE_RUNNING

	return NODE_RUNNING

/bt_action/carbon_violate_target

/bt_action/carbon_violate_target/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(user.doing) return NODE_RUNNING

	var/mob/living/carbon/human/victim = target

	if(!ishuman(user) || !victim || !victim.sexcon)
		return NODE_FAILURE

	// Only violate if they are restrained
	if(!victim.restrained() && !victim.IsUnconscious() && !victim.IsKnockdown())
		return NODE_FAILURE

	if(!user.sexcon)
		user.sexcon = new

	if(user.sexcon.is_spent())
		user.sexcon.stop_current_action()
		return NODE_SUCCESS

	var/datum/sex_action/action = SEX_ACTION(/datum/sex_action/vaginal_sex)
	if(!action)
		return NODE_FAILURE
	
	if(user.getorganslot(ORGAN_SLOT_PENIS) && !user.sexcon.is_spent())
		user.sexcon.set_target(victim)
		user.sexcon.update_all_accessible_body_zones()
		victim.sexcon.update_all_accessible_body_zones()

		// Determine preferred action
		var/action_path = /datum/sex_action/vaginal_sex
		if(!victim.getorganslot(ORGAN_SLOT_VAGINA))
			action_path = /datum/sex_action/anal_sex
		
		action = SEX_ACTION(action_path)
		if(!action)
			return NODE_FAILURE
			
		// 1. Check if USER is accessible
		if(!action.check_location_accessible(user, user, BODY_ZONE_PRECISE_GROIN))
			user.visible_message(span_warning("[user] starts stripping [user.p_their()] own clothing!"))
			if(do_mob(user, user, 30))
				var/stripped = FALSE
				if(user.wear_shirt && (user.wear_shirt.body_parts_covered_dynamic & GROIN))
					user.dropItemToGround(user.wear_shirt, TRUE, TRUE)
					stripped = TRUE
				else if(user.wear_armor && (user.wear_armor.body_parts_covered_dynamic & GROIN))
					user.dropItemToGround(user.wear_armor, TRUE, TRUE)
					stripped = TRUE
				else if(user.wear_pants && (user.wear_pants.body_parts_covered_dynamic & GROIN))
					user.dropItemToGround(user.wear_pants, TRUE, TRUE)
					stripped = TRUE
				else if(user.underwear)
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
		if(!action.check_location_accessible(user, victim, BODY_ZONE_PRECISE_GROIN))
			user.visible_message(span_warning("[user] starts stripping the clothing off of [victim]!"))
			if(do_mob(user, victim, 50))
				var/stripped = FALSE
				if(victim.wear_shirt && (victim.wear_shirt.body_parts_covered_dynamic & GROIN))
					victim.dropItemToGround(victim.wear_shirt, TRUE, TRUE)
					stripped = TRUE
				else if(victim.wear_armor && (victim.wear_armor.body_parts_covered_dynamic & GROIN))
					victim.dropItemToGround(victim.wear_armor, TRUE, TRUE)
					stripped = TRUE
				else if(victim.wear_pants && (victim.wear_pants.body_parts_covered_dynamic & GROIN))
					victim.dropItemToGround(victim.wear_pants, TRUE, TRUE)
					stripped = TRUE
				else if(victim.underwear)
					var/obj/item/bodypart/chest = victim.get_bodypart(BODY_ZONE_CHEST)
					if(chest)
						chest.remove_bodypart_feature(victim.underwear.undies_feature)
					victim.underwear.forceMove(get_turf(victim))
					victim.underwear = null
					stripped = TRUE
				
				if(stripped)
					victim.sexcon.update_all_accessible_body_zones()
					return NODE_RUNNING
				else
					return NODE_FAILURE
			return NODE_RUNNING

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
			if(user.sexcon.just_ejaculated())
				user.sexcon.stop_current_action()
				user.ai_root.blackboard.Remove(AIBLK_S_ACTION)
				return NODE_SUCCESS
			return NODE_RUNNING

	return NODE_FAILURE
