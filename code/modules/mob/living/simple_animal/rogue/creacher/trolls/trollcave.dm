// Port from Vanderlin with AP code for throwing the rock
/mob/living/simple_animal/hostile/retaliate/rogue/troll/cave
	name = "cave troll"
	desc = "Dwarven tales of giants and trolls often contain these creatures, horrifying amalgamations of flesh and crystal who have long since abandoned Malum's ways."
	icon = 'icons/roguetown/mob/monster/trolls/troll_cave.dmi'
	health = CAVETROLL_HEALTH
	maxHealth = CAVETROLL_HEALTH

	botched_butcher_results = list (
		/obj/item/reagent_containers/food/snacks/rogue/meat/steak = 2,
		/obj/item/natural/bundle/bone/full = 1,
		/obj/item/alch/horn = 1, 
		/obj/item/natural/hide = 2)
	butcher_results = list(
		/obj/item/reagent_containers/food/snacks/rogue/meat/steak = 3,
		/obj/item/natural/hide = 3,
		/obj/item/natural/bundle/bone/full = 1,
		/obj/item/alch/sinew = 5,
		/obj/item/alch/horn = 2,
		/obj/item/alch/viscera = 3,
		/obj/item/natural/head/troll/cave = 1,
		)
	perfect_butcher_results = list(
		/obj/item/reagent_containers/food/snacks/rogue/meat/steak = 5,
		/obj/item/natural/hide = 5,
		/obj/item/natural/bundle/bone/full = 1, 
		/obj/item/alch/sinew = 7, 
		/obj/item/alch/horn = 2, 
		/obj/item/alch/viscera = 3,
		/obj/item/natural/head/troll/cave = 1,
		)

	defprob = 15

/mob/living/simple_animal/hostile/retaliate/rogue/troll/cave/Initialize(mapload)
	. = ..()
	var/datum/action/cooldown/mob_cooldown/stone_throw/throwstone = new(src)
	throwstone.Grant(src)

	// Initialize behavior tree with stone throw ability
	init_ai_root(/datum/behavior_tree/node/selector/direbear_tree)
	ai_root.blackboard["targeted_action"] = throwstone
	ai_root.next_move_delay = move_to_delay
	ai_root.next_attack_delay = TROLL_ATTACK_SPEED
