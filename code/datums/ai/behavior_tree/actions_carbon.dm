// ==============================================================================
// CARBON/HUMAN BEHAVIOR TREE ACTIONS (ATOMIZED)
// ==============================================================================

// ------------------------------------------------------------------------------
// TARGETING
// ------------------------------------------------------------------------------

/bt_action/carbon_find_target
	var/search_range = 7

/bt_action/carbon_find_target/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(!ishuman(user)) return NODE_FAILURE

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
		if(user.faction_check_mob(L)) continue
		var/ai_squad/my_squad = user.ai_root.blackboard[AIBLK_SQUAD_DATUM] ? user.ai_root.blackboard[AIBLK_SQUAD_DATUM] : null
		var/ai_squad/their_squad = L.ai_root?.blackboard[AIBLK_SQUAD_DATUM] ? L.ai_root.blackboard[AIBLK_SQUAD_DATUM] : null
		if(my_squad && their_squad && my_squad == their_squad) continue

		var/dist = get_dist(user, L)
		if(dist < closest_dist)
			new_target = L
			closest_dist = dist

	if(new_target)
		if(user.ai_root)
			user.ai_root.target = new_target
			user.add_aggressor(new_target)
		user.retaliate(new_target)
		return NODE_SUCCESS

	return NODE_FAILURE

/bt_action/carbon_has_target/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(!ishuman(user)) return NODE_FAILURE
	if(target && user.should_target(target))
		if(get_dist(user, target) <= 7 && !los_blocked(user, target, TRUE))
			blackboard[AIBLK_LAST_KNOWN_TARGET_LOC] = get_turf(target)
			return NODE_SUCCESS
		return NODE_SUCCESS
	
	if(user.ai_root)
		user.ai_root.target = null
		user.back_to_idle()
	return NODE_FAILURE

// ------------------------------------------------------------------------------
// SUBDUE LOGIC
// ------------------------------------------------------------------------------

/bt_action/ensure_blunt_weapon
/bt_action/ensure_blunt_weapon/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	// Check if we are already using blunt intent/weapon
	var/obj/item/W = user.equip_best_weapon_for_damage_type(GLOB.crush_bclasses)
	var/found_blunt = FALSE
	
	if(W)
		user.update_a_intents()
		for(var/i = 1 to length(user.possible_a_intents))
			var/datum/intent/I = user.possible_a_intents[i]
			if(I.blade_class == BCLASS_BLUNT || I.blade_class == BCLASS_SMASH)
				if(user.used_intent != I) user.a_intent_change(i)
				found_blunt = TRUE
				break
	
	if(found_blunt) return NODE_SUCCESS
	
	// If not, find one or switch to unarmed
	// (just switch to unarmed if current weapon isn't blunt)
	if(W)
		if(!user.place_in_inventory(W))
			user.dropItemToGround(W)
	
	user.rog_intent_change(4) // Unarmed
	return NODE_SUCCESS

/bt_action/knockdown_target
/bt_action/knockdown_target/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	var/mob/living/victim = target ? target : user.ai_root.blackboard[AIBLK_MONSTER_BAIT]
	if(!victim) return NODE_FAILURE
	
	if(victim.IsKnockdown() || victim.IsParalyzed() || victim.IsUnconscious() || victim.IsSleeping())
		return NODE_SUCCESS
		
	if(get_dist(user, victim) > 1) return NODE_FAILURE // Must be close
	
	// Target legs
	user.zone_selected = pick(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
	npc_click_on(user, victim)
	return NODE_RUNNING

/bt_action/grapple_target
/bt_action/grapple_target/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	var/mob/living/victim = target ? target : user.ai_root.blackboard[AIBLK_MONSTER_BAIT]
	if(!victim) return NODE_FAILURE

	// Check if already grabbing
	var/obj/item/grabbing/G = user.get_active_held_item()
	if(istype(G) && G.grabbed == victim) return NODE_SUCCESS
	
	// Initiate grab
	user.zone_selected = BODY_ZONE_CHEST
	user.select_intent_and_attack(INTENT_GRAB, victim)
	return NODE_RUNNING

/bt_action/upgrade_grapple
/bt_action/upgrade_grapple/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	var/obj/item/grabbing/G = user.get_active_held_item()
	if(!istype(G)) return NODE_FAILURE
	
	if(G.grab_state >= GRAB_AGGRESSIVE) return NODE_SUCCESS
	
	user.use_grab_intent(G, /datum/intent/grab/upgrade, G.grabbed)
	return NODE_RUNNING

/bt_action/pin_target
/bt_action/pin_target/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	var/mob/living/victim = target ? target : user.ai_root.blackboard[AIBLK_MONSTER_BAIT]
	if(!victim) return NODE_FAILURE
	
	if(victim.IsParalyzed() || victim.restrained()) return NODE_SUCCESS
	
	var/obj/item/grabbing/G = user.get_active_held_item()
	if(!istype(G) || G.grab_state < GRAB_AGGRESSIVE || G.grabbed != victim || get_turf(user) != get_turf(victim)) return NODE_FAILURE
	
	// Pin/Tackle
	user.use_grab_intent(G, /datum/intent/grab/shove, victim)
	return NODE_RUNNING

/bt_action/cuff_target
/bt_action/cuff_target/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	var/mob/living/victim = target ? target : user.ai_root.blackboard[AIBLK_MONSTER_BAIT]
	if(!victim) return NODE_FAILURE
	
	if(victim.restrained()) return NODE_SUCCESS
	
	var/obj/item/rope/R = user.find_item_in_inventory(/obj/item/rope)
	if(!R)
		R = new /obj/item/rope(user)
		user.ensure_in_active_hand(R)
		
	if(user.get_active_held_item() == R)
		R.try_cuff_arms(victim, user)
		return NODE_RUNNING
		
	return NODE_FAILURE

// ------------------------------------------------------------------------------
// VIOLATION LOGIC (ATOMIZED)
// ------------------------------------------------------------------------------

/bt_action/strip_victim
/bt_action/strip_victim/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	var/mob/living/carbon/human/victim = target ? target : user.ai_root.blackboard[AIBLK_MONSTER_BAIT]
	if(!ishuman(victim)) return NODE_FAILURE
	
	var/used_bitflag = GROIN
	if(!user.getorganslot(ORGAN_SLOT_PENIS)) used_bitflag = MOUTH 
	
	if(!victim.get_blocking_equipment(used_bitflag)) return NODE_SUCCESS // Exposed
	
	if(user.doing) return NODE_RUNNING
	
	// Strip logic
	user.visible_message(span_warning("[user] tears at [victim]'s clothing!"))
	if(do_mob(user, victim, 30))
		for(var/obj/item/I in victim.get_blocking_equipment(used_bitflag))
			victim.dropItemToGround(I, TRUE, TRUE)
			return NODE_RUNNING
			
	return NODE_RUNNING

/bt_action/position_for_sex
/bt_action/position_for_sex/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	var/mob/living/victim = target ? target : user.ai_root.blackboard[AIBLK_MONSTER_BAIT]
	if(!victim) return NODE_FAILURE
	
	var/turf/T = get_turf(victim)
	if(get_turf(user) == T) return NODE_SUCCESS
	
	user.Move(T, get_dir(user, T))
	return NODE_RUNNING

/bt_action/start_sex
/bt_action/start_sex/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(user.ai_root.blackboard[AIBLK_S_ACTION]) return NODE_SUCCESS // Already started
	
	var/mob/living/victim = target ? target : user.ai_root.blackboard[AIBLK_MONSTER_BAIT]
	if(!victim) return NODE_FAILURE
	
	if(!user.sexcon) user.sexcon = new
	user.sexcon.set_target(victim)
	user.sexcon.update_all_accessible_body_zones()
	
	var/action_path = /datum/sex_action/vaginal_sex
	
	if(user.getorganslot(ORGAN_SLOT_PENIS))
		if(victim.getorganslot(ORGAN_SLOT_VAGINA) && (BODY_ZONE_PRECISE_GROIN in victim.sexcon.using_zones))
			action_path = /datum/sex_action/vaginal_sex
		else if(BODY_ZONE_PRECISE_MOUTH in victim.sexcon.using_zones)
			action_path = /datum/sex_action/force_blowjob
		else if(BODY_ZONE_PRECISE_GROIN in victim.sexcon.using_zones) // Fallback to anal if no vagina but groin accessible
			action_path = /datum/sex_action/anal_sex
		else
			return NODE_FAILURE // Nothing accessible
	else
		return NODE_FAILURE 
	
	user.sexcon.try_start_action(action_path)
	user.ai_root.blackboard[AIBLK_S_ACTION] = "[action_path]"
	return NODE_SUCCESS

/bt_action/continue_sex
/bt_action/continue_sex/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(!user.ai_root.blackboard[AIBLK_S_ACTION]) return NODE_FAILURE
	
	if(user.sexcon.just_ejaculated() || user.sexcon.is_spent())
		user.sexcon.stop_current_action()
		user.ai_root.blackboard -= AIBLK_S_ACTION
		return NODE_SUCCESS // Finished
		
	return NODE_RUNNING

// ------------------------------------------------------------------------------
// OTHER ACTIONS
// ------------------------------------------------------------------------------

/bt_action/carbon_check_monster_bait/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(user.ai_root.blackboard[AIBLK_S_ACTION] && !length(user.sexcon.using_zones))
		user.ai_root.blackboard -= AIBLK_S_ACTION

	if(!target) return NODE_FAILURE
	
	if(HAS_TRAIT(target, TRAIT_MONSTERBAIT))
		user.ai_root.blackboard[AIBLK_MONSTER_BAIT] = target
		return NODE_SUCCESS

	return NODE_FAILURE

/bt_action/carbon_move_to_target/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(user.Adjacent(target)) return NODE_SUCCESS
	if(user.ai_root.move_destination == get_turf(target) || user.set_ai_path_to(target)) return NODE_RUNNING
	return NODE_FAILURE

/bt_action/carbon_idle_wander/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(prob(8) && user.wander && user.ai_root)
		var/turf/T = get_step(user, pick(GLOB.cardinals))
		if(!T) return NODE_FAILURE
		else if(user.set_ai_path_to(T)) return NODE_RUNNING
	return NODE_RUNNING

/bt_action/carbon_attack_melee/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(user.Adjacent(target))
		user.face_atom(target)
		npc_click_on(user, target)
		return NODE_SUCCESS
	return NODE_FAILURE

/bt_action/carbon_equip_weapon/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	var/obj/item/held = user.get_active_held_item()
	if(held) 
		if(user.equip_best_weapon_for_damage_type(GLOB.crush_bclasses))
			return NODE_SUCCESS
	
	for(var/obj/item/I in range(1, user))
		if(I.force > 7 && user.equip_item(I)) return NODE_SUCCESS
	return NODE_FAILURE

/bt_action/carbon_should_flee/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(user.get_complex_pain() >= ((user.STAEND * 10) * 0.9)) return NODE_SUCCESS
	return NODE_FAILURE

/bt_action/carbon_flee/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	var/turf/flee_turf = get_ranged_target_turf(user, get_dir(target, user), 8)
	if(flee_turf && user.set_ai_path_to(flee_turf)) return NODE_RUNNING
	return NODE_FAILURE

// ------------------------------------------------------------------------------
// RESTORED ACTIONS
// ------------------------------------------------------------------------------

/bt_action/carbon_check_aggressors
	parent_type = /bt_action/switch_to_aggressor

/bt_action/carbon_pursue_last_known/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(!ishuman(user) || !user.ai_root) return NODE_FAILURE
	if(user.ai_root.target) return NODE_FAILURE
	
	var/turf/last_known_loc = blackboard[AIBLK_LAST_KNOWN_TARGET_LOC]
	if(!last_known_loc) return NODE_FAILURE
	
	if(get_turf(user) == last_known_loc)
		blackboard -= AIBLK_LAST_KNOWN_TARGET_LOC
		return NODE_SUCCESS
		
	if(user.set_ai_path_to(last_known_loc)) return NODE_RUNNING
	return NODE_FAILURE

/bt_action/carbon_search_area/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(!ishuman(user) || !user.ai_root) return NODE_FAILURE
	if(user.ai_root.target) return NODE_SUCCESS
	
	if(prob(40))
		var/turf/T = get_step(user, pick(GLOB.cardinals))
		if(user.set_ai_path_to(T)) return NODE_RUNNING
	return NODE_RUNNING

/bt_action/carbon_target_in_range
	var/range = 1
/bt_action/carbon_target_in_range/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(target && get_dist(user, target) <= range) return NODE_SUCCESS
	return NODE_FAILURE
