PROCESSING_SUBSYSTEM_DEF(ai_behaviors)
	name = "AI Behaviors"
	priority = SS_PRIORITY_AI
	flags = SS_KEEP_TIMING
	runlevels = RUNLEVEL_GAME
	wait = 1

	var/list/ai_behaviors = list()

/datum/controller/subsystem/processing/ai_behaviors/Initialize()
	..()
	// Initialize behaviors here if needed, or they register themselves
	for(var/type in subtypesof(/datum/ai_behavior))
		ai_behaviors[type] = new type()
	return INITIALIZE_HINT_LATELOAD
