// ==============================================================================
// COMBAT TEST SQUAD SPAWNERS
// ==============================================================================
// These spawners create balanced squads for testing AI combat behaviors

// ==============================================================================
// GOBLIN COMBAT SQUAD - Focus Fire Tactics
// ==============================================================================
/obj/effect/mob_spawner/combat_test_goblin_squad
	name = "Goblin Squad Spawner"
	desc = "Spawns a goblin squad with focus fire tactics"
	icon = 'icons/effects/effects.dmi'
	icon_state = "at_shield1"
	var/squad_size = 5
	var/leader_bonus = 1 // +1 to all stats and skills for leader

/obj/effect/mob_spawner/combat_test_goblin_squad/attack_hand(mob/living/user)
	. = ..()
	if(.)
		return

	to_chat(user, "<span class='notice'>Spawning goblin squad...</span>")
	spawn_squad()
	qdel(src)

/obj/effect/mob_spawner/combat_test_goblin_squad/proc/spawn_squad()
	var/turf/T = get_turf(src)
	if(!T)
		return

	var/list/spawned_goblins = list()
	var/mob/living/carbon/human/species/goblin/npc/leader

	// Spawn goblins
	for(var/i in 1 to squad_size)
		var/turf/spawn_turf = locate(T.x + rand(-2, 2), T.y + rand(-2, 2), T.z)
		if(!spawn_turf)
			spawn_turf = T

		var/mob/living/carbon/human/species/goblin/npc/goblin = new(spawn_turf)

		spawned_goblins += goblin

		// First goblin is leader
		if(i == 1)
			leader = goblin
			goblin.name = "goblin leader"
			goblin.real_name = "goblin leader"

			// Leader gets +1 to all stats
			goblin.STASTR += leader_bonus
			goblin.STASPD += leader_bonus
			goblin.STACON += leader_bonus
			goblin.STAEND += leader_bonus
			goblin.STAINT += leader_bonus
			goblin.STALUC += leader_bonus

			// Leader gets +1 to all skills
			goblin.adjust_skillrank(/datum/skill/combat/swords, leader_bonus, TRUE)
			goblin.adjust_skillrank(/datum/skill/combat/maces, leader_bonus, TRUE)
			goblin.adjust_skillrank(/datum/skill/combat/axes, leader_bonus, TRUE)
			goblin.adjust_skillrank(/datum/skill/combat/wrestling, leader_bonus, TRUE)
			goblin.adjust_skillrank(/datum/skill/combat/unarmed, leader_bonus, TRUE)
			goblin.adjust_skillrank(/datum/skill/combat/knives, leader_bonus, TRUE)
			goblin.adjust_skillrank(/datum/skill/misc/climbing, leader_bonus, TRUE)
			goblin.adjust_skillrank(/datum/skill/misc/athletics, leader_bonus, TRUE)

	// Create squad with focus fire tactics
	if(leader && length(spawned_goblins) > 1)
		var/ai_squad/goblin/squad = new(leader)
		for(var/mob/living/carbon/human/species/goblin/npc/goblin in spawned_goblins)
			if(goblin != leader)
				squad.AddMember(goblin)

		// Set focus fire tactic
		squad.set_tactic(/squad_tactic/focus_fire)

		to_chat(world, "<span class='boldannounce'>Goblin squad spawned with [length(spawned_goblins)] members using focus fire tactics!</span>")

// ==============================================================================
// BANDIT COMBAT SQUAD - Spread Out Tactics
// ==============================================================================
/obj/effect/mob_spawner/combat_test_bandit_squad
	name = "Bandit Squad Spawner"
	desc = "Spawns a bandit squad with spread out tactics"
	icon = 'icons/effects/effects.dmi'
	icon_state = "at_shield2"
	var/squad_size = 5
	var/leader_bonus = 1

/obj/effect/mob_spawner/combat_test_bandit_squad/attack_hand(mob/living/user)
	. = ..()
	if(.)
		return

	to_chat(user, "<span class='notice'>Spawning bandit squad...</span>")
	spawn_squad()
	qdel(src)

/obj/effect/mob_spawner/combat_test_bandit_squad/proc/spawn_squad()
	var/turf/T = get_turf(src)
	if(!T)
		return

	var/list/spawned_bandits = list()
	var/mob/living/carbon/human/species/human/northern/highwayman/leader

	// Spawn bandits (highwaymen)
	for(var/i in 1 to squad_size)
		var/turf/spawn_turf = locate(T.x + rand(-2, 2), T.y + rand(-2, 2), T.z)
		if(!spawn_turf)
			spawn_turf = T

		var/mob/living/carbon/human/species/human/northern/highwayman/bandit = new(spawn_turf)

		spawned_bandits += bandit

		// First bandit is leader
		if(i == 1)
			leader = bandit
			bandit.name = "bandit leader"
			bandit.real_name = "bandit leader"

			// Leader gets +1 to all stats
			bandit.STASTR += leader_bonus
			bandit.STASPD += leader_bonus
			bandit.STACON += leader_bonus
			bandit.STAEND += leader_bonus
			bandit.STAINT += leader_bonus
			bandit.STALUC += leader_bonus

			// Leader gets +1 to all skills
			bandit.adjust_skillrank(/datum/skill/combat/swords, leader_bonus, TRUE)
			bandit.adjust_skillrank(/datum/skill/combat/maces, leader_bonus, TRUE)
			bandit.adjust_skillrank(/datum/skill/combat/axes, leader_bonus, TRUE)
			bandit.adjust_skillrank(/datum/skill/combat/wrestling, leader_bonus, TRUE)
			bandit.adjust_skillrank(/datum/skill/combat/unarmed, leader_bonus, TRUE)
			bandit.adjust_skillrank(/datum/skill/combat/shields, leader_bonus, TRUE)
			bandit.adjust_skillrank(/datum/skill/combat/polearms, leader_bonus, TRUE)

	// Create squad with spread out tactics
	if(leader && length(spawned_bandits) > 1)
		var/ai_squad/squad = new(leader)
		for(var/mob/living/carbon/human/species/human/northern/highwayman/bandit in spawned_bandits)
			if(bandit != leader)
				squad.AddMember(bandit)

		// Set spread out tactic
		squad.set_tactic(/squad_tactic/spread_out)

		to_chat(world, "<span class='boldannounce'>Bandit squad spawned with [length(spawned_bandits)] members using spread out tactics!</span>")
