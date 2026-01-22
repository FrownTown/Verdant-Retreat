/obj/effect/admin_spawn/goblin_squad
	name = "goblin squad spawner"
	icon = 'icons/mob/effects/landmarks.dmi'
	icon_state = "x3"
	
/obj/effect/admin_spawn/goblin_squad/Initialize(mapload)
	. = ..()
	var/turf/T = get_turf(src)
	
	// Create leader
	var/mob/living/carbon/human/species/goblin/npc/leader = new(T)
	var/ai_squad/goblin/squad = new(leader)
	
	// Create followers around
	for(var/i in 1 to 5)
		var/turf/spawn_turf = get_ranged_target_turf(T, pick(GLOB.cardinals), rand(1,2))
		var/mob/living/carbon/human/species/goblin/npc/grunt = new(spawn_turf)
		squad.AddMember(grunt)
		
	qdel(src)
