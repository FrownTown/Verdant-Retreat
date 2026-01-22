GLOBAL_LIST_INIT(bum_quotes, world.file2list("strings/rt/bumlines.txt"))
GLOBAL_LIST_INIT(bum_aggro, world.file2list("strings/rt/bumaggrolines.txt"))

/mob/living/carbon/human/species/human/northern/bum
	aggressive=0
	rude = TRUE
	faction = list("bums", "station")
	ambushable = FALSE
	dodgetime = 30
	flee_in_pain = TRUE
	possible_rmb_intents = list()

	wander = FALSE

/mob/living/carbon/human/species/human/northern/bum/ambush
	aggressive=1

	wander = TRUE

/mob/living/carbon/human/species/human/northern/bum/retaliate(mob/living/L)
	var/newtarg = target
	.=..()
	if(target)
		aggressive=1
		wander = TRUE
		if(target != newtarg)
			say(pick(GLOB.bum_aggro))
			pointed(target)

/mob/living/carbon/human/species/human/northern/bum/should_target(mob/living/L)
	if(L.stat != CONSCIOUS)
		return FALSE
	. = ..()

/mob/living/carbon/human/species/human/northern/bum/Initialize()
	. = ..()
	set_species(/datum/species/human/northern)
	addtimer(CALLBACK(src, PROC_REF(after_creation)), 1 SECONDS)

/mob/living/carbon/human/species/human/northern/bum/after_creation()
	..()
	job = "Beggar"
	ADD_TRAIT(src, TRAIT_NOMOOD, TRAIT_GENERIC)
	ADD_TRAIT(src, TRAIT_NOHUNGER, TRAIT_GENERIC)
	ADD_TRAIT(src, TRAIT_INFINITE_ENERGY, TRAIT_GENERIC)
	equipOutfit(new /datum/outfit/job/vagrant)

	// Initialize behavior tree AI
	init_ai_root(/datum/behavior_tree/node/selector/hostile_humanoid_tree)
	ai_root.next_move_delay = 3
	ai_root.next_attack_delay = CLICK_CD_MELEE
	SSai.Register(src)
