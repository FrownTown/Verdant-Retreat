// ==============================================================================
// ROGUETOWN BEHAVIOR TREE ACTIONS
// ==============================================================================

// ------------------------------------------------------------------------------
// TARGETING
// ------------------------------------------------------------------------------

/bt_action/list_targets
	var/search_range = 7

/bt_action/list_targets/evaluate(mob/living/user, mob/living/target, list/blackboard)
	if(!user.ai_root)
		return NODE_FAILURE

	var/mob/living/simple_animal/hostile/H = user
	if(!istype(H))
		return NODE_FAILURE

	var/list/targets = list()
	if(!H.search_objects)
		targets = get_nearby_entities(H, search_range)
	else
		var/list/candidates = get_nearby_entities(H, search_range)
		for(var/mob/living/L in candidates)
			if(!los_blocked(H, L))
				targets += L

	user.ai_root.blackboard["possible_targets"] = targets
	return length(targets) ? NODE_SUCCESS : NODE_FAILURE

/bt_action/found_target

/bt_action/found_target/evaluate(mob/living/user, mob/living/target, list/blackboard)
	if(!target || !isliving(target))
		return NODE_FAILURE

	var/mob/living/living_target = target
	if(living_target.alpha == 0 && living_target.rogue_sneaking || world.time < living_target.mob_timers[MT_INVISIBILITY])
		var/mob/living/simple_animal/hostile/H = user
		if(istype(H) && H.npc_detect_sneak(living_target, H.simple_detect_bonus))
			return NODE_SUCCESS
		return NODE_FAILURE
	return NODE_SUCCESS

/bt_action/can_attack

/bt_action/can_attack/evaluate(mob/living/user, mob/living/target, list/blackboard)
	if(!user.ai_root)
		return NODE_FAILURE

	var/mob/living/simple_animal/hostile/H = user
	if(!istype(H))
		return NODE_FAILURE

	var/atom/the_target = target
	if(!the_target)
		var/atom/check_target = user.ai_root.blackboard["check_target"]
		if(!check_target)
			return NODE_FAILURE
		the_target = check_target

	if(isturf(the_target) || !the_target || the_target.type == /atom/movable/lighting_object)
		return FALSE

	if(H.binded)
		return FALSE

	if(ismob(the_target))
		var/mob/M = the_target
		if(world.time < M.mob_timers[MT_INVISIBILITY])
			return FALSE
		if(M.status_flags & GODMODE)
			return FALSE
		if(M.name in H.friends)
			return FALSE

	if(H.see_invisible < the_target.invisibility)
		return FALSE

	if(H.search_objects < 2)
		if(isliving(the_target))
			var/mob/living/L = the_target
			var/faction_check = H.faction_check_mob(L)
			if(H.robust_searching)
				if(faction_check && !H.attack_same)
					return FALSE
				if(L.stat > H.stat_attack)
					return FALSE
			else
				if((faction_check && !H.attack_same) || L.stat)
					return FALSE
			return TRUE

	if(isobj(the_target))
		if(H.attack_all_objects || is_type_in_typecache(the_target, H.wanted_objects))
			return TRUE

	return FALSE

/bt_action/pick_target

/bt_action/pick_target/evaluate(mob/living/user, mob/living/target, list/blackboard)
	if(!user.ai_root)
		return NODE_FAILURE

	var/list/valid_targets = user.ai_root.blackboard["valid_targets"]
	if(!valid_targets || !valid_targets.len)
		return NODE_FAILURE

	var/mob/living/simple_animal/hostile/H = user
	if(!istype(H))
		return NODE_FAILURE

	if(target != null)
		for(var/pos_targ in valid_targets)
			var/atom/A = pos_targ
			var/target_dist = get_dist(H.targets_from, target)
			var/possible_target_distance = get_dist(H.targets_from, A)
			if(target_dist < possible_target_distance)
				valid_targets -= A

	if(!valid_targets.len)
		return NODE_FAILURE

	var/chosen_target = pick(valid_targets)
	user.ai_root.blackboard["chosen_target"] = chosen_target
	return NODE_SUCCESS

/bt_action/give_target

/bt_action/give_target/evaluate(mob/living/user, mob/living/target, list/blackboard)
	if(!user.ai_root)
		return NODE_FAILURE

	var/new_target = user.ai_root.blackboard["chosen_target"]
	if(!new_target)
		return NODE_FAILURE

	var/mob/living/simple_animal/hostile/H = user
	if(!istype(H))
		return NODE_FAILURE

	user.ai_root.target = new_target

	H.LosePatience()
	if(new_target != null)
		H.GainPatience()
		H.last_aggro_loss = 0

		H.vision_range = H.aggro_vision_range
	
		if(H.ai_root.next_emote_tick >= world.time)
			if(new_target && H.emote_taunt.len && prob(H.taunt_chance))
				H.emote("me", 1, "[pick(H.emote_taunt)] at [new_target].")
				H.taunt_chance = max(H.taunt_chance-7,2)
			H.emote("aggro")

			var/next_emote = H.ai_root.next_emote_delay ? H.ai_root.next_emote_delay : AI_DEFAULT_EMOTE_DELAY
			H.ai_root.next_emote_tick = world.time + next_emote

	return NODE_SUCCESS

/bt_action/find_target

/bt_action/find_target/evaluate(mob/living/user, mob/living/target, list/blackboard)
	if(!user.ai_root)
		return NODE_FAILURE

	var/mob/living/simple_animal/hostile/H = user
	if(!istype(H))
		return NODE_FAILURE

	if(H.search_objects >= 2)
		return NODE_FAILURE

	var/list/possible_targets = list()
	if(!H.search_objects)
		possible_targets = hearers(H.vision_range, H.targets_from) - H
	else
		possible_targets = oview(H.vision_range, H.targets_from)

	if(istype(H, /mob/living/simple_animal/hostile/retaliate))
		var/mob/living/simple_animal/hostile/retaliate/R = H
		if(!R.aggressive && R.enemies.len)
			possible_targets &= R.enemies
		else if(!R.aggressive)
			possible_targets = list()

	var/list/valid_targets = list()
	// Transient helper for filtering
	var/bt_action/can_attack/can_attack_check = new

	for(var/pos_targ in possible_targets)
		var/atom/A = pos_targ

		if(isliving(A))
			var/mob/living/living_target = A
			if(living_target.alpha == 0 && living_target.rogue_sneaking || world.time < living_target.mob_timers[MT_INVISIBILITY])
				if(H.npc_detect_sneak(living_target, H.simple_detect_bonus))
					valid_targets = list(A)
					break
				else
					continue

		user.ai_root.blackboard["check_target"] = A
		if(can_attack_check.evaluate(user, null, user.ai_root.blackboard) == NODE_SUCCESS)
			valid_targets += A
			continue
	
	qdel(can_attack_check)

	if(!valid_targets.len)
		return NODE_FAILURE

	if(target != null)
		for(var/pos_targ in valid_targets)
			var/atom/A = pos_targ
			var/target_dist = get_dist(H.targets_from, target)
			var/possible_target_distance = get_dist(H.targets_from, A)
			if(target_dist < possible_target_distance)
				valid_targets -= A

	if(!valid_targets.len)
		return NODE_FAILURE

	var/chosen_target = pick(valid_targets)
	if(chosen_target)
		user.ai_root.target = chosen_target

		H.LosePatience()
		H.GainPatience()
		H.last_aggro_loss = 0

		H.vision_range = H.aggro_vision_range
		if(chosen_target && H.emote_taunt.len && prob(H.taunt_chance))
			H.emote("me", 1, "[pick(H.emote_taunt)] at [chosen_target].")
			H.taunt_chance = max(H.taunt_chance-7,2)
		H.emote("aggro")

		return NODE_SUCCESS

	return NODE_FAILURE

/bt_action/has_target/evaluate(mob/living/user, mob/living/target, list/blackboard)
	if(target && target.stat != DEAD && get_dist(user, target) <= 9) // simple range check
		return NODE_SUCCESS
	if(user.ai_root)
		user.ai_root.target = null // Clear invalid target
	return NODE_FAILURE

/bt_action/target_in_range
	var/range = 1

/bt_action/target_in_range/evaluate(mob/living/user, mob/living/target, list/blackboard)
	if(target && get_dist(user, target) <= range)
		return NODE_SUCCESS
	return NODE_FAILURE

// ------------------------------------------------------------------------------
// AGGRO/DEAGGRO
// ------------------------------------------------------------------------------

/bt_action/lose_aggro

/bt_action/lose_aggro/evaluate(mob/living/user, mob/living/target, list/blackboard)
	var/mob/living/simple_animal/hostile/H = user
	if(!istype(H))
		return NODE_FAILURE

	H.vision_range = initial(H.vision_range)
	H.taunt_chance = initial(H.taunt_chance)
	return NODE_SUCCESS

/bt_action/lose_target

/bt_action/lose_target/evaluate(mob/living/user, mob/living/target, list/blackboard)
	var/mob/living/simple_animal/hostile/H = user
	if(!istype(H))
		return NODE_FAILURE

	if(target)
		H.last_aggro_loss = world.time

	if(user.ai_root)
		user.ai_root.target = null
		user.set_ai_path_to(null)

	H.approaching_target = FALSE
	H.in_melee = FALSE

	H.vision_range = initial(H.vision_range)
	H.taunt_chance = initial(H.taunt_chance)

	return NODE_SUCCESS

// ------------------------------------------------------------------------------
// MOVEMENT
// ------------------------------------------------------------------------------

/bt_action/move_to_destination

/bt_action/move_to_destination/evaluate(mob/living/user, atom/target, list/blackboard)
	if(!user.ai_root)
		return NODE_FAILURE

	var/atom/destination = user.ai_root.move_destination
	if(!destination)
		// If we have a target but no move_destination, maybe we should set it?
		// But this action implies we are already moving towards a destination set by another node (like find_food).
		// If that node set ai_root.move_destination, we just continue.
		if(target && target != user)
			user.set_ai_path_to(target)
			return NODE_RUNNING
		return NODE_FAILURE

	if(get_dist(user, destination) <= 1 || user.loc == destination.loc)
		user.set_ai_path_to(null)
		return NODE_SUCCESS

	// Path is already set by set_ai_path_to in the previous node (e.g. find_food)
	// We just ensure we are still running.
	if(length(user.ai_root.path))
		return NODE_RUNNING
	
	// If path is empty but we are not there, try repathing
	if(user.set_ai_path_to(destination))
		return NODE_RUNNING

	return NODE_FAILURE

/bt_action/dreamfiend_blink
	var/blink_range = 5

/bt_action/dreamfiend_blink/evaluate(mob/living/user, mob/living/target, list/blackboard)
	if(!target || get_dist(user, target) > blink_range)
		return NODE_FAILURE
	
	// Blink logic
	var/turf/T = get_step(target, get_dir(target, user)) 
	if(!T || T.density)
		T = get_turf(target)
	
	if(T)
		do_teleport(user, T, 0, asoundin = 'sound/magic/blink.ogg', channel = TELEPORT_CHANNEL_MAGIC)
		return NODE_SUCCESS
		
	return NODE_FAILURE

/bt_action/escape_confinement

/bt_action/escape_confinement/evaluate(mob/living/user, mob/living/target, list/blackboard)
	var/mob/living/simple_animal/hostile/H = user
	if(!istype(H))
		return NODE_FAILURE

	if(H.buckled)
		H.buckled.attack_animal(H)
		return NODE_SUCCESS

	if(!H.targets_from.loc)
		return NODE_FAILURE

	if(!isturf(H.targets_from.loc))
		var/atom/A = H.targets_from.loc
		A.attack_animal(H)
		return NODE_SUCCESS

	return NODE_FAILURE

/bt_action/destroy_path

/bt_action/destroy_path/evaluate(mob/living/user, mob/living/target, list/blackboard)
	var/mob/living/simple_animal/hostile/H = user
	if(!istype(H) || !target)
		return NODE_FAILURE

	if(!H.environment_smash)
		return NODE_FAILURE

	var/dir_to_target = get_dir(H.targets_from, target)

	var/turf/V = get_turf(H)
	for (var/obj/structure/O in V.contents)
		if(isstructure(O) && !(O in H.favored_structures))
			O.attack_animal(H)
			return NODE_SUCCESS

	var/list/dir_list = list()
	if(dir_to_target in GLOB.diagonals)
		for(var/direction in GLOB.cardinals)
			if(direction & dir_to_target)
				dir_list += direction
	else
		dir_list += dir_to_target

	for(var/direction in dir_list)
		var/turf/T = get_step(H.targets_from, direction)
		if(QDELETED(T))
			continue
		if(T.Adjacent(H.targets_from))
			if(H.CanSmashTurfs(T))
				T.attack_animal(H)
				return NODE_SUCCESS
		for(var/obj/O in T.contents)
			if(!O.Adjacent(H.targets_from))
				continue
			if(O in H.favored_structures)
				continue
			if((ismachinery(O) || isstructure(O)) && H.environment_smash >= ENVIRONMENT_SMASH_STRUCTURES && !O.IsObscured())
				O.attack_animal(H)
				return NODE_SUCCESS

	for(var/obj/structure/O in get_step(H, dir_to_target))
		if(O.density && O.climbable)
			O.climb_structure(H)
			return NODE_SUCCESS

	return NODE_FAILURE

/bt_action/find_hidden

/bt_action/find_hidden/evaluate(mob/living/user, mob/living/target, list/blackboard)
	var/mob/living/simple_animal/hostile/H = user
	if(!istype(H) || !target)
		return NODE_FAILURE

	if(istype(target.loc, /obj/structure/closet))
		var/atom/A = target.loc
		
		// Movement logic for hidden find
		if(user.set_ai_path_to(A))
			if(A.Adjacent(H.targets_from))
				A.attack_animal(H)
				return NODE_SUCCESS
			return NODE_RUNNING

	return NODE_FAILURE

/bt_action/move_to_target

/bt_action/move_to_target/evaluate(mob/living/user, mob/living/target, list/blackboard)
	if(!user || !target)
		return NODE_FAILURE

	var/mob/living/simple_animal/hostile/H = user
	if(istype(H))
		H.stop_automated_movement = 1

	if(user.Adjacent(target))
		if(user.ai_root)
			user.ai_root.path = null
		return NODE_SUCCESS

	var/atom/move_dest = target
	
	// Retreat Logic
	if(istype(H) && H.retreat_distance != null && get_dist(H.targets_from, target) <= H.retreat_distance)
		var/dir_away = get_dir(target, H)
		var/turf/potential_flee = get_ranged_target_turf(H, dir_away, H.retreat_distance)
		if(potential_flee)
			move_dest = potential_flee
		
	if(user.set_ai_path_to(move_dest))
		return NODE_RUNNING

	return NODE_FAILURE

/bt_action/idle_wander/evaluate(mob/living/user, mob/living/target, list/blackboard)
	if(istype(user, /mob/living/simple_animal))
		var/mob/living/simple_animal/SA = user
		if(!SA.wander)
			return NODE_FAILURE

	if(user.ai_root && world.time >= user.ai_root.next_move_tick)
		var/turf/T = get_step(user, pick(GLOB.cardinals))
		if(T && !T.density)
			if(user.set_ai_path_to(T))
				return NODE_RUNNING 
		
		return NODE_FAILURE
	
	return NODE_RUNNING

/bt_action/flee_target
	var/run_distance = 8
	var/until_destination = FALSE

/bt_action/flee_target/evaluate(mob/living/user, mob/living/target, list/blackboard)
	if(!target)
		return NODE_FAILURE
	
	var/escaped = QDELETED(target) || !can_see(user, target, run_distance)
	if(escaped)
		user.set_ai_path_to(null)
		return NODE_SUCCESS
		
	if(until_destination && user.ai_root && user.ai_root.move_destination)
		if(get_dist(user, user.ai_root.move_destination) <= 1)
			user.set_ai_path_to(null)
			return NODE_SUCCESS
		return NODE_RUNNING
		
	var/turf/target_destination = get_turf(user)
	var/static/list/offset_angles = list(45, 90, 135, 180, 225, 270)
	
	var/best_dest = target_destination
	
	for(var/angle in offset_angles)
		var/turf/test_turf = get_furthest_turf(user, angle, target)
		if(isnull(test_turf))
			continue
		var/distance_from_target = get_dist(target, test_turf)
		if(distance_from_target <= get_dist(target, best_dest))
			continue
		best_dest = test_turf
		if(distance_from_target == run_distance)
			break
			
	if(best_dest == get_turf(user))
		return NODE_FAILURE
		
	if(user.set_ai_path_to(best_dest))
		return NODE_RUNNING
		
	return NODE_FAILURE

/bt_action/flee_target/proc/get_furthest_turf(atom/source, angle, atom/target)
	var/turf/return_turf
	for(var/i in 1 to run_distance)
		var/turf/test_destination = get_ranged_target_turf_direct(source, target, range = i, offset = angle)
		if(is_blocked_turf(test_destination, exclude_mobs = !source.density))
			break
		return_turf = test_destination
	return return_turf


/bt_action/set_move_target_key
	var/blackboard_key
	
/bt_action/set_move_target_key/evaluate(mob/living/user, mob/living/target, list/blackboard)
	if(!user.ai_root)
		return NODE_FAILURE
	
	var/atom/dest = user.ai_root.blackboard[blackboard_key]
	if(!dest || QDELETED(dest))
		return NODE_FAILURE
		
	user.set_ai_path_to(dest)
	return NODE_SUCCESS


// ------------------------------------------------------------------------------
// COMBAT
// ------------------------------------------------------------------------------

/bt_action/melee_action

/bt_action/melee_action/evaluate(mob/living/user, mob/living/target, list/blackboard)
	var/mob/living/simple_animal/hostile/H = user
	if(!istype(H) || !target)
		return NODE_FAILURE

	if(H.binded)
		return NODE_FAILURE

	if(H.rapid_melee > 1)
		var/datum/callback/cb = CALLBACK(H, TYPE_PROC_REF(/mob/living/simple_animal/hostile, CheckAndAttack))
		var/delay = SSnpcpool.wait / H.rapid_melee
		for(var/i in 1 to H.rapid_melee)
			addtimer(cb, (i - 1)*delay)
	else
		if(SEND_SIGNAL(H, COMSIG_HOSTILE_PRE_ATTACKINGTARGET, target) & COMPONENT_HOSTILE_NO_PREATTACK)
			return NODE_FAILURE
		SEND_SIGNAL(H, COMSIG_HOSTILE_ATTACKINGTARGET, target)
		H.in_melee = TRUE
		if(!QDELETED(target))
			target.attack_animal(H)

	H.GainPatience()
	return NODE_SUCCESS

/bt_action/attack_melee/evaluate(mob/living/user, mob/living/target, list/blackboard)
	if(!target)
		return NODE_FAILURE

	var/mob/living/simple_animal/hostile/H = user
	if(istype(H))
		if(H.binded)
			return NODE_FAILURE
		if(SEND_SIGNAL(H, COMSIG_HOSTILE_PRE_ATTACKINGTARGET, target) & COMPONENT_HOSTILE_NO_PREATTACK)
			return NODE_FAILURE
		SEND_SIGNAL(H, COMSIG_HOSTILE_ATTACKINGTARGET, target)
		H.in_melee = TRUE

	if(user.ai_root && world.time >= user.ai_root.next_attack_tick)
		if(!QDELETED(target))
			target.attack_animal(user)
		user.ai_root.next_attack_tick = world.time + (user.ai_root.next_attack_delay || 10)
		return NODE_SUCCESS

	return NODE_RUNNING

/bt_action/check_friendly_fire

/bt_action/check_friendly_fire/evaluate(mob/living/user, mob/living/target, list/blackboard)
	var/mob/living/simple_animal/hostile/H = user
	if(!istype(H) || !target)
		return NODE_FAILURE

	if(!H.check_friendly_fire)
		return NODE_FAILURE

	for(var/turf/T in getline(H, target))
		for(var/mob/living/L in T)
			if(L == H || L == target)
				continue
			if(H.faction_check_mob(L) && !H.attack_same)
				return NODE_SUCCESS

	return NODE_FAILURE

/bt_action/use_ability
	var/ability_key = "targeted_action"

/bt_action/use_ability/evaluate(mob/living/user, mob/living/target, list/blackboard)
	if(!user.ai_root)
		return NODE_FAILURE

	var/datum/action/cooldown/ability = user.ai_root.blackboard[ability_key]
	if(!ability)
		return NODE_FAILURE
	if(!target)
		return NODE_FAILURE
	if(ability.IsAvailable())
		ability.Trigger(target = target)
		return NODE_SUCCESS
	return NODE_FAILURE

/bt_action/attack_ranged

/bt_action/attack_ranged/evaluate(mob/living/user, mob/living/target, list/blackboard)
	if(!target)
		return NODE_FAILURE

	var/mob/living/simple_animal/hostile/H = user
	if(!istype(H))
		return NODE_FAILURE

	if(H.binded)
		return NODE_FAILURE

	if(H.ranged_cooldown > world.time)
		return NODE_RUNNING

	if(H.check_friendly_fire)
		for(var/turf/T in getline(H, target))
			for(var/mob/living/L in T)
				if(L == H || L == target)
					continue
				if(H.faction_check_mob(L) && !H.attack_same)
					return NODE_FAILURE

	H.visible_message(span_danger("<b>[H]</b> [H.ranged_message] at [target]!"))

	if(H.rapid > 1)
		var/datum/callback/cb = CALLBACK(H, TYPE_PROC_REF(/mob/living/simple_animal/hostile, Shoot), target)
		for(var/i in 1 to H.rapid)
			addtimer(cb, (i - 1)*H.rapid_fire_delay)
	else
		if(QDELETED(target) || target == H.targets_from.loc || target == H.targets_from)
			return NODE_FAILURE
		var/turf/startloc = get_turf(H.targets_from)
		if(H.casingtype)
			var/obj/item/ammo_casing/casing = new H.casingtype(startloc)
			playsound(H, H.projectilesound, 100, TRUE)
			casing.fire_casing(target, H, null, null, null, ran_zone(), 0, H)
		else if(H.projectiletype)
			var/obj/projectile/P = new H.projectiletype(startloc)
			playsound(H, H.projectilesound, 100, TRUE)
			P.starting = startloc
			P.firer = H
			P.fired_from = H
			P.yo = target.y - startloc.y
			P.xo = target.x - startloc.x
			if(H.AIStatus != AI_ON)
				H.newtonian_move(get_dir(target, H.targets_from))
			P.original = target
			P.preparePixelProjectile(target, H)
			P.fire()

	H.ranged_cooldown = world.time + H.ranged_cooldown_time
	return NODE_SUCCESS

// ------------------------------------------------------------------------------
// SCAVENGING
// ------------------------------------------------------------------------------

/bt_action/check_hunger
	var/hunger_key = "next_hunger_check"
	
/bt_action/check_hunger/evaluate(mob/living/user, mob/living/target, list/blackboard)
	if(!user.ai_root)
		return NODE_FAILURE

	var/next_eat = user.ai_root.blackboard[hunger_key]
	if(!next_eat)
		next_eat = world.time + rand(0, 30 SECONDS)
		user.ai_root.blackboard[hunger_key] = next_eat
		
	if(world.time < next_eat)
		return NODE_FAILURE // Not hungry yet
		
	return NODE_SUCCESS

/bt_action/find_food
	var/search_range = 5

/bt_action/find_food/evaluate(mob/living/user, mob/living/target, list/blackboard)
	if(!user.ai_root)
		return NODE_FAILURE

	var/mob/living/simple_animal/SA = user
	if(!istype(SA) || !SA.food_type)
		return NODE_FAILURE

	// Check if we already have valid food target
	var/atom/current_food = user.ai_root.blackboard["food_target"]
	if(current_food && !QDELETED(current_food) && get_dist(user, current_food) <= search_range)
		if(current_food.loc) // Ensure it's still in the world
			return NODE_SUCCESS
	
	user.ai_root.blackboard["food_target"] = null

	for(var/atom/movable/A in view(search_range, user))
		if(SA.food_type && is_type_in_list(A, SA.food_type))
			user.ai_root.blackboard["food_target"] = A
			return NODE_SUCCESS
	
	return NODE_FAILURE

/bt_action/eat_food/evaluate(mob/living/user, mob/living/target, list/blackboard)
	if(!user.ai_root)
		return NODE_FAILURE

	var/atom/movable/food = user.ai_root.blackboard["food_target"]
	if(!food || QDELETED(food))
		return NODE_FAILURE
	
	if(get_dist(user, food) > 1)
		// Also set move destination for move_to_destination action
		user.ai_root.move_destination = food
		return NODE_FAILURE 
	
	// Eat it
	user.visible_message(span_notice("[user] eats [food]."))
	playsound(user, 'sound/misc/eat.ogg', 50, TRUE)
	qdel(food)
	user.ai_root.blackboard["food_target"] = null
	
	// Reset hunger timer
	user.ai_root.blackboard["next_hunger_check"] = world.time + rand(60 SECONDS, 120 SECONDS)
	
	// Heal or restore nutrition if applicable
	if(istype(user, /mob/living/simple_animal))
		var/mob/living/simple_animal/SA = user
		SA.food = min(SA.food + 30, 100)
		SA.adjustHealth(-5) // Small heal from eating

	return NODE_SUCCESS

/bt_action/find_and_set
	var/blackboard_key
	var/locate_path
	var/search_range = 7
	var/check_hands = FALSE
	
/bt_action/find_and_set/evaluate(mob/living/user, mob/living/target, list/blackboard)
	if(!user.ai_root)
		return NODE_FAILURE

	if(!blackboard_key || !locate_path)
		return NODE_FAILURE
		
	var/found_thing = null
	
	if(check_hands)
		if(locate(locate_path) in user.held_items)
			found_thing = locate(locate_path) in user.held_items
	
	if(!found_thing)
		var/list/candidates = view(search_range, user)
		var/list/valid = list()
		for(var/atom/A in candidates)
			if(istype(A, locate_path))
				valid += A
		if(length(valid))
			found_thing = pick(valid)
			
	if(found_thing)
		user.ai_root.blackboard[blackboard_key] = found_thing
		return NODE_SUCCESS
		
	return NODE_FAILURE


// ------------------------------------------------------------------------------
// MIMIC ACTIONS
// ------------------------------------------------------------------------------

/bt_action/mimic_disguise/evaluate(mob/living/user, mob/living/target, list/blackboard)
	if(istype(user, /mob/living/simple_animal/hostile/retaliate/rogue/mimic))
		var/mob/living/simple_animal/hostile/retaliate/rogue/mimic/M = user
		M.disguise()
		return NODE_SUCCESS
	return NODE_FAILURE

/bt_action/mimic_undisguise/evaluate(mob/living/user, mob/living/target, list/blackboard)
	if(istype(user, /mob/living/simple_animal/hostile/retaliate/rogue/mimic))
		var/mob/living/simple_animal/hostile/retaliate/rogue/mimic/M = user
		M.undisguise()
		return NODE_SUCCESS
	return NODE_FAILURE

// ------------------------------------------------------------------------------
// PORTED ACTIONS (COMPLETING THE SET)
// ------------------------------------------------------------------------------

/bt_action/follow_target

/bt_action/follow_target/evaluate(mob/living/user, mob/living/target, list/blackboard)
	if(!user.ai_root)
		return NODE_FAILURE

	var/atom/movable/follow_target = user.ai_root.blackboard["follow_target"]
	if(!follow_target || get_dist(user, follow_target) > user.client?.view || 7)
		user.ai_root.blackboard.Remove("follow_target")
		return NODE_FAILURE

	if(istype(follow_target, /mob/living) && (follow_target:stat == DEAD))
		user.ai_root.blackboard.Remove("follow_target")
		return NODE_SUCCESS

	if(get_dist(user, follow_target) <= 1)
		return NODE_SUCCESS

	// Logic to move towards follow_target
	if(user.ai_root.move_destination != follow_target || !length(user.ai_root.path))
		user.ai_root.path = A_Star(user, get_turf(user), get_turf(follow_target))
		user.ai_root.move_destination = follow_target
	
	if(length(user.ai_root.path))
		return NODE_RUNNING
	
	return NODE_FAILURE

/bt_action/perform_emote
	var/emote_id

/bt_action/perform_emote/evaluate(mob/living/user, mob/living/target, list/blackboard)
	if(!user.ai_root)
		return NODE_FAILURE

	var/emote = emote_id
	if(!emote)
		emote = user.ai_root.blackboard["perform_emote_id"]
	if(!emote)
		return NODE_FAILURE
	
	user.emote(emote)
	return NODE_SUCCESS

/bt_action/perform_speech
	var/speech_text

/bt_action/perform_speech/evaluate(mob/living/user, mob/living/target, list/blackboard)
	if(!user.ai_root)
		return NODE_FAILURE

	var/speech = speech_text
	if(!speech)
		speech = user.ai_root.blackboard["perform_speech_text"]
	if(!speech)
		return NODE_FAILURE
	
	user.say(speech, forced = "AI Controller")
	return NODE_SUCCESS

/bt_action/recuperate

/bt_action/recuperate/evaluate(mob/living/user, mob/living/target, list/blackboard)
	if(!user.ai_root)
		return NODE_FAILURE

	var/mob/living/simple_animal/pawn = user
	if(!istype(pawn) || QDELETED(pawn)) 
		return NODE_FAILURE
	
	if(pawn.health >= pawn.maxHealth)
		return NODE_SUCCESS // Fully healed

	// This action simulates the long do_after. In a BT, we would typically return RUNNING while waiting.
	// However, simple animals might not support async waiting easily in this framework without a state.
	// We'll simulate it by checking if we are already resting.
	
	if(!user.ai_root.blackboard["recuperating"])
		pawn.visible_message(span_danger("[pawn] tends to their wounds..."))
		user.ai_root.blackboard["recuperating"] = world.time
		return NODE_RUNNING
	
	if(world.time - user.ai_root.blackboard["recuperating"] >= 80) // 8 seconds
		var/max_hp = pawn.maxHealth
		// Default values from old behavior
		var/bleed_clot = 0.02
		var/brute_heal = 0.10
		var/fire_heal = 1
		var/blood_recovery = 5
		
		if(pawn.bleed_rate)
			pawn.bleed_rate = pawn.bleed_rate - (max_hp * bleed_clot)
			pawn.bleed_rate = clamp(pawn.bleed_rate, 0, max_hp)
		
		pawn.adjustBruteLoss( (max_hp * -brute_heal) )
		pawn.health = clamp(pawn.health, 0, max_hp)
		pawn.adjust_fire_stacks(-fire_heal)
		if(pawn.blood_volume)
			pawn.blood_volume += blood_recovery
			pawn.blood_volume = clamp(pawn.blood_volume, 0, BLOOD_VOLUME_NORMAL)
		
		user.ai_root.blackboard.Remove("recuperating")
		return NODE_SUCCESS
		
	return NODE_RUNNING

/bt_action/resist/evaluate(mob/living/user, mob/living/target, list/blackboard)
	user.resist()
	return NODE_SUCCESS

/bt_action/use_in_hand/evaluate(mob/living/user, mob/living/target, list/blackboard)
	var/obj/item/held = user.get_active_held_item()
	if(!held)
		return NODE_FAILURE
	user.activate_hand(user.active_hand_index)
	return NODE_SUCCESS

/bt_action/use_on_object/evaluate(mob/living/user, mob/living/target, list/blackboard)
	if(!user.ai_root)
		return NODE_FAILURE

	var/atom/use_target = user.ai_root.blackboard["use_target"]
	if(!use_target || !user.CanReach(use_target))
		return NODE_FAILURE
	
	var/obj/item/held_item = user.get_active_held_item()
	if(held_item)
		held_item.melee_attack_chain(user, use_target)
	else
		user.UnarmedAttack(use_target, TRUE)
	return NODE_SUCCESS

/bt_action/idle_crab_walk
	var/walk_chance = 10

/bt_action/idle_crab_walk/evaluate(mob/living/user, mob/living/target, list/blackboard)
	if(!user.ai_root)
		return NODE_FAILURE

	if(user.ai_root.blackboard["food_target"]) 
		return NODE_FAILURE
	
	if(prob(walk_chance) && (user.mobility_flags & MOBILITY_MOVE) && isturf(user.loc) && !user.pulledby)
		var/move_dir = pick(WEST, EAST)
		step(user, move_dir)
		return NODE_SUCCESS
	return NODE_FAILURE

// ------------------------------------------------------------------------------
// NEW/PORTED ACTIONS (SUBTREE COMPLETION)
// ------------------------------------------------------------------------------

/bt_action/minion_follow
	var/distance = 12

/bt_action/minion_follow/evaluate(mob/living/user, mob/living/target, list/blackboard)
	if(!user.ai_root)
		return NODE_FAILURE

	// 1. Check travel destination (overrides follow)
	var/turf/travel = user.ai_root.blackboard["minion_travel_dest"]
	if(travel)
		if(get_dist(user, travel) <= 1)
			user.ai_root.blackboard.Remove("minion_travel_dest")
			user.set_ai_path_to(null)
			return NODE_SUCCESS
		
		user.ai_root.move_destination = travel
		if(user.set_ai_path_to(travel))
			return NODE_RUNNING
		return NODE_FAILURE

	// 2. Check follow target
	var/mob/following = user.ai_root.blackboard["minion_follow_target"]
	if(following)
		if(get_dist(user, following) > distance)
			// Lost them
			user.ai_root.blackboard.Remove("minion_follow_target")
			return NODE_FAILURE
		
		if(get_dist(user, following) > 1)
			user.ai_root.move_destination = following
			if(user.set_ai_path_to(following))
				return NODE_RUNNING
		return NODE_SUCCESS // Nearby

	return NODE_FAILURE

/bt_action/call_reinforcements
	var/reinforcements_range = 12
	var/cooldown = 30 SECONDS

/bt_action/call_reinforcements/evaluate(mob/living/user, mob/living/target, list/blackboard)
	if(!user.ai_root)
		return NODE_FAILURE

	if(user.ai_root.blackboard["reinforcements_cooldown"] > world.time)
		return NODE_FAILURE

	if(user.ai_root.blackboard["tamed"])
		return NODE_FAILURE

	var/atom/current_target = target
	if(!current_target)
		return NODE_FAILURE

	// Emote/Say
	var/call_say = user.ai_root.blackboard["reinforcements_say"]
	if(call_say)
		user.say(call_say)
	else
		user.emote("cries for help!")

	// Call Logic
	var/mob/living/simple_animal/hostile/H = user
	if(istype(H))
		for(var/mob/living/simple_animal/hostile/other in get_hearers_in_view(reinforcements_range, user))
			if(other == user) continue
			if(H.faction_check_mob(other, exact_match=FALSE) && !other.ai_root?.blackboard["tamed"])
				// Assuming other mobs have a way to receive this signal.
				// In new system, we might just set their target if they are idle?
				// Or add to a 'valid targets' list?
				// For now, let's try to set their target if they don't have one.
				if(other.ai_root && !other.ai_root.target)
					other.ai_root.target = current_target
					other.ai_root.blackboard["chosen_target"] = current_target
					// Wake them up
					other.LosePatience()
					other.GainPatience()

	user.ai_root.blackboard["reinforcements_cooldown"] = world.time + cooldown
	return NODE_SUCCESS

/bt_action/random_speech
	var/speech_chance = 15
	var/list/emote_hear
	var/list/emote_see
	var/list/speak

/bt_action/random_speech/evaluate(mob/living/user, mob/living/target, list/blackboard)
	var/can_chat = user.ai_root.next_chatter_tick >= world.time
	var/can_emote = user.ai_root.next_emote_tick >= world.time

	if(!can_chat && !can_emote)
		return NODE_FAILURE

	if(prob(speech_chance))
		var/len_hear = length(emote_hear)
		var/len_see = length(emote_see)
		var/len_speak = length(speak)
		var/total = len_hear + len_see + len_speak
		
		if(total == 0) return NODE_FAILURE

		var/next_chat = user.ai_root.next_chatter_delay ? user.ai_root.next_chatter_delay : AI_DEFAULT_CHATTER_DELAY
		var/next_emote = user.ai_root.next_emote_delay ? user.ai_root.next_emote_delay : AI_DEFAULT_EMOTE_DELAY

		var/roll = rand(1, total)
		if(can_emote)
			if(roll <= len_hear)
				user.emote(pick(emote_hear))
				user.ai_root.next_emote_tick = world.time + next_emote
			else if(roll <= len_hear + len_see)
				user.emote(pick(emote_see))
				user.ai_root.next_emote_tick = world.time + next_emote
			else
				user.say(pick(speak))
				user.ai_root.next_chatter_tick = world.time + next_chat
		
		// Fallback if can chat, but not emote
		else
			user.say(pick(speak))
			user.ai_root.next_chatter_tick = world.time + next_chat
		return NODE_SUCCESS
	return NODE_FAILURE

/bt_action/maintain_distance
	var/min_dist = 2
	var/max_dist = 4
	var/view_dist = 8

/bt_action/maintain_distance/evaluate(mob/living/user, mob/living/target, list/blackboard)
	if(!user.ai_root || !target)
		return NODE_FAILURE

	var/dist = get_dist(user, target)
	
	// Too close? Step away.
	if(dist < min_dist)
		// Step away logic
		user.face_atom(target)
		var/turf/T = get_step_away(user, target)
		if(T && !T.is_blocked_turf(exclude_mobs=TRUE))
			if(user.set_ai_path_to(T))
				return NODE_RUNNING
		// Try random if blocked
		var/list/dirs = GLOB.alldirs.Copy()
		dirs -= get_dir(user, T)
		dirs -= get_dir(user, target)
		for(var/d in dirs)
			T = get_step(user, d)
			if(T && !T.is_blocked_turf(exclude_mobs=TRUE))
				if(user.set_ai_path_to(T))
					return NODE_RUNNING
		return NODE_FAILURE

	// Too far? Pursue.
	if(dist > max_dist)
		if(user.set_ai_path_to(target))
			return NODE_RUNNING
	
	// Just right.
	return NODE_SUCCESS

/bt_action/eat_dead_body
	var/action_cooldown = 1.5 SECONDS

/bt_action/eat_dead_body/evaluate(mob/living/user, mob/living/target, list/blackboard)
	if(!user.ai_root || !target || target.stat != DEAD)
		return NODE_FAILURE

	// Check eligibility
	if(target.ckey || target.mind) // Don't eat players
		return NODE_FAILURE

	if(get_dist(user, target) > 1)
		user.set_ai_path_to(target)
		return NODE_RUNNING

	// Eat logic
	if(!user.ai_root.blackboard["eating_body"])
		user.visible_message(span_danger("[user] starts to rip apart [target]!"))
		user.ai_root.blackboard["eating_body"] = world.time
		return NODE_RUNNING

	if(world.time - user.ai_root.blackboard["eating_body"] >= 100) // 10 seconds
		if(iscarbon(target))
			var/mob/living/carbon/C = target
			var/list/limbs = list()
			for(var/obj/item/I in C.bodyparts)
				limbs += I
			if(length(limbs))
				var/obj/item/bodypart/limb = pick(limbs)
				limb.dismember()
				limb.Destroy()
			else
				C.gib()
		else
			target.gib()
		
		user.ai_root.blackboard.Remove("eating_body")
		return NODE_SUCCESS

	return NODE_RUNNING

/bt_action/static_melee_attack
/bt_action/static_melee_attack/evaluate(mob/living/user, mob/living/target, list/blackboard)
	if(!target || get_dist(user, target) > 1)
		return NODE_FAILURE
	
	if(user.ai_root && world.time >= user.ai_root.next_attack_tick)
		user.face_atom(target)
		user.ClickOn(target) // Simple click
		user.ai_root.next_attack_tick = world.time + (user.ai_root.next_attack_delay || 10)
		return NODE_SUCCESS
	return NODE_RUNNING

// ------------------------------------------------------------------------------
// EVENT ACTIONS
// ------------------------------------------------------------------------------

/bt_action/deadite_migrate
	var/path_key = "deadite_migration_path"
	var/target_key = "deadite_migration_target"

/bt_action/deadite_migrate/evaluate(mob/living/user, mob/living/target, list/blackboard)
	if(!user.ai_root)
		return NODE_FAILURE

	var/list/path = blackboard[path_key]
	if(!length(path))
		return NODE_FAILURE

	// If we are currently moving to a migration target, check if we arrived
	var/turf/current_target = blackboard[target_key]
	
	if(current_target)
		if(user.loc == current_target || get_dist(user, current_target) <= 1)
			// Arrived at current point, pick next
			var/idx = path.Find(current_target)
			if(idx > 0 && idx < length(path))
				var/turf/next = path[idx+1]
				blackboard[target_key] = next
				user.set_ai_path_to(next)
				return NODE_RUNNING
			else if(idx == length(path))
				// Arrived at end
				blackboard.Remove(path_key)
				blackboard.Remove(target_key)
				return NODE_SUCCESS
		else
			// Still travelling to current point
			user.ai_root.move_destination = current_target
			if(user.set_ai_path_to(current_target))
				return NODE_RUNNING
			// If pathing fails, we might be stuck or target unreachable.
			// For now, retry.
			return NODE_RUNNING
	else
		// No current target, start from beginning or closest?
		// Logic: Pick first point
		var/turf/first = path[1]
		blackboard[target_key] = first
		user.set_ai_path_to(first)
		return NODE_RUNNING

	return NODE_FAILURE
