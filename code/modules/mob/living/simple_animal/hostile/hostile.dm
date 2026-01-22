/mob/living/simple_animal/hostile
	faction = list("hostile")
	stop_automated_movement_when_pulled = 0
	obj_damage = 40
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES //Bitflags. Set to ENVIRONMENT_SMASH_STRUCTURES to break closets,tables,racks, etc; ENVIRONMENT_SMASH_WALLS for walls; ENVIRONMENT_SMASH_RWALLS for rwalls
	var/ranged = FALSE
	var/rapid = 0 //How many shots per volley.
	var/rapid_fire_delay = 2 //Time between rapid fire shots

	var/dodging = FALSE
	var/approaching_target = FALSE //We should dodge now
	var/in_melee = FALSE	//We should sidestep now
	var/dodge_prob = 0
	var/sidestep_per_cycle = 1 //How many sidesteps per npcpool cycle when in melee

	var/projectiletype	//set ONLY it and NULLIFY casingtype var, if we have ONLY projectile
	var/projectilesound
	var/casingtype		//set ONLY it and NULLIFY projectiletype, if we have projectile IN CASING
	var/move_to_delay = 3 //delay for the automated movement.
	var/list/friends = list()
	var/list/emote_taunt = list()
	var/taunt_chance = 0

	var/rapid_melee = 1			 //Number of melee attacks between each npc pool tick. Spread evenly.
	var/melee_queue_distance = 4 //If target is close enough start preparing to hit them if we have rapid_melee enabled

	var/ranged_message = "fires" //Fluff text for ranged mobs
	var/ranged_cooldown = 0 //What the current cooldown on ranged attacks is, generally world.time + ranged_cooldown_time
	var/ranged_cooldown_time = 30 //How long, in deciseconds, the cooldown of ranged attacks is
	var/ranged_ignores_vision = FALSE //if it'll fire ranged attacks even if it lacks vision on its target, only works with environment smash
	var/check_friendly_fire = 0 // Should the ranged mob check for friendlies when shooting
	var/retreat_distance = null //If our mob runs from players when they're too close, set in tile distance. By default, mobs do not retreat.
	var/minimum_distance = 1 //Minimum approach distance, so ranged mobs chase targets down, but still keep their distance set in tiles to the target, set higher to make mobs keep distance


//These vars are related to how mobs locate and target
	var/robust_searching = 0 //By default, mobs have a simple searching method, set this to 1 for the more scrutinous searching (stat_attack, stat_exclusive, etc), should be disabled on most mobs
	var/vision_range = 6 //How big of an area to search for targets in, a vision of 9 attempts to find targets as soon as they walk into screen view
	var/aggro_vision_range = 18 //If a mob is aggro, we search in this radius. Defaults to 9 to keep in line with original simple mob aggro radius
	var/search_objects = 0 //If we want to consider objects when searching around, set this to 1. If you want to search for objects while also ignoring mobs until hurt, set it to 2. To completely ignore mobs, even when attacked, set it to 3
	var/search_objects_timer_id //Timer for regaining our old search_objects value after being attacked
	var/search_objects_regain_time = 30 //the delay between being attacked and gaining our old search_objects value back
	var/list/wanted_objects = list() //A typecache of objects types that will be checked against to attack, should we have search_objects enabled
	var/stat_attack = CONSCIOUS //Mobs with stat_attack to UNCONSCIOUS will attempt to attack things that are unconscious, Mobs with stat_attack set to DEAD will attempt to attack the dead.
	var/stat_exclusive = FALSE //Mobs with this set to TRUE will exclusively attack things defined by stat_attack, stat_attack DEAD means they will only attack corpses
	var/attack_same = 0 //Set us to 1 to allow us to attack our own faction
	var/atom/targets_from = null //all range/attack/etc. calculations should be done from this atom, defaults to the mob itself, useful for Vehicles and such
	var/attack_all_objects = FALSE //if true, equivalent to having a wanted_objects list containing ALL objects.
	var/list/favored_structures = list() //if we want our mob to like specific structs and not smash 'em all, e.g fey mobs with vines (although be careful not to set this to something that blocks their path

	var/lose_patience_timer_id //id for a timer to call LoseTarget(), used to stop mobs fixating on a target they can't reach
	var/lose_patience_timeout = 300 //30 seconds by default, so there's no major changes to AI behaviour, beyond actually bailing if stuck forever

	var/retreat_health

	var/next_seek

	cmode = 1
	setparrytime = 30
	dodgetime = 30




/mob/living/simple_animal/hostile/Initialize()
	. = ..()
	last_aggro_loss = world.time //so we delete even if we never found a target
	if(!targets_from)
		targets_from = src
	wanted_objects = typecacheof(wanted_objects)
	
	// If we still have the default idiot tree from simple_animal, upgrade to generic hostile
	if(istype(ai_root, /datum/behavior_tree/node/selector/generic_friendly_tree) || !ai_root)
		init_ai_root(/datum/behavior_tree/node/selector/generic_hostile_tree)
		// Initialize the new tree properties if needed
		ai_root.next_move_delay = move_to_delay


/mob/living/simple_animal/hostile/Destroy()
	targets_from = null
	return ..()

/mob/living/simple_animal/hostile/Life()
	. = ..()
	if(!.) //dead
		walk(src, 0) //stops walking
		return 0

// Legacy function, currently only called by legacy logic and unsupported.
// Any similar functionality should be migrated to the new behavior tree.
/mob/living/simple_animal/hostile/proc/deaggrodel()
	return

/mob/living/simple_animal/hostile/proc/sidestep()
	if(!target || !isturf(target.loc) || !isturf(loc) || stat == DEAD)
		return
	var/target_dir = get_dir(src,target)

	var/static/list/cardinal_sidestep_directions = list(-90,-45,0,45,90)
	var/static/list/diagonal_sidestep_directions = list(-45,0,45)
	var/chosen_dir = 0
	if (target_dir & (target_dir - 1))
		chosen_dir = pick(diagonal_sidestep_directions)
	else
		chosen_dir = pick(cardinal_sidestep_directions)
	if(chosen_dir)
		chosen_dir = turn(target_dir,chosen_dir)
		Move(get_step(src,chosen_dir))
		face_atom(target) //Looks better if they keep looking at you when dodging

/mob/living/simple_animal/hostile/attacked_by(obj/item/I, mob/living/user)
	if(stat == CONSCIOUS && !target && ai_root && !client && user)
		if(ai_root)
			ai_root.target = user
	return ..()

/mob/living/simple_animal/hostile/bullet_act(obj/projectile/P)
	if(stat == CONSCIOUS && !target && ai_root && !client)
		if(P.firer && get_dist(src, P.firer) <= aggro_vision_range)
			if(ai_root)
				ai_root.target = P.firer
		if(ai_root)
			set_ai_path_to(P.starting)
	return ..()

//////////////HOSTILE MOB TARGETTING AND AGGRESSION////////////

/mob/living/simple_animal/hostile/proc/Found(atom/A)//This is here as a potential override to pick a specific target if available
	if (isliving(A))
		var/mob/living/living_target = A
		if(living_target.alpha == 0 && living_target.rogue_sneaking || world.time < living_target.mob_timers[MT_INVISIBILITY]) // is our target hidden? if they are, attempt to detect them once
			return npc_detect_sneak(living_target, simple_detect_bonus)
	return

// Please do not add one-off mob AIs here, but override this function for your mob
/mob/living/simple_animal/hostile/CanAttack(atom/the_target)//Can we actually attack a possible target?
	if(isturf(the_target) || !the_target || the_target.type == /atom/movable/lighting_object) // bail out on invalids
		return FALSE

	if(binded)//bound by summoning circle = don't try to attack
		return FALSE

	if(ismob(the_target)) //Target is in godmode, ignore it.
		var/mob/M = the_target
		if(world.time < M.mob_timers[MT_INVISIBILITY])//if they're under the effect of the invisibility spell
			return FALSE
		if(M.status_flags & GODMODE)
			return FALSE
		if(M.name in friends)
			return FALSE

	if(see_invisible < the_target.invisibility)//Target's invisible to us, forget it
		return FALSE
	if(search_objects < 2)
		if(isliving(the_target))
			var/mob/living/L = the_target
			var/faction_check = faction_check_mob(L)
			if(robust_searching)
				if(faction_check && !attack_same)
					return FALSE
				if(L.stat > stat_attack)
					return FALSE
			else
				if((faction_check && !attack_same) || L.stat)
					return FALSE
			return TRUE

	if(isobj(the_target))
		if(attack_all_objects || is_type_in_typecache(the_target, wanted_objects))
			return TRUE

	return FALSE

/mob/living/simple_animal/hostile/GiveTarget(new_target)//Step 4, give us our selected target
	. = ..()

	LosePatience()
	if(target != null)
		GainPatience()
		last_aggro_loss = 0
		Aggro()
		return 1

//What we do after closing in
/mob/living/simple_animal/hostile/proc/MeleeAction(patience = TRUE)
	if(binded)
		return FALSE
	if(rapid_melee > 1)
		var/datum/callback/cb = CALLBACK(src, PROC_REF(CheckAndAttack))
		var/delay = ai_root.next_attack_delay / rapid_melee
		for(var/i in 1 to rapid_melee)
			addtimer(cb, (i - 1)*delay)
	else
		AttackingTarget()
	if(patience)
		GainPatience()

/mob/living/simple_animal/hostile/proc/CheckAndAttack()
	if(target && targets_from && isturf(targets_from.loc) && target.Adjacent(targets_from) && !incapacitated())
		AttackingTarget()

/mob/living/simple_animal/hostile/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	if(!ckey && !stat && search_objects < 3 && . > 0)//Not unconscious, and we don't ignore mobs
		if(search_objects)//Turn off item searching and ignore whatever item we were looking at, we're more concerned with fight or flight
			target = null
			LoseSearchObjects()
			SSai.WakeUp(src)
		else if(target != null && prob(40))//No more pulling a mob forever and having a second player attack it, it can switch targets now if it finds a more suitable one
			SSai.WakeUp(src)


/mob/living/simple_animal/hostile/proc/AttackingTarget()
	if(SEND_SIGNAL(src, COMSIG_HOSTILE_PRE_ATTACKINGTARGET, target) & COMPONENT_HOSTILE_NO_PREATTACK)
		return FALSE //but more importantly return before attack_animal called
	SEND_SIGNAL(src, COMSIG_HOSTILE_ATTACKINGTARGET, target)
	in_melee = TRUE

	if(!QDELETED(target))
		return target.attack_animal(src)

/mob/living/simple_animal/hostile/proc/Aggro()
	if(ai_root?.next_emote_tick <= world.time)
		vision_range = aggro_vision_range
		if(target && emote_taunt.len && prob(taunt_chance))
			emote("me", 1, "[pick(emote_taunt)] at [target].")
			taunt_chance = max(taunt_chance-7,2)
		emote("aggro")


/mob/living/simple_animal/hostile/proc/LoseAggro()
	vision_range = initial(vision_range)
	taunt_chance = initial(taunt_chance)

/mob/living/simple_animal/hostile/LoseTarget()
	if(ai_root)
		ai_root.target = null
		ai_root.obj_target = null

	if(target)
		last_aggro_loss = world.time
	target = null
	approaching_target = FALSE
	in_melee = FALSE
	set_ai_path_to(null)
	LoseAggro()

/mob/living/simple_animal/hostile/proc/revalidate_target_on_faction_change()
	if(!target || !isliving(target))
		return
	if(faction_check_mob(target))
		if(ai_root)
			ai_root.target = null

/mob/living/proc/notify_faction_change()
	for(var/mob/living/simple_animal/hostile/H in orange(7, src))
		if(H.target == src)
			H.revalidate_target_on_faction_change()

//////////////END HOSTILE MOB TARGETTING AND AGGRESSION////////////

/mob/living/simple_animal/hostile/death(gibbed)
	LoseTarget()
	
	LoseAggro()
	..(gibbed)

/mob/living/simple_animal/hostile/proc/summon_backup(distance, exact_faction_match)
	playsound(loc, 'sound/blank.ogg', 50, TRUE, -1)
	for(var/mob/living/simple_animal/hostile/M in oview(distance, targets_from))
		if(faction_check_mob(M, TRUE))
			if(M.ai_root)
				M.set_ai_path_to(src)

/mob/living/simple_animal/hostile/proc/CheckFriendlyFire(atom/A)
	if(check_friendly_fire)
		for(var/turf/T in getline(src,A)) // Not 100% reliable but this is faster than simulating actual trajectory
			for(var/mob/living/L in T)
				if(L == src || L == A)
					continue
				if(faction_check_mob(L) && !attack_same)
					return TRUE

/mob/living/simple_animal/hostile/proc/OpenFire(atom/A)
	if(binded)
		return FALSE
	if(CheckFriendlyFire(A))
		return
	visible_message(span_danger("<b>[src]</b> [ranged_message] at [A]!"))


	if(rapid > 1)
		var/datum/callback/cb = CALLBACK(src, PROC_REF(Shoot), A)
		for(var/i in 1 to rapid)
			addtimer(cb, (i - 1)*rapid_fire_delay)
	else
		Shoot(A)
	ranged_cooldown = world.time + ranged_cooldown_time


/mob/living/simple_animal/hostile/proc/Shoot(atom/targeted_atom)
	if( QDELETED(targeted_atom) || targeted_atom == targets_from.loc || targeted_atom == targets_from )
		return
	var/turf/startloc = get_turf(targets_from)
	if(casingtype)
		var/obj/item/ammo_casing/casing = new casingtype(startloc)
		playsound(src, projectilesound, 100, TRUE)
		casing.fire_casing(targeted_atom, src, null, null, null, ran_zone(), 0,  src)
	else if(projectiletype)
		var/obj/projectile/P = new projectiletype(startloc)
		playsound(src, projectilesound, 100, TRUE)
		P.starting = startloc
		P.firer = src
		P.fired_from = src
		P.yo = targeted_atom.y - startloc.y
		P.xo = targeted_atom.x - startloc.x
		// Legacy newtonian_move check removed
		P.original = targeted_atom
		P.preparePixelProjectile(targeted_atom, src)
		P.fire()
		return P


/mob/living/simple_animal/hostile/proc/CanSmashTurfs(turf/T)
	return iswallturf(T) || ismineralturf(T)


/mob/living/simple_animal/hostile/Move(atom/newloc, dir , step_x , step_y)
	if(dodging && approaching_target && prob(dodge_prob) && moving_diagonally == 0 && isturf(loc) && isturf(newloc) && !incapacitated())
		return dodge(newloc,dir)
	else
		return ..()

/mob/living/simple_animal/hostile/proc/dodge(moving_to,move_direction)
	//Assuming we move towards the target we want to swerve toward them to get closer
	var/cdir = turn(move_direction,45)
	var/ccdir = turn(move_direction,-45)
	dodging = FALSE
	. = Move(get_step(loc,pick(cdir,ccdir)))
	if(!.)//Can't dodge there so we just carry on
		. =  Move(moving_to,move_direction)
	dodging = TRUE

/mob/living/simple_animal/hostile/proc/DestroyObjectsInDirection(direction)
	var/turf/T = get_step(targets_from, direction)
	if(QDELETED(T))
		return
	if(T.Adjacent(targets_from))
		if(CanSmashTurfs(T))
			T.attack_animal(src)
			return
	for(var/obj/O in T.contents)
		if(!O.Adjacent(targets_from))
			continue
		if(O in favored_structures)
			continue
		if((ismachinery(O) || isstructure(O)) && environment_smash >= ENVIRONMENT_SMASH_STRUCTURES && !O.IsObscured())
			O.attack_animal(src)
			return

/mob/living/simple_animal/hostile/proc/DestroyPathToTarget()
	var/dir_to_target = get_dir(targets_from, target)
	if(environment_smash)
		var/turf/V = get_turf(src)
		for (var/obj/structure/O in V.contents)	//check for if a direction dense structure is on the same tile as the mob
			if(isstructure(O) && !(O in favored_structures))
				O.attack_animal(src)
				continue
		EscapeConfinement()
		var/dir_list = list()
		if(dir_to_target in GLOB.diagonals) //it's diagonal, so we need two directions to hit
			for(var/direction in GLOB.cardinals)
				if(direction & dir_to_target)
					dir_list += direction
		else
			dir_list += dir_to_target
		for(var/direction in dir_list) //now we hit all of the directions we got in this fashion, since it's the only directions we should actually need
			DestroyObjectsInDirection(direction)
	for(var/obj/structure/O in get_step(src,dir_to_target))
		if(O.density && O.climbable)
			O.climb_structure(src)
			break

/mob/living/simple_animal/hostile/proc/DestroySurroundings() // for use with megafauna destroying everything around them
	if(environment_smash)
		EscapeConfinement()
		for(var/dir in GLOB.cardinals)
			DestroyObjectsInDirection(dir)


/mob/living/simple_animal/hostile/proc/EscapeConfinement()
	if(buckled)
		buckled.attack_animal(src)
	if(!targets_from.loc)
		return
	if(!isturf(targets_from.loc))//Did someone put us in something?
		var/atom/A = targets_from.loc
		A.attack_animal(src)//Bang on it till we get out


/mob/living/simple_animal/hostile/proc/FindHidden()
	if(istype(target.loc, /obj/structure/closet))
		var/atom/A = target.loc
		if(get_dist(src, A) <= 1)
			set_ai_path_to(null)
		else
			set_ai_path_to(A)
		if(A.Adjacent(targets_from))
			A.attack_animal(src)
		return 1

/mob/living/simple_animal/hostile/RangedAttack(atom/A, params) //Player firing
	if(ranged && ranged_cooldown <= world.time)
		target = A
		OpenFire(A)
	..()


/mob/living/simple_animal/hostile/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	if(!ckey && !stat && search_objects < 3 && . > 0)//Not unconscious, and we don't ignore mobs
		if(search_objects)//Turn off item searching and ignore whatever item we were looking at, we're more concerned with fight or flight
			target = null
			LoseSearchObjects()
		
	SSai.WakeUp(src)

/mob/living/simple_animal/hostile/proc/GainPatience()
	if ((lose_patience_timeout) && !QDELETED(src))
		LosePatience()
		lose_patience_timer_id = addtimer(CALLBACK(src, PROC_REF(LoseTarget)), lose_patience_timeout, TIMER_STOPPABLE)


/mob/living/simple_animal/hostile/proc/LosePatience()
	deltimer(lose_patience_timer_id)


//These two procs handle losing and regaining search_objects when attacked by a mob
/mob/living/simple_animal/hostile/proc/LoseSearchObjects()
	search_objects = 0
	deltimer(search_objects_timer_id)
	search_objects_timer_id = addtimer(CALLBACK(src, PROC_REF(RegainSearchObjects)), search_objects_regain_time, TIMER_STOPPABLE)


/mob/living/simple_animal/hostile/proc/RegainSearchObjects(value)
	if(!value)
		value = initial(search_objects)
	search_objects = value
