/mob/living/simple_animal/hostile/retaliate/rogue/fae/dryad	//Make this cause giant vine tangled messes
	icon = 'icons/mob/summonable/32x64.dmi'
	name = "dryad"
	icon_state = "dryad"
	icon_living = "dryad"
	icon_dead = "vvd"
	summon_primer = "You are a dryad, a large sized fae. You spend time tending to forests, guarding sacred ground from tresspassers. Now you've been pulled from your home into a new world, that is decidedly less wild and natural. How you react to these events, only time can tell."
	summon_tier = 3
	gender = MALE
	emote_hear = null
	emote_see = null
	speak_chance = 1
	turns_per_move = 6
	see_in_dark = 6
	move_to_delay = 12
	base_intents = list(/datum/intent/simple/elementalt3_unarmed)
	butcher_results = list()
	faction = list("fae")
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	health = 650
	maxHealth = 650
	melee_damage_lower = 40
	melee_damage_upper = 55
	vision_range = 7
	aggro_vision_range = 9
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES
	simple_detect_bonus = 20
	retreat_distance = 0
	minimum_distance = 0
	food_type = list()
	footstep_type = FOOTSTEP_MOB_BAREFOOT
	pooptype = null
	STACON = 18
	STASTR = 14
	STASPD = 8
	simple_detect_bonus = 20
	deaggroprob = 0
	defprob = 40
	// del_on_deaggro = 44 SECONDS
	retreat_health = 0.3
	food = 0
	attack_sound = "plantcross"
	dodgetime = 30
	aggressive = 1
//	stat_attack = UNCONSCIOUS
	ranged = FALSE
	var/vine_cd
	inherent_spells = list(/obj/effect/proc_holder/spell/self/create_vines)

/mob/living/simple_animal/hostile/retaliate/rogue/fae/dryad/Initialize()
	. = ..()
	init_ai_root(/datum/behavior_tree/node/selector/dryad_tree)
	ai_root.next_move_delay = move_to_delay

/mob/living/simple_animal/hostile/retaliate/rogue/fae/dryad/simple_add_wound(datum/wound/wound, silent = FALSE, crit_message = FALSE)	//no wounding the watcher
	return

/mob/living/simple_animal/hostile/retaliate/rogue/fae/dryad/proc/vine()
	visible_message(span_boldwarning("Vines spread out from [src]!"))
	for(var/turf/turf as anything in RANGE_TURFS(3,src.loc))
		if(!locate(/obj/structure/vine) in turf)
			new /obj/structure/vine(turf)
		for(var/mob/living/carbon/human/H in turf.contents)
			to_chat(H,span_danger("I'm tangled up in the vines!"))
			H.Immobilize(50)

/mob/living/simple_animal/hostile/retaliate/rogue/fae/dryad/death(gibbed)
	..()
	var/turf/deathspot = get_turf(src)
	new /obj/item/magic/melded/t1(deathspot)
	new /obj/item/magic/fae/scale(deathspot)
	new /obj/item/magic/fae/scale(deathspot)
	new /obj/item/magic/fae/core(deathspot)
	new /obj/item/magic/fae/core(deathspot)
	new /obj/item/magic/fae/dust(deathspot)
	new /obj/item/magic/fae/dust(deathspot)
	update_icon()
	spill_embedded_objects()
	qdel(src)

/obj/effect/proc_holder/spell/self/create_vines
	name = "Spawn Vines"
	recharge_time = 15 SECONDS
	sound = 'sound/magic/churn.ogg'
	overlay_state = "blesscrop"

/obj/effect/proc_holder/spell/self/create_vines/cast(list/targets, mob/living/user = usr)
	if(istype(user, /mob/living/simple_animal/hostile/retaliate/rogue/fae/dryad))
		var/mob/living/simple_animal/hostile/retaliate/rogue/fae/dryad/treeguy = user
		if(world.time <= treeguy.vine_cd + 150)//shouldn't ever happen cuz the spell cd is the same as summon_cd but I'd rather it check with the internal cd just in case
			to_chat(user,span_warning("Too soon!"))
			revert_cast()
			return FALSE
		if(treeguy.binded)
			revert_cast()
			return FALSE
		treeguy.vine()
		treeguy.vine_cd = world.time
