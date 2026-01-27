// ==============================================================================
// GOBLIN BEHAVIOR TREE ACTIONS
// ==============================================================================

// ------------------------------------------------------------------------------
// SQUAD COORDINATION
// ------------------------------------------------------------------------------

// ------------------------------------------------------------------------------
// BLACKBOARD CLEANUP
// ------------------------------------------------------------------------------

// Action node to clean up goblin squad-related blackboard keys when no longer needed
/bt_action/goblin_cleanup_squad_state/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(!user.ai_root) return NODE_SUCCESS

	// Clean up squad state if:
	// 1. No target
	// 2. Target is dead
	// 3. No longer in combat
	// 4. Squad no longer exists

	var/should_cleanup = FALSE

	// Check if we have no target or target is invalid
	if(!user.ai_root.target || (isliving(user.ai_root.target) && user.ai_root.target:stat == DEAD))
		should_cleanup = TRUE

	// Check if we're not in a squad anymore
	var/ai_squad/squad = user.ai_root.blackboard[AIBLK_SQUAD_DATUM]
	if(!squad || !(user in squad.members))
		should_cleanup = TRUE

	// Check if we're alone (no squad mates nearby and no formal squad)
	if(!squad)
		var/list/squad_mates = user.ai_root.blackboard[AIBLK_SQUAD_MATES]
		if(!squad_mates || !length(squad_mates))
			should_cleanup = TRUE

	if(should_cleanup)
		// Clear squad coordination keys
		user.ai_root.blackboard -= AIBLK_SQUAD_ROLE
		user.ai_root.blackboard -= AIBLK_SQUAD_MATES
		user.ai_root.blackboard -= AIBLK_SQUAD_SIZE
		user.ai_root.blackboard -= AIBLK_VIOLATION_INTERRUPTED
		user.ai_root.blackboard -= AIBLK_DEFENDING_FROM_INTERRUPT
		user.ai_root.blackboard -= AIBLK_IS_PINNING

		// Clear MONSTER_BAIT state if target is gone/dead
		var/mob/living/bait = user.ai_root.blackboard[AIBLK_MONSTER_BAIT]
		if(!bait || bait.stat == DEAD || !bait.loc)
			user.ai_root.blackboard -= AIBLK_MONSTER_BAIT
			user.ai_root.blackboard -= AIBLK_S_ACTION
			user.ai_root.blackboard -= AIBLK_DRAG_START_LOC

	return NODE_SUCCESS

// ------------------------------------------------------------------------------
// HELPER PROCS
// ------------------------------------------------------------------------------

// Check if a mob has armor equipped in any armor slot
/proc/has_armor_equipped(mob/living/carbon/human/H)
	if(!ishuman(H)) return FALSE
	var/list/armor_slots = list(SLOT_HEAD, SLOT_ARMOR, SLOT_GLOVES, SLOT_SHOES)
	for(var/slot in armor_slots)
		var/obj/item/clothing/armor = H.get_item_by_slot(slot)
		if(armor && armor.armor_class >= ARMOR_CLASS_LIGHT)
			return TRUE
	return FALSE

// Move to adjacent position if not already adjacent
// Returns: NODE_RUNNING if moving, NODE_FAILURE if can't path, null if already adjacent
/proc/move_adjacent_to(mob/living/carbon/human/user, atom/target)
	if(get_dist(user, target) > 1)
		if(user.set_ai_path_to(target))
			return NODE_RUNNING
		return NODE_FAILURE
	return null // Already adjacent

// Force user to move onto the same turf as target and face the same direction (for sexcon)
// This overrides normal movement pathing
/proc/position_for_sex(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!user || !target) return
	var/turf/T = get_turf(target)
	if(get_turf(user) != T && user.Adjacent(target) && !is_blocked_turf(T, FALSE))
		user.Move(T, get_dir(user, target))
		user.dir = target.dir

/bt_action/goblin_squad_coordination
	var/coordination_range = 10

/bt_action/goblin_squad_coordination/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(!user.ai_root) return NODE_FAILURE

	var/current_role = user.ai_root.blackboard[AIBLK_SQUAD_ROLE]

	// Check for interruptions - new aggressors attacking us or squad mates
	var/mob/living/interrupter = check_for_interrupter(user)

	// Violators are "sticky" - they only switch if personally attacked
	if(current_role == GOB_SQUAD_ROLE_VIOLATOR && interrupter)
		// Only switch if WE were attacked, not squad mates
		var/list/our_aggressors = user.ai_root.blackboard[AIBLK_AGGRESSORS]
		var/personally_attacked = FALSE
		if(our_aggressors && (interrupter in our_aggressors))
			// Check if this is a new aggressor (recent attack)
			personally_attacked = TRUE

		if(personally_attacked)
			// Violator interrupted, switch to interrupter
			user.ai_root.target = interrupter
			user.ai_root.blackboard[AIBLK_SQUAD_ROLE] = GOB_SQUAD_ROLE_ATTACKER // Become attacker
			user.ai_root.blackboard[AIBLK_VIOLATION_INTERRUPTED] = TRUE
		else
			// Not personally attacked, keep violating
			return NODE_SUCCESS

	// Non-violators respond to any interrupter
	else if(interrupter && current_role != GOB_SQUAD_ROLE_VIOLATOR)
		user.ai_root.target = interrupter
		// Keep our role, just switch target temporarily
		user.ai_root.blackboard[AIBLK_DEFENDING_FROM_INTERRUPT] = interrupter
		return NODE_SUCCESS

	// Check if we're part of an ai_squad
	var/ai_squad/squad = user.ai_root.blackboard[AIBLK_SQUAD_DATUM]

	if(squad)
		// Use squad-assigned priority target
		var/mob/living/squad_target = squad.blackboard[AIBLK_SQUAD_PRIORITY_TARGET]
		if(squad_target)
			// Check if this target is ignored
			var/list/ignored = user.ai_root.blackboard[AIBLK_IGNORED_TARGETS]
			if(!(ignored && squad_target && ignored[squad_target]))
				if(user.ai_root.target != squad_target)
					user.ai_root.target = squad_target

				// Check if target is MONSTER_BAIT
				if(HAS_TRAIT(squad_target, TRAIT_MONSTERBAIT))
					user.ai_root.blackboard[AIBLK_MONSTER_BAIT] = squad_target

		// Store squad info
		user.ai_root.blackboard[AIBLK_SQUAD_MATES] = squad.members - user
		user.ai_root.blackboard[AIBLK_SQUAD_SIZE] = length(squad.members)

		// Role is assigned by squad.RunAI(), just return success
		return NODE_SUCCESS

	// No ai_squad - use fallback coordination for nearby goblins
	var/list/squad_mates = list()
	var/atom/our_target = user.ai_root.target

	if(!our_target)
		return NODE_SUCCESS

	// Get all nearby goblins
	var/list/entities = get_nearby_entities(user, coordination_range)
	for(var/mob/living/carbon/human/G in entities)
		if(G == user) continue
		if(!isgoblin(G)) continue
		if(!G.ai_root || G.stat == DEAD) continue

		// Check if they share our target
		if(G.ai_root.target == our_target)
			squad_mates += G

	// Store squad mates in blackboard
	user.ai_root.blackboard[AIBLK_SQUAD_MATES] = squad_mates
	user.ai_root.blackboard[AIBLK_SQUAD_SIZE] = length(squad_mates) + 1 // +1 for ourselves

	// If we have squad mates, coordinate roles
	if(length(squad_mates) > 0)
		assign_squad_roles(user, our_target, squad_mates)
	else
		// Solo goblin, clear any role
		user.ai_root.blackboard -= AIBLK_SQUAD_ROLE

	return NODE_SUCCESS

/bt_action/goblin_squad_coordination/proc/check_for_interrupter(mob/living/carbon/human/user)
	// Check our aggressors for new threats
	var/list/aggressors = user.ai_root.blackboard[AIBLK_AGGRESSORS]
	if(!aggressors || !length(aggressors))
		return null

	var/current_target = user.ai_root.target

	// Find highest priority interrupter
	for(var/mob/living/L in aggressors)
		if(!L || L.stat == DEAD) continue
		if(L == current_target) continue // Already targeting them

		// Check if visible and in range
		var/dist = get_dist(user, L)
		if(dist <= 7 && !los_blocked(user, L, TRUE))
			// New visible aggressor - this is an interrupter
			return L

	return null

/bt_action/goblin_squad_coordination/proc/assign_squad_roles(mob/living/carbon/human/user, atom/target, list/squad_mates)
	// Build complete squad list
	var/list/full_squad = list(user) + squad_mates

	// Check if target is MONSTER_BAIT
	var/is_bait = FALSE
	if(isliving(target))
		var/mob/living/L = target
		is_bait = HAS_TRAIT(L, TRAIT_MONSTERBAIT)
		if(is_bait)
			user.ai_root.blackboard[AIBLK_MONSTER_BAIT] = L

	// Count existing role assignments
	var/restrainer_count = 0
	var/stripper_count = 0
	var/violator_count = 0

	for(var/mob/living/carbon/human/goblin in full_squad)
		var/role = goblin.ai_root.blackboard[AIBLK_SQUAD_ROLE]
		switch(role)
			if(GOB_SQUAD_ROLE_RESTRAINER)
				restrainer_count++
			if(GOB_SQUAD_ROLE_STRIPPER)
				stripper_count++
			if(GOB_SQUAD_ROLE_VIOLATOR)
				violator_count++

	// Assign roles if we don't have one
	if(!user.ai_root.blackboard[AIBLK_SQUAD_ROLE])
		if(restrainer_count < 1)
			user.ai_root.blackboard[AIBLK_SQUAD_ROLE] = GOB_SQUAD_ROLE_RESTRAINER
		else if(stripper_count < 2 && length(full_squad) >= 2)
			user.ai_root.blackboard[AIBLK_SQUAD_ROLE] = GOB_SQUAD_ROLE_STRIPPER
		else if(is_bait && violator_count < 1)
			user.ai_root.blackboard[AIBLK_SQUAD_ROLE] = GOB_SQUAD_ROLE_VIOLATOR
		else
			user.ai_root.blackboard[AIBLK_SQUAD_ROLE] = GOB_SQUAD_ROLE_ATTACKER

// ------------------------------------------------------------------------------
// SQUAD ROLE CHECKERS
// ------------------------------------------------------------------------------

/bt_action/goblin_has_squad_role/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	return user.ai_root.blackboard[AIBLK_SQUAD_ROLE] ? NODE_SUCCESS : NODE_FAILURE

/bt_action/goblin_is_restrainer/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	return user.ai_root.blackboard[AIBLK_SQUAD_ROLE] == GOB_SQUAD_ROLE_RESTRAINER ? NODE_SUCCESS : NODE_FAILURE

/bt_action/goblin_is_stripper/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	return user.ai_root.blackboard[AIBLK_SQUAD_ROLE] == GOB_SQUAD_ROLE_STRIPPER ? NODE_SUCCESS : NODE_FAILURE

/bt_action/goblin_is_violator/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	return user.ai_root.blackboard[AIBLK_SQUAD_ROLE] == GOB_SQUAD_ROLE_VIOLATOR ? NODE_SUCCESS : NODE_FAILURE

/bt_action/goblin_is_attacker/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	return user.ai_root.blackboard[AIBLK_SQUAD_ROLE] == GOB_SQUAD_ROLE_ATTACKER ? NODE_SUCCESS : NODE_FAILURE

// ------------------------------------------------------------------------------
// SQUAD TACTICS - SURROUND
// ------------------------------------------------------------------------------

/bt_action/goblin_surround_target/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(!target || !user.ai_root)
		return NODE_FAILURE

	// Only surround if we have squad mates
	var/squad_size = user.ai_root.blackboard[AIBLK_SQUAD_SIZE]
	if(!squad_size || squad_size < 2)
		return NODE_SUCCESS // Solo, skip surrounding

	var/list/squad_mates = user.ai_root.blackboard[AIBLK_SQUAD_MATES]
	if(!squad_mates) squad_mates = list()

	var/turf/target_turf = get_turf(target)
	if(!target_turf) return NODE_FAILURE

	// Check if we're already adjacent to target
	if(user.Adjacent(target))
		return NODE_SUCCESS // Already in position

	// Get all adjacent turfs around target
	var/list/surrounding_turfs = list()
	for(var/turf/T in orange(1, target_turf))
		if(!T.density)
			surrounding_turfs += T

	if(!length(surrounding_turfs))
		return NODE_FAILURE

	// Find occupied and reserved positions
	var/list/occupied_or_reserved = list()
	for(var/mob/living/M as anything in squad_mates + user)
		var/turf/M_turf = get_turf(M)
		// Check if they're already on a surrounding turf
		if(M_turf in surrounding_turfs)
			occupied_or_reserved += M_turf
		// Check if they're pathing to a surrounding turf
		if(M.ai_root?.move_destination)
			var/turf/dest = get_turf(M.ai_root.move_destination)
			if(dest in surrounding_turfs)
				occupied_or_reserved += dest

	// Find the closest free tile
	var/turf/best_turf = null
	var/best_dist = 999

	for(var/turf/T as anything in surrounding_turfs)
		// Skip if occupied or reserved
		if(T in occupied_or_reserved)
			continue

		// Check if any mobs are on this tile or pathing to it
		var/already_claimed = FALSE
		for(var/mob/living/M in T)
			already_claimed = TRUE
			break

		if(already_claimed)
			continue

		// Check if we can actually reach it
		var/dist = get_dist(user, T)
		if(dist < best_dist)
			best_dist = dist
			best_turf = T

	// If we found a free tile, path to it
	if(best_turf)
		if(user.set_ai_path_to(best_turf))
			return NODE_RUNNING
		return NODE_FAILURE

	// All tiles occupied/reserved - find closest position NEAR the target
	// This handles when target is blocked by allies
	var/turf/our_turf = get_turf(user)
	var/turf/fallback = null
	var/fallback_dist = 999

	for(var/turf/T in range(2, target_turf))
		if(T.density || T == our_turf)
			continue

		var/occupied = FALSE
		for(var/mob/living/M in T)
			if(M != user)
				occupied = TRUE
				break

		if(!occupied)
			var/dist = get_dist(user, T)
			if(dist < fallback_dist)
				fallback_dist = dist
				fallback = T

	if(fallback && user.set_ai_path_to(fallback))
		return NODE_RUNNING

	return NODE_SUCCESS // Can't find position, let role actions handle it

// ------------------------------------------------------------------------------
// SQUAD TACTICS - RESTRAIN
// ------------------------------------------------------------------------------

/bt_action/goblin_restrain_target/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(!ishuman(user) || !isliving(target) || !user.ai_root)
		return NODE_FAILURE

	var/mob/living/carbon/human/victim = target
	if(QDELETED(victim) || victim.stat == DEAD)
		return NODE_FAILURE

	// Only restrainer should do this
	var/role = user.ai_root.blackboard[AIBLK_SQUAD_ROLE]
	if(role != GOB_SQUAD_ROLE_RESTRAINER)
		return NODE_SUCCESS // Not our job

	// Get or initialize our state
	var/state = user.ai_root.blackboard[AIBLK_RESTRAIN_STATE]
	if(!state)
		state = GOB_RESTRAIN_STATE_NONE
		user.ai_root.blackboard[AIBLK_RESTRAIN_STATE] = state

	// If victim is already pinned, continue
	if(victim.IsParalyzed() && state == GOB_RESTRAIN_STATE_PINNED)
		return NODE_SUCCESS

	// Must be adjacent for all actions
	var/move_result = move_adjacent_to(user, victim)
	if(move_result)
		return move_result

	// Get current grab state
	var/obj/item/grabbing/G = user.get_active_held_item()
	if(!istype(G) || G.grabbed != victim)
		G = user.get_inactive_held_item()
		if(!istype(G) || G.grabbed != victim)
			G = null

	// Count how many goblins are grabbing the victim (for auto-win bonus)
	var/grab_count = 0
	for(var/obj/item/grabbing/grab as anything in victim.grabbedby)
		if(grab && grab.grabbee && isgoblin(grab.grabbee))
			grab_count++

	// Check cooldown for actions (but not for initial weapon stowing)
	var/on_cooldown = (world.time < user.ai_root.next_attack_tick)

	// State machine
	switch(state)
		if(GOB_RESTRAIN_STATE_NONE, GOB_RESTRAIN_STATE_GRABBING)
			// Need to establish grab
			if(!G)
				// Stow weapon first
				var/obj/item/held = user.get_active_held_item()
				if(held)
					if(!user.place_in_inventory(held))
						user.dropItemToGround(held)
					return NODE_RUNNING

				if(on_cooldown)
					return NODE_RUNNING

				// Attempt grab
				if(user.select_intent_and_attack(INTENT_GRAB, victim))
					user.ai_root.blackboard[AIBLK_RESTRAIN_STATE] = GOB_RESTRAIN_STATE_GRABBING
					return NODE_RUNNING
				return NODE_FAILURE
			else
				// Successfully grabbed, move to upgrade
				user.ai_root.blackboard[AIBLK_RESTRAIN_STATE] = GOB_RESTRAIN_STATE_UPGRADING
				return NODE_RUNNING

		if(GOB_RESTRAIN_STATE_UPGRADING)
			if(!G)
				// Lost the grab, reset
				user.ai_root.blackboard[AIBLK_RESTRAIN_STATE] = GOB_RESTRAIN_STATE_NONE
				return NODE_RUNNING

			if(G.grab_state >= GRAB_AGGRESSIVE)
				// Already upgraded, move to tackle
				user.ai_root.blackboard[AIBLK_RESTRAIN_STATE] = GOB_RESTRAIN_STATE_TACKLING
				return NODE_RUNNING

			if(user.doing || on_cooldown)
				return NODE_RUNNING

			// Upgrade the grab
			if(grab_count >= 2)
				// Auto-win upgrade
				user.ai_root.next_attack_tick = world.time + (user.ai_root.next_attack_delay || 10)
				G.grab_state = GRAB_AGGRESSIVE
				victim.visible_message(span_danger("[user] tightens [user.p_their()] grip on [victim]!"), span_danger("[user] tightens [user.p_their()] grip on me!"))
				user.ai_root.blackboard[AIBLK_RESTRAIN_STATE] = GOB_RESTRAIN_STATE_TACKLING
			else
				user.ai_root.next_attack_tick = world.time + (user.ai_root.next_attack_delay || 10)
				user.use_grab_intent(G, /datum/intent/grab/upgrade, victim)
			return NODE_RUNNING

		if(GOB_RESTRAIN_STATE_TACKLING)
			if(!G)
				// Lost the grab, reset
				user.ai_root.blackboard[AIBLK_RESTRAIN_STATE] = GOB_RESTRAIN_STATE_NONE
				return NODE_RUNNING

			if(victim.IsKnockdown())
				// Already knocked down, move to pin
				user.ai_root.blackboard[AIBLK_RESTRAIN_STATE] = GOB_RESTRAIN_STATE_PINNING
				return NODE_RUNNING

			if(user.doing || on_cooldown)
				return NODE_RUNNING

			// Tackle them down
			if(grab_count >= 2)
				// Auto-win tackle
				user.ai_root.next_attack_tick = world.time + (user.ai_root.next_attack_delay || 10)
				victim.Knockdown(30)
				victim.visible_message(span_danger("[user] tackles [victim] down!"), span_danger("[user] tackles me down!"))
				user.ai_root.blackboard[AIBLK_RESTRAIN_STATE] = GOB_RESTRAIN_STATE_PINNING
			else
				user.ai_root.next_attack_tick = world.time + (user.ai_root.next_attack_delay || 10)
				user.use_grab_intent(G, /datum/intent/grab/shove, victim)
			return NODE_RUNNING

		if(GOB_RESTRAIN_STATE_PINNING)
			if(!G)
				// Lost the grab, reset
				user.ai_root.blackboard[AIBLK_RESTRAIN_STATE] = GOB_RESTRAIN_STATE_NONE
				return NODE_RUNNING

			if(user.doing)
				return NODE_RUNNING

			// Move on top for pinning position
			if(get_turf(user) != get_turf(victim))
				position_for_sex(user, victim)

			// Attempt to pin
			if(grab_count >= 2)
				// Auto-win pin
				victim.Paralyze(15 SECONDS)
				victim.visible_message(span_danger("[user] pins [victim] down!"), span_danger("[user] pins me down!"))
				user.ai_root.blackboard[AIBLK_IS_PINNING] = TRUE
				user.ai_root.blackboard[AIBLK_RESTRAIN_STATE] = GOB_RESTRAIN_STATE_PINNED
				return NODE_RUNNING
			else
				if(!on_cooldown)
					user.ai_root.next_attack_tick = world.time + (user.ai_root.next_attack_delay || 10)
					G.attack(victim, user)
					if(victim.IsParalyzed())
						user.ai_root.blackboard[AIBLK_IS_PINNING] = TRUE
						user.ai_root.blackboard[AIBLK_RESTRAIN_STATE] = GOB_RESTRAIN_STATE_PINNED
				return NODE_RUNNING

		if(GOB_RESTRAIN_STATE_PINNED)
			if(get_turf(user) != get_turf(victim))
				position_for_sex(user, victim)

			if(!G)
				// Lost the grab, reset
				user.ai_root.blackboard[AIBLK_RESTRAIN_STATE] = GOB_RESTRAIN_STATE_NONE
				return NODE_RUNNING

			if(!victim.IsParalyzed())
				// Unpin
				user.ai_root.blackboard[AIBLK_IS_PINNING] = FALSE
				user.ai_root.blackboard[AIBLK_RESTRAIN_STATE] = GOB_RESTRAIN_STATE_PINNING
				return NODE_RUNNING
			
			return NODE_SUCCESS

	return NODE_RUNNING


// ------------------------------------------------------------------------------
// SQUAD TACTICS - STRIP ARMOR (for normal enemies)
// ------------------------------------------------------------------------------

/bt_action/goblin_strip_armor/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(!ishuman(user) || !ishuman(target))
		return NODE_FAILURE

	var/mob/living/carbon/human/victim = target
	if(QDELETED(victim) || victim.stat == DEAD)
		return NODE_FAILURE

	// Only strippers should do this
	var/role = user.ai_root.blackboard[AIBLK_SQUAD_ROLE]
	if(role != GOB_SQUAD_ROLE_STRIPPER)
		return NODE_SUCCESS // Not our job

	// Check if victim is incapacitated
	if(!victim.incapacitated())
		return NODE_FAILURE // Can't strip while fighting back

	// Must be adjacent
	var/move_result = move_adjacent_to(user, victim)
	if(move_result)
		return move_result

	// Priority: Helmet > Chest Armor > Gloves > Boots
	var/obj/item/clothing/to_strip = null
	var/list/armor_slots = list(SLOT_HEAD, SLOT_ARMOR, SLOT_GLOVES, SLOT_SHOES)

	for(var/slot in armor_slots)
		var/obj/item/clothing/armor = victim.get_item_by_slot(slot)
		if(armor)
			// Check if it's actually armor worth stripping
			if(istype(armor) && armor.armor_class >= ARMOR_CLASS_LIGHT)
				to_strip = armor
				break

	if(to_strip)
		if(user.doing) return NODE_RUNNING

		user.visible_message(span_danger("[user] starts tearing \the [to_strip] off of [victim]!"))
		if(do_mob(user, victim, 30))
			// Re-verify item is still equipped after the delay
			if(to_strip && to_strip.loc == victim)
				victim.dropItemToGround(to_strip)
				to_strip.throw_at(get_ranged_target_turf(user, pick(GLOB.alldirs), 3), 3, 1)
		// Always return RUNNING to re-evaluate and find next item (or determine we're done)
		return NODE_RUNNING

	// No armor left - for MONSTER_BAIT, keep the sequence running so we don't fall through to attacking
	if(user.ai_root.blackboard[AIBLK_MONSTER_BAIT] == victim)
		return NODE_RUNNING // Stay in squad tactics, don't fall through

	return NODE_SUCCESS // For normal enemies, we're done

// ------------------------------------------------------------------------------
// SQUAD TACTICS - ATTACKER ASSISTS WITH RESTRAINING MONSTER_BAIT
// ------------------------------------------------------------------------------

/bt_action/goblin_assist_restrain/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(!ishuman(user) || !ishuman(target))
		return NODE_FAILURE

	var/mob/living/carbon/human/victim = target
	if(QDELETED(victim) || victim.stat == DEAD)
		return NODE_FAILURE

	// Get current grab state
	var/obj/item/grabbing/G = user.get_active_held_item()
	if(!istype(G) || G.grabbed != victim)
		G = user.get_inactive_held_item()
		if(!istype(G) || G.grabbed != victim)
			G = null

	// Check if we should assist
	if(!can_assist(user, victim))
		// Clean up - drop grab if we have one
		if(G)
			user.stop_pulling()
		return NODE_FAILURE // Not our job or job is done

	// Already grabbing - maintain it
	if(G)
		return NODE_RUNNING

	// Execute: Establish grab
	// Step 1: Stow weapon
	var/obj/item/held = user.get_active_held_item()
	if(held)
		if(!user.place_in_inventory(held))
			user.dropItemToGround(held)
		return NODE_RUNNING

	// Step 2: Move adjacent
	var/move_result = move_adjacent_to(user, victim)
	if(move_result)
		return move_result

	// Step 3: Check cooldown
	if(world.time < user.ai_root.next_attack_tick)
		return NODE_RUNNING

	// Step 4: Grab
	if(user.select_intent_and_attack(INTENT_GRAB, victim))
		return NODE_RUNNING

	return NODE_FAILURE

// Helper: Should this goblin assist with restraining?
/bt_action/goblin_assist_restrain/proc/can_assist(mob/living/carbon/human/user, mob/living/carbon/human/victim)
	// Only non-restrainer roles assist
	var/role = user.ai_root.blackboard[AIBLK_SQUAD_ROLE]
	if(role == GOB_SQUAD_ROLE_RESTRAINER)
		return FALSE

	// Only help with MONSTER_BAIT targets
	if(user.ai_root.blackboard[AIBLK_MONSTER_BAIT] != victim)
		return FALSE

	// Once victim is knocked down, our assist job is done
	if(victim.IsKnockdown() || victim.IsParalyzed())
		return FALSE

	return TRUE

// ------------------------------------------------------------------------------
// SQUAD TACTICS - ATTACK VITALS (after armor stripped)
// ------------------------------------------------------------------------------

/bt_action/goblin_attack_vitals/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(!ishuman(user) || !ishuman(target))
		return NODE_FAILURE

	var/mob/living/carbon/human/victim = target
	if(QDELETED(victim) || victim.stat == DEAD)
		return NODE_FAILURE

	// Only attackers should do this
	var/role = user.ai_root.blackboard[AIBLK_SQUAD_ROLE]
	if(role != GOB_SQUAD_ROLE_ATTACKER)
		return NODE_SUCCESS // Not our job

	// Don't attack MONSTER_BAIT - that's handled by violation sequence
	if(user.ai_root.blackboard[AIBLK_MONSTER_BAIT] == victim)
		return NODE_SUCCESS // Not our job for MONSTER_BAIT

	// Check if victim has any armor left
	if(has_armor_equipped(victim))
		return NODE_FAILURE // Wait for strippers to finish

	// Target vitals - use targeted attacks
	if(!user.ai_root || world.time < user.ai_root.next_attack_tick)
		return NODE_RUNNING

	// Must be adjacent
	var/move_result = move_adjacent_to(user, victim)
	if(move_result)
		return move_result

	// Attack with targeted zone
	user.face_atom(victim)
	user.zone_selected = pick(BODY_ZONE_HEAD, BODY_ZONE_CHEST, BODY_ZONE_PRECISE_GROIN)
	npc_click_on(user, victim)
	user.ai_root.next_attack_tick = world.time + (user.ai_root.next_attack_delay || 10)

	return NODE_RUNNING

// ------------------------------------------------------------------------------
// SQUAD TACTICS - MULTI-GOBLIN VIOLATION (for MONSTER_BAIT)
// ------------------------------------------------------------------------------

/bt_action/goblin_squad_violate/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(!ishuman(user))
		return NODE_FAILURE

	var/mob/living/carbon/human/victim = user.ai_root.blackboard[AIBLK_MONSTER_BAIT]
	if(!victim || QDELETED(victim) || victim.stat == DEAD)
		// Clear invalid target
		user.ai_root.blackboard -= AIBLK_MONSTER_BAIT
		user.ai_root.target = null
		return NODE_FAILURE

	var/role = user.ai_root.blackboard[AIBLK_SQUAD_ROLE]

	// Only violators and restrainers (who pinned) participate
	// Check if this goblin is the one pinning
	var/is_pinning = user.ai_root.blackboard[AIBLK_IS_PINNING]

	if(role != GOB_SQUAD_ROLE_VIOLATOR && !is_pinning)
		return NODE_SUCCESS // Not our job

	// Wait for victim to be incapacitated by restrainer
	if(!victim.incapacitated())
		// Move adjacent while waiting
		var/move_result = move_adjacent_to(user, victim)
		if(move_result)
			return move_result
		return NODE_RUNNING // Wait for restrainer to pin

	// Must be adjacent
	var/move_result = move_adjacent_to(user, victim)
	if(move_result)
		return move_result

	// Check if other goblins are already violating
	var/list/squad_mates = user.ai_root.blackboard[AIBLK_SQUAD_MATES]
	var/others_violating = 0
	var/we_are_primary = is_pinning

	if(squad_mates)
		for(var/mob/living/carbon/human/G as anything in squad_mates)
			if(!G.ai_root) continue
			if(G.ai_root.blackboard[AIBLK_SQUAD_ROLE] != GOB_SQUAD_ROLE_VIOLATOR) continue

			// Check if they're actively violating
			if(G.sexcon && !G.sexcon.is_spent() && G.sexcon.target == victim)
				others_violating++
				we_are_primary = FALSE // Someone else is primary

	// Random chance for additional violators to join (low chance)
	if(!we_are_primary && others_violating > 0)
		// 50% chance for second violator, 10% for third
		var/join_chance = others_violating == 1 ? 50 : 10
		if(!prob(join_chance))
			return NODE_SUCCESS // Don't join

	if(user.doing) return NODE_RUNNING

	if(user.sexcon.is_spent())
		user.sexcon.stop_current_action()
		return NODE_SUCCESS // Finished

	// Set up for violation
	if(user.getorganslot(ORGAN_SLOT_PENIS) && !user.sexcon.is_spent())
		user.sexcon.set_target(victim)
		user.sexcon.update_all_accessible_body_zones()
		victim.sexcon.update_all_accessible_body_zones()

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

		if(!user.ai_root.blackboard[AIBLK_S_ACTION])
			var/used_zone = action_path == /datum/sex_action/force_blowjob ? BODY_ZONE_PRECISE_MOUTH : BODY_ZONE_PRECISE_GROIN
			var/used_bitflag = used_zone == BODY_ZONE_PRECISE_MOUTH ? MOUTH : GROIN
				
			if(!action.check_location_accessible(user, user, used_zone))
				user.visible_message(span_warning("[user] starts stripping [user.p_their()] own clothing!"))
				if(do_mob(user, user, 30))
					var/stripped = FALSE
					var/list/stripping_candidates = list()
					// Strip self
					for(var/obj/I as anything in user.get_blocking_equipment(used_bitflag))
						stripping_candidates += I

					for(var/obj/item/I as anything in stripping_candidates)
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
					for(var/obj/item/I as anything in victim.get_blocking_equipment(used_bitflag))
						stripping_candidates += I

					for(var/obj/item/I as anything in stripping_candidates)
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
				else
					return NODE_RUNNING // do_mob was interrupted

			position_for_sex(user, victim)

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


// ------------------------------------------------------------------------------
// SUBDUE / DRAG LOGIC
// ------------------------------------------------------------------------------

/bt_action/goblin_drag_away
	var/min_drag_dist = 10
	var/blackboard_key = "drag_start_loc"

/bt_action/goblin_drag_away/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	var/mob/living/carbon/victim = user.ai_root.blackboard[AIBLK_MONSTER_BAIT]
	
	if(!victim || victim.stat == DEAD)
		user.ai_root.blackboard -= blackboard_key
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
		npc_click_on(user, victim)
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
			if(isgoblin(L)) continue
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
		user.ai_root.blackboard -= AIBLK_MONSTER_BAIT
		user.ai_root.blackboard -= AIBLK_SQUAD_PRIORITY_TARGET
		user.ai_root.blackboard -= AIBLK_DRAG_START_LOC
		
		// Add to ignore list
		var/list/ignored = user.ai_root.blackboard[AIBLK_IGNORED_TARGETS] ? user.ai_root.blackboard[AIBLK_IGNORED_TARGETS] : list()

		ignored[victim] = world.time
		user.ai_root.blackboard[AIBLK_IGNORED_TARGETS] = ignored
		
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
	if(!victim.incapacitated())
		return NODE_FAILURE

	// Check for weapons to strip - Prioritize hands -> Belt -> Back
	var/obj/item/to_strip = victim.get_active_held_item()
	if(!to_strip) to_strip = victim.get_inactive_held_item()
	if(!to_strip) to_strip = victim.get_item_by_slot(SLOT_BELT)
	if(!to_strip) to_strip = victim.get_item_by_slot(SLOT_BACK)

	if(to_strip)
		// Only strip if it's a weapon (arbitrary check: force > 0)
		if(to_strip.force > 0 || istype(to_strip, /obj/item/gun) || istype(to_strip, /obj/item/rogueweapon))

			// Must be adjacent
			var/move_result = move_adjacent_to(user, victim)
			if(move_result)
				return move_result

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

// ------------------------------------------------------------------------------
// CAPTIVE HANDLING
// ------------------------------------------------------------------------------

/bt_action/goblin_attack_check/evaluate(mob/living/carbon/human/user, mob/living/target, list/blackboard)
	if(!ishuman(target))
		return NODE_SUCCESS
	if(target && (target.restrained()))
		return NODE_FAILURE

	var/list/ignored = user.ai_root.blackboard[AIBLK_IGNORED_TARGETS]
	if(ignored && ignored[target])
		return NODE_FAILURE

	return NODE_SUCCESS
