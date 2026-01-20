/mob/living/simple_animal/hostile/retaliate/rogue/chicken
	icon = 'icons/roguetown/mob/monster/chicken.dmi'
	name = "\improper chicken"
	desc = "A small, domestic, flightless bird. It's known for both its egg-laying and rapid breeding, making it a boon for carnivorous societies."
	icon_state = "chicken_brown"
	icon_living = "chicken_brown"
	icon_dead = "chicken_brown_dead"

	gender = FEMALE
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	emote_see = list("pecks at the ground.","flaps its wings viciously.")
	density = FALSE
	base_intents = list(/datum/intent/simple/claw)
	speak_chance = 2
	turns_per_move = 5
	faction = list("chickens")
	botched_butcher_results = list(/obj/item/reagent_containers/food/snacks/rogue/meat/poultry = 1)
	butcher_results = list(/obj/item/reagent_containers/food/snacks/fat = 1, 
		/obj/item/reagent_containers/food/snacks/rogue/meat/poultry = 1,
		/obj/item/natural/feather = 1, 
		/obj/item/natural/bone = 2,
		/obj/item/alch/sinew = 1, 
		/obj/item/alch/bone = 1,
		/obj/item/alch/viscera = 1)
	perfect_butcher_results = list(
		/obj/item/reagent_containers/food/snacks/fat = 2, 
		/obj/item/reagent_containers/food/snacks/rogue/meat/poultry = 2,
		/obj/item/natural/feather = 2, 
		/obj/item/natural/bone = 2, 
		/obj/item/alch/sinew = 1, 
		/obj/item/alch/bone = 1,
		/obj/item/alch/viscera = 1
		)
	var/egg_type = /obj/item/reagent_containers/food/snacks/egg
	food_type = list(/obj/item/reagent_containers/food/snacks/grown/berries/rogue,/obj/item/natural/worms,/obj/item/reagent_containers/food/snacks/grown/wheat,/obj/item/reagent_containers/food/snacks/grown/oat)
	response_help_continuous = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "gently pushes aside"
	response_disarm_simple = "gently push aside"
	response_harm_continuous = "kicks"
	response_harm_simple = "kick"
	melee_damage_lower = 1
	melee_damage_upper = 8
	pooptype = /obj/item/natural/poo/horse
	health = 15
	maxHealth = 15
	ventcrawler = VENTCRAWLER_ALWAYS
	var/eggsFertile = TRUE
	var/body_color
	var/icon_prefix = "chicken"
	pass_flags = PASSTABLE | PASSMOB
	mob_size = MOB_SIZE_SMALL
	var/list/layMessage = EGG_LAYING_MESSAGES
	var/list/validColors = list("brown","black","white")
	var/static/chicken_count = 0
	footstep_type = FOOTSTEP_MOB_BAREFOOT
	STACON = 6
	STASTR = 6
	STASPD = 1
	tame = TRUE

/mob/living/simple_animal/hostile/retaliate/rogue/chicken/get_sound(input)
	switch(input)
		if("pain")
			return pick('sound/vo/mobs/chikn/pain (1).ogg','sound/vo/mobs/chikn/pain (2).ogg','sound/vo/mobs/chikn/pain (3).ogg')
		if("death")
			return 'sound/vo/mobs/chikn/death.ogg'
		if("idle")
			return pick('sound/vo/mobs/chikn/idle (1).ogg','sound/vo/mobs/chikn/idle (2).ogg','sound/vo/mobs/chikn/idle (3).ogg','sound/vo/mobs/chikn/idle (4).ogg','sound/vo/mobs/chikn/idle (5).ogg','sound/vo/mobs/chikn/idle (6).ogg')


/mob/living/simple_animal/hostile/retaliate/rogue/chicken/simple_limb_hit(zone)
	if(!zone)
		return ""
	switch(zone)
		if(BODY_ZONE_PRECISE_R_EYE)
			return "head"
		if(BODY_ZONE_PRECISE_L_EYE)
			return "head"
		if(BODY_ZONE_PRECISE_NOSE)
			return "beak"
		if(BODY_ZONE_PRECISE_MOUTH)
			return "beak"
		if(BODY_ZONE_PRECISE_SKULL)
			return "head"
		if(BODY_ZONE_PRECISE_EARS)
			return "head"
		if(BODY_ZONE_PRECISE_NECK)
			return "neck"
		if(BODY_ZONE_PRECISE_L_HAND)
			return "wing"
		if(BODY_ZONE_PRECISE_R_HAND)
			return "wing"
		if(BODY_ZONE_PRECISE_L_FOOT)
			return "leg"
		if(BODY_ZONE_PRECISE_R_FOOT)
			return "leg"
		if(BODY_ZONE_HEAD)
			return "head"
		if(BODY_ZONE_R_LEG)
			return "leg"
		if(BODY_ZONE_L_LEG)
			return "leg"
		if(BODY_ZONE_R_ARM)
			return "wing"
		if(BODY_ZONE_L_ARM)
			return "wing"
	return ..()

/mob/living/simple_animal/hostile/retaliate/rogue/chicken/Initialize()
	. = ..()
	if(!body_color)
		body_color = pick(validColors)
	icon_state = "[icon_prefix]_[body_color]"
	icon_living = "[icon_prefix]_[body_color]"
	icon_dead = "[icon_prefix]_[body_color]_dead"
	pixel_x = rand(-6, 6)
	pixel_y = rand(0, 10)
	++chicken_count
	
	ai_root = new /datum/behavior_tree/node/selector/chicken_tree()
	ai_root.next_move_delay = move_to_delay
	SSai.Register(src)

/mob/living/simple_animal/hostile/retaliate/rogue/chicken/Destroy()
	--chicken_count
	return ..()

/obj/structure/fluff/nest
	name = "nest"
	desc = ""
	icon = 'icons/roguetown/misc/structure.dmi'
	icon_state = "nest"
	density = FALSE
	anchored = TRUE
	can_buckle = 1
	layer = 2.8
	max_integrity = 40
	static_debris = list(/obj/item/natural/fibers = 1)