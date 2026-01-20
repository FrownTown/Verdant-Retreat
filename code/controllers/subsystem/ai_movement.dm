PROCESSING_SUBSYSTEM_DEF(ai_movement)
	name = "AI Movement"
	priority = SS_PRIORITY_AI
	flags = SS_KEEP_TIMING
	runlevels = RUNLEVEL_GAME
	wait = 1

	var/list/movement_types = list()

/datum/controller/subsystem/processing/ai_movement/Initialize()
	..()
	for(var/type in subtypesof(/datum/ai_movement))
		movement_types[type] = new type()
	return INITIALIZE_HINT_LATELOAD
