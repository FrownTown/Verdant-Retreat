/mob/living/carbon/human
	var/aggressive=0 //0= retaliate only
	var/list/enemies = list()
	var/list/friends = list()
	var/list/blacklistItems = list()
	var/wander = TRUE
	var/next_idle = 0
	var/flee_in_pain = FALSE
	var/rude = FALSE
	var/tree_climber = FALSE
	var/find_targets_above = TRUE

	// LEAPING
	var/npc_jump_chance = 5
	var/npc_jump_distance = 4
	var/npc_max_jump_stamina = 50

	///What distance should we be checking for interesting things when considering idling/deidling?
	var/interesting_dist = AI_DEFAULT_INTERESTING_DIST

/mob/living/carbon/human/Initialize()
	. = ..()

/mob/living/carbon/human/Destroy()
	return ..()

/mob/living/carbon/human/proc/IsStandingStill()
	// For NPCs, just check if doing an action
	return doing

/mob/living/carbon/human/proc/check_mouth_grabbed()
	var/obj/item/bodypart/head/head = get_bodypart(BODY_ZONE_HEAD)
	if(!head)
		return FALSE
	for(var/obj/item/grabbing/grab in head.grabbedby)
		if(grab.sublimb_grabbed == BODY_ZONE_PRECISE_MOUTH)
			return TRUE
	return FALSE

/mob/living/carbon/human/proc/IsDeadOrIncap(checkDead = TRUE)
	if(!(mobility_flags & MOBILITY_FLAGS_INTERACTION))
		return TRUE
	if(health <= 0 && checkDead)
		return TRUE
	if(incapacitated(ignore_restraints = TRUE))
		return TRUE
	return FALSE

/mob/living/carbon/human/proc/equip_item(obj/item/I)
	if(I.loc == src)
		return TRUE

	if(I.anchored)
		blacklistItems[I] ++
		return FALSE

	// WEAPONS
	if(istype(I, /obj/item))
		if(put_in_hands(I))
			return TRUE

	blacklistItems[I] ++
	return FALSE

/mob/living/carbon/human/proc/monkeyDrop(obj/item/A)
	if(A)
		dropItemToGround(A, TRUE)

/mob/living/carbon/human/proc/should_target(mob/living/L)
	if(HAS_TRAIT(src, TRAIT_PACIFISM))
		return FALSE

	if(L == src)
		return FALSE

	if (L.alpha == 0 && L.rogue_sneaking)
		return FALSE

	if(!is_in_zweb(src.z,L.z))
		return FALSE

	if(L.stat == DEAD)
		return FALSE

	if(L.InFullCritical())
		return FALSE

	if(L.name in friends)
		return FALSE

	if(enemies[L])
		return TRUE

	if(aggressive && !faction_check_mob(L))
		return TRUE

	return FALSE

/mob/living/carbon/human/proc/back_to_idle()
	if(pulling)
		stop_pulling()
	set_ai_path_to(null)
	m_intent = MOVE_INTENT_WALK
	target = null
	a_intent = INTENT_HELP

/mob/living/carbon/human/proc/npc_choose_attack_zone(mob/living/victim)
	if(mind?.has_antag_datum(/datum/antagonist/zombie))
		aimheight_change(deadite_get_aimheight(victim))
		return
	if(!(mobility_flags & MOBILITY_STAND))
		aimheight_change(rand(1, 4)) // Go for the knees!
		return
	if(HAS_TRAIT(victim, TRAIT_BLOODLOSS_IMMUNE)) // Go for the head!
		aimheight_change(rand(12, 19))
		return
	aimheight_change(pick(rand(5, 8), rand(9, 11), rand(12, 19))) // Arms, chest, head.

/mob/living/carbon/human/proc/monkey_attack(mob/living/L)
	if(next_move > world.time)
		return

	npc_choose_attack_zone(L)
	do_best_melee_attack(L)

/mob/living/carbon/human/proc/do_best_melee_attack(mob/living/victim)
	if(mind?.has_antag_datum(/datum/antagonist/zombie))
		if(do_deadite_attack(victim))
			return TRUE

	var/obj/item/Weapon = get_active_held_item()
	var/obj/item/OffWeapon = get_inactive_held_item()

	if(OffWeapon && (!Weapon || OffWeapon.force > Weapon.force))
		swap_hand()

	Weapon = get_active_held_item()
	OffWeapon = get_inactive_held_item()

	// attack with weapon if we have one
	if(Weapon)
		if(!Weapon.wielded && Weapon.force_wielded > Weapon.force)
			if(!OffWeapon)
				Weapon.attack_self(src)
		rog_intent_change(1)
		used_intent = a_intent
		Weapon.melee_attack_chain(src, victim)
		return TRUE
	else //Unarmed
		rog_intent_change(4) // punch
		used_intent = a_intent
		UnarmedAttack(victim, 1)
		var/adf = used_intent.clickcd
		if(istype(rmb_intent, /datum/rmb_intent/aimed))
			adf = round(adf * 1.4)
		if(istype(rmb_intent, /datum/rmb_intent/swift))
			adf = round(adf * 0.6)
		changeNext_move(adf)
		return TRUE

/mob/living/carbon/human/proc/retaliate(mob/living/L)
	if(!wander)
		wander = TRUE
	if(L == src)
		return
	if(ai_root) // Behavior tree system
		if(L.alpha == 0 && L.rogue_sneaking)
			if (prob(5))
				visible_message(span_notice("[src] begins searching around frantically..."))
			var/extra_chance = (health <= maxHealth * 50) ? 30 : 0
			if (!npc_detect_sneak(L, extra_chance))
				return
		face_atom(L)
		if(!ai_root.target)
			emote("aggro")
		if(ai_root)
			ai_root.target = L
		enemies |= L

/mob/living/carbon/human/attackby(obj/item/W, mob/user, params)
	. = ..()
	if(!ai_root) return
	if((W.force) && (!ai_root.target) && (W.damtype != STAMINA) )
		retaliate(user)

/mob/living/proc/npc_detect_sneak(mob/living/target, extra_prob = 0)
	if (target.alpha > 0 || !target.rogue_sneaking)
		return TRUE
	var/probby = 4 * STAPER
	probby += extra_prob
	var/sneak_bonus = 0
	if(target.mind)
		if (world.time < target.mob_timers[MT_INVISIBILITY])
			sneak_bonus = (max(target.get_skill_level(/datum/skill/magic/arcane), target.get_skill_level(/datum/skill/magic/holy)) * 10)
			probby -= 20
		else
			sneak_bonus = (target.get_skill_level(/datum/skill/misc/sneaking) * 5)
		probby -= sneak_bonus
	if(!target.check_armor_skill())
		probby += 85
		if (sneak_bonus)
			probby += sneak_bonus
	if (target.badluck(5))
		probby += (10 - target.STALUC) * 5
	if (target.goodluck(5))
		probby -= (10 - target.STALUC) * 5

	if (prob(probby))
		target.mob_timers[MT_FOUNDSNEAK] = world.time
		if(!target.thicc_sneaking)
			to_chat(target, span_danger("[src] sees me! I'm found!"))
		else
			to_chat(target, span_danger("[src] sees me! The clap of my asscheeks gave me away!"))
		target.update_sneak_invis(TRUE)
		return TRUE
	else
		return FALSE

/mob/living/carbon/human/Moved()
	. = ..()

