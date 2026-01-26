// Global hash lookup table - built once on first use
GLOBAL_LIST_EMPTY(aiblk_hash_lookup)

/proc/reverse_lookup_hash(hash_value)
	if(!isnum(hash_value))
		return "[hash_value]"

	// Build lookup table on first use
	if(!length(GLOB.aiblk_hash_lookup))
		GLOB.aiblk_hash_lookup = list(
			"[AIBLK_LAST_TARGET]" = "AIBLK_LAST_TARGET", "[AIBLK_LAST_KNOWN_TARGET_LOC]" = "AIBLK_LAST_KNOWN_TARGET_LOC",
			"[AIBLK_PURSUE_TIME]" = "AIBLK_PURSUE_TIME", "[AIBLK_SEARCH_TIME]" = "AIBLK_SEARCH_TIME",
			"[AIBLK_SEARCH_START_TIME]" = "AIBLK_SEARCH_START_TIME", "[AIBLK_PURSUE_START_TIME]" = "AIBLK_PURSUE_START_TIME",
			"[AIBLK_FLEE_DIST]" = "AIBLK_FLEE_DIST", "[AIBLK_ACTION_TIMEOUT]" = "AIBLK_ACTION_TIMEOUT",
			"[AIBLK_TARGET_LOST_TIMER]" = "AIBLK_TARGET_LOST_TIMER", "[AIBLK_HIBERNATION_TIMER]" = "AIBLK_HIBERNATION_TIMER",
			"[AIBLK_FIND_TARGET_TIMER]" = "AIBLK_FIND_TARGET_TIMER", "[AIBLK_AGGRESSORS]" = "AIBLK_AGGRESSORS",
			"[AIBLK_AGRSR_RST_TMR]" = "AIBLK_AGRSR_RST_TMR", "[AIBLK_EXHAUSTED]" = "AIBLK_EXHAUSTED",
			"[AIBLK_KEEPAWAY_DIST]" = "AIBLK_KEEPAWAY_DIST", "[AIBLK_STAND_UP_TIMER]" = "AIBLK_STAND_UP_TIMER",
			"[AIBLK_UNDER_FIRE]" = "AIBLK_UNDER_FIRE", "[AIBLK_LAST_ATTACKER]" = "AIBLK_LAST_ATTACKER",
			"[AIBLK_IN_COVER]" = "AIBLK_IN_COVER", "[AIBLK_COVER_TIMER]" = "AIBLK_COVER_TIMER",
			"[AIBLK_MOVE_ACTIVE]" = "AIBLK_MOVE_ACTIVE", "[AIBLK_CHASE_TIMEOUT]" = "AIBLK_CHASE_TIMEOUT",
			"[AIBLK_ATTACKED_OBSTACLE]" = "AIBLK_ATTACKED_OBSTACLE", "[AIBLK_AI_COMMANDER]" = "AIBLK_AI_COMMANDER",
			"[AIBLK_BUMBLE_STATE]" = "AIBLK_BUMBLE_STATE", "[AIBLK_BUMBLE_NEXT_TICK]" = "AIBLK_BUMBLE_NEXT_TICK",
			"[AIBLK_COMBAT_STYLE]" = "AIBLK_COMBAT_STYLE", "[AIBLK_GRABBING]" = "AIBLK_GRABBING",
			"[AIBLK_BURST_COUNT]" = "AIBLK_BURST_COUNT", "[AIBLK_HIGH_VALUE_TARGET]" = "AIBLK_HIGH_VALUE_TARGET",
			"[AIBLK_STRAGGLER_TARGET]" = "AIBLK_STRAGGLER_TARGET", "[AIBLK_TIME_WAIT]" = "AIBLK_TIME_WAIT",
			"[AIBLK_AGGRO_LIST]" = "AIBLK_AGGRO_LIST", "[AIBLK_TIMER_DELAY]" = "AIBLK_TIMER_DELAY",
			"[AIBLK_BURROWING]" = "AIBLK_BURROWING", "[AIBLK_IS_ACTIVE]" = "AIBLK_IS_ACTIVE",
			"[AIBLK_CHARGE_RATE]" = "AIBLK_CHARGE_RATE", "[AIBLK_CURRENT_TARGET]" = "AIBLK_CURRENT_TARGET",
			"[AIBLK_SIGHT_RANGE]" = "AIBLK_SIGHT_RANGE", "[AIBLK_AGGRO_TICK]" = "AIBLK_AGGRO_TICK",
			"[AIBLK_HAS_ATTACKED]" = "AIBLK_HAS_ATTACKED", "[AIBLK_IDLE_SOUNDS]" = "AIBLK_IDLE_SOUNDS",
			"[AIBLK_IDLE_SOUND_TIMER]" = "AIBLK_IDLE_SOUND_TIMER", "[AIBLK_THREAT_SOUND]" = "AIBLK_THREAT_SOUND",
			"[AIBLK_THREAT_MESSAGE]" = "AIBLK_THREAT_MESSAGE", "[AIBLK_AGGRO_THRESHOLD]" = "AIBLK_AGGRO_THRESHOLD",
			"[AIBLK_CRITTER_PATH]" = "AIBLK_CRITTER_PATH", "[AIBLK_ATTACK_LIST]" = "AIBLK_ATTACK_LIST",
			"[AIBLK_IDEAL_RANGE]" = "AIBLK_IDEAL_RANGE", "[AIBLK_OBJECT_HIT]" = "AIBLK_OBJECT_HIT",
			"[AIBLK_BLOODTYPE]" = "AIBLK_BLOODTYPE", "[AIBLK_BLOODCOLOR]" = "AIBLK_BLOODCOLOR",
			"[AIBLK_HARVEST_LIST]" = "AIBLK_HARVEST_LIST", "[AIBLK_DAMAGE_OVERLAY]" = "AIBLK_DAMAGE_OVERLAY",
			"[AIBLK_OVERLAY_UPDATED]" = "AIBLK_OVERLAY_UPDATED", "[AIBLK_S_ACTION]" = "AIBLK_S_ACTION",
			"[AIBLK_AGGRESSION]" = "AIBLK_AGGRESSION", "[AIBLK_PATH_BLOCKED_COUNT]" = "AIBLK_PATH_BLOCKED_COUNT",
			"[AIBLK_SQUAD_ROLE]" = "AIBLK_SQUAD_ROLE", "[AIBLK_SQUAD_MATES]" = "AIBLK_SQUAD_MATES",
			"[AIBLK_SQUAD_SIZE]" = "AIBLK_SQUAD_SIZE", "[AIBLK_CHECK_TARGET]" = "AIBLK_CHECK_TARGET",
			"[AIBLK_CHOSEN_TARGET]" = "AIBLK_CHOSEN_TARGET", "[AIBLK_COMMAND_MODE]" = "AIBLK_COMMAND_MODE",
			"[AIBLK_DEFENDING_FROM_INTERRUPT]" = "AIBLK_DEFENDING_FROM_INTERRUPT", "[AIBLK_EATING_BODY]" = "AIBLK_EATING_BODY",
			"[AIBLK_FOLLOW_TARGET]" = "AIBLK_FOLLOW_TARGET", "[AIBLK_FOOD_TARGET]" = "AIBLK_FOOD_TARGET",
			"[AIBLK_FRIEND_REF]" = "AIBLK_FRIEND_REF", "[AIBLK_IGNORED_TARGETS]" = "AIBLK_IGNORED_TARGETS",
			"[AIBLK_IS_PINNING]" = "AIBLK_IS_PINNING", "[AIBLK_LAST_TARGET_SWITCH_TIME]" = "AIBLK_LAST_TARGET_SWITCH_TIME",
			"[AIBLK_MINION_FOLLOW_TARGET]" = "AIBLK_MINION_FOLLOW_TARGET", "[AIBLK_MINION_TRAVEL_DEST]" = "AIBLK_MINION_TRAVEL_DEST",
			"[AIBLK_PERFORM_EMOTE_ID]" = "AIBLK_PERFORM_EMOTE_ID", "[AIBLK_POSSIBLE_TARGETS]" = "AIBLK_POSSIBLE_TARGETS",
			"[AIBLK_REINFORCEMENTS_COOLDOWN]" = "AIBLK_REINFORCEMENTS_COOLDOWN", "[AIBLK_REINFORCEMENTS_SAY]" = "AIBLK_REINFORCEMENTS_SAY",
			"[AIBLK_TAMED]" = "AIBLK_TAMED", "[AIBLK_USE_TARGET]" = "AIBLK_USE_TARGET",
			"[AIBLK_VALID_TARGETS]" = "AIBLK_VALID_TARGETS", "[AIBLK_VIOLATION_INTERRUPTED]" = "AIBLK_VIOLATION_INTERRUPTED",
			"[AIBLK_DRAG_START_LOC]" = "AIBLK_DRAG_START_LOC", "[AIBLK_NEXT_HUNGER_CHECK]" = "AIBLK_NEXT_HUNGER_CHECK",
			"[AIBLK_PERFORM_SPEECH_TEXT]" = "AIBLK_PERFORM_SPEECH_TEXT", "[AIBLK_TARGETED_ACTION]" = "AIBLK_TARGETED_ACTION",
			"[AIBLK_DEADITE_MIGRATION_PATH]" = "AIBLK_DEADITE_MIGRATION_PATH", "[AIBLK_SQUAD_DATUM]" = "AIBLK_SQUAD_DATUM",
			"[AIBLK_SQUAD_PRIORITY_TARGET]" = "AIBLK_SQUAD_PRIORITY_TARGET", "[AIBLK_SQUAD_KNOWN_ENEMIES]" = "AIBLK_SQUAD_KNOWN_ENEMIES",
			"[AIBLK_SQUAD_TACTICAL_TARGET]" = "AIBLK_SQUAD_TACTICAL_TARGET", "[AIBLK_SQUAD_PRIORITY_TARGET_IN_COVER]" = "AIBLK_SQUAD_PRIORITY_TARGET_IN_COVER",
			"[AIBLK_SQUAD_HUNT_TARGET]" = "AIBLK_SQUAD_HUNT_TARGET", "[AIBLK_SQUAD_SHOULD_REGROUP]" = "AIBLK_SQUAD_SHOULD_REGROUP",
			"[AIBLK_SQUAD_PATROL_TARGET]" = "AIBLK_SQUAD_PATROL_TARGET", "[AIBLK_SQUAD_HUNT_LOCATION]" = "AIBLK_SQUAD_HUNT_LOCATION",
			"[AIBLK_MONSTER_BAIT]" = "AIBLK_MONSTER_BAIT", "[AIBLK_RESTRAIN_STATE]" = "AIBLK_RESTRAIN_STATE"
		)

	var/key_str = "[hash_value]"
	return GLOB.aiblk_hash_lookup[key_str] || key_str

/datum/behavior_tree_view
	var/mob/living/target
	var/datum/behavior_tree/node/parallel/root/root
	var/client/viewer
	var/image/outline_image
	var/list/selected_mobs = list()
	var/list/selection_images = list()
	var/selecting_mode = FALSE
	var/atom/drag_start

/datum/behavior_tree_view/New(client/C)
	viewer = C
	selected_mobs = list()
	selection_images = list()

/datum/behavior_tree_view/proc/set_target(mob/living/M)
	// Remove outline from old target
	if(outline_image && viewer)
		viewer.images -= outline_image
		qdel(outline_image)
		outline_image = null

	target = M
	if(istype(target))
		root = target.ai_root
		// Add outline to new target (client-only image)
		outline_image = image(target, loc = target)
		outline_image.override = TRUE
		outline_image.appearance = target.appearance
		outline_image.filters += filter(type = "outline", size = 2, color = "#00ffff")
		viewer.images += outline_image
	else
		root = null

/datum/behavior_tree_view/ui_state(mob/user)
	if(!GLOB.admin_states["[R_DEBUG]"])
		GLOB.admin_states["[R_DEBUG]"] = new /datum/ui_state/admin_state(R_DEBUG)
	return GLOB.admin_states["[R_DEBUG]"]

/datum/behavior_tree_view/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "BehaviorTreeDebug")
		ui.open()

/datum/behavior_tree_view/ui_data(mob/user)
	var/list/data = list()

	// Always provide selection and spawn data
	data["selected_count"] = length(selected_mobs)
	var/list/selected_list = list()
	for(var/mob/living/M in selected_mobs)
		selected_list += M.name
	data["selected_mobs"] = selected_list
	data["spawn_categories"] = get_spawn_categories()

	// Check if we have a target with AI
	if(!target || !root)
		data["has_ai"] = FALSE
		data["selecting"] = FALSE
		data["mob_name"] = ""
		data["blackboard"] = list()
		data["tree"] = null
		return data

	data["has_ai"] = TRUE
	data["selecting"] = FALSE
	data["mob_name"] = target.name
	data["blackboard"] = list()

	if(root.blackboard)
		for(var/key in root.blackboard)
			var/value = root.blackboard[key]
			// Convert integer hash keys to strings for JSON compatibility
			var/key_str = reverse_lookup_hash(key)
			data["blackboard"] += list(list("key" = key_str, "value" = "[value]"))

	data["tree"] = get_node_data(root)

	return data

/datum/behavior_tree_view/proc/get_spawn_categories()
	var/list/categories = list()

	// Goblins
	var/list/goblins = list()
	goblins["Goblin"] = "/mob/living/carbon/human/species/goblin/npc"
	goblins["Goblin (Ambush)"] = "/mob/living/carbon/human/species/goblin/npc/ambush"
	goblins["Hell Goblin"] = "/mob/living/carbon/human/species/goblin/npc/hell"
	goblins["Cave Goblin"] = "/mob/living/carbon/human/species/goblin/npc/cave"
	goblins["Sea Goblin"] = "/mob/living/carbon/human/species/goblin/npc/sea"
	categories["Goblins"] = goblins

	// Humanoids
	var/list/humanoids = list()
	humanoids["Highwayman"] = "/mob/living/carbon/human/species/human/northern/highwayman"
	humanoids["Highwayman (Ambush)"] = "/mob/living/carbon/human/species/human/northern/highwayman/ambush"
	categories["Humanoids"] = humanoids

	// Squads
	var/list/squads = list()
	squads["Goblin Squad (Focus Fire)"] = "/obj/effect/mob_spawner/combat_test_goblin_squad"
	squads["Bandit Squad (Spread Out)"] = "/obj/effect/mob_spawner/combat_test_bandit_squad"
	categories["Combat Squads"] = squads

	return categories

/datum/behavior_tree_view/proc/get_node_data(datum/behavior_tree/node/N)
	if(!N)
		return null

	var/list/node_data = list()
	node_data["type"] = "[N.type]"
	node_data["state"] = N.node_state
	node_data["children"] = list()
	node_data["name"] = node_data["type"] // Default name

	if(istype(N, /datum/behavior_tree/node/action))
		var/datum/behavior_tree/node/action/A = N
		if(A.my_action)
			node_data["name"] = "[A.my_action.type]"
			// Clean up name for display
			var/last_slash = findlasttext(node_data["name"], "/")
			if(last_slash)
				node_data["name"] = copytext(node_data["name"], last_slash + 1)

	else if(istype(N, /datum/behavior_tree/node/selector))
		var/datum/behavior_tree/node/selector/S = N
		node_data["name"] = "Selector"
		if(S.my_nodes)
			for(var/datum/behavior_tree/node/child in S.my_nodes)
				var/child_data = get_node_data(child)
				if(child_data)
					node_data["children"] += list(child_data)

	else if(istype(N, /datum/behavior_tree/node/sequence))
		var/datum/behavior_tree/node/sequence/S = N
		node_data["name"] = "Sequence"
		if(S.my_nodes)
			for(var/datum/behavior_tree/node/child in S.my_nodes)
				var/child_data = get_node_data(child)
				if(child_data)
					node_data["children"] += list(child_data)

	else if(istype(N, /datum/behavior_tree/node/decorator))
		var/datum/behavior_tree/node/decorator/D = N
		node_data["name"] = "Decorator"
		if(D.child)
			var/child_data = get_node_data(D.child)
			if(child_data)
				node_data["children"] += list(child_data)

	else if(istype(N, /datum/behavior_tree/node/parallel))
		var/datum/behavior_tree/node/parallel/P = N
		node_data["name"] = "Parallel"
		if(P.my_nodes)
			for(var/datum/behavior_tree/node/child in P.my_nodes)
				var/child_data = get_node_data(child)
				if(child_data)
					node_data["children"] += list(child_data)

	return node_data

/datum/behavior_tree_view/ui_close(mob/user)
	. = ..()
	cleanup()

/datum/behavior_tree_view/proc/cleanup()
	if(outline_image && viewer)
		viewer.images -= outline_image
		qdel(outline_image)
		outline_image = null
	clear_selections()
	target = null
	root = null
	if(viewer)
		viewer.click_intercept = null
		viewer.mouse_pointer_icon = null
		if(viewer.mob)
			viewer.mob.update_mouse_pointer()

/datum/behavior_tree_view/proc/clear_selections()
	if(viewer)
		for(var/image/I in selection_images)
			viewer.images -= I
			qdel(I)
	selection_images = list()
	selected_mobs = list()

/datum/behavior_tree_view/proc/add_to_selection(mob/living/M)
	if(M in selected_mobs)
		return
	selected_mobs += M
	var/image/sel_img = new /image
	sel_img.override = TRUE
	sel_img.appearance = M.appearance
	sel_img.loc = M
	sel_img.filters += filter(type = "outline", size = 2, color = "#ffff00")
	selection_images += sel_img
	if(viewer)
		viewer.images += sel_img

/datum/behavior_tree_view/proc/remove_from_selection(mob/living/M)
	var/index = selected_mobs.Find(M)
	if(!index)
		return
	selected_mobs -= M
	var/image/sel_img = selection_images[index]
	if(viewer)
		viewer.images -= sel_img
	qdel(sel_img)
	selection_images -= sel_img

/datum/behavior_tree_view/ui_act(action, list/params)
	to_chat(viewer.mob, span_notice("DEBUG ui_act ENTRY: action=[action]"))
	. = ..()
	to_chat(viewer.mob, span_notice("DEBUG parent returned: [.]"))
	if(.)
		return

	to_chat(viewer.mob, span_notice("DEBUG ui_act: action=[action]"))

	switch(action)
		if("start_selecting")
			// Enable click intercept mode
			viewer.click_intercept = src
			viewer.mouse_pointer_icon = 'icons/effects/mousemice/human_looking.dmi'
			selecting_mode = TRUE
			return TRUE

		if("clear_selection")
			clear_selections()
			return TRUE

		if("spawn_mob")
			var/path_string = params["path"]
			to_chat(viewer.mob, span_notice("DEBUG: Attempting to spawn: [path_string]"))
			var/mob_path = text2path(path_string)
			if(!ispath(mob_path))
				to_chat(viewer.mob, span_warning("Invalid mob path: [path_string]"))
				return TRUE

			var/turf/spawn_loc = get_turf(viewer.mob)
			if(ispath(mob_path, /obj/effect/mob_spawner))
				var/obj/effect/mob_spawner/spawner = new mob_path(spawn_loc)
				spawner.attack_hand(viewer.mob)
				to_chat(viewer.mob, span_notice("Spawned squad spawner"))
			else if(ispath(mob_path, /mob/living))
				var/mob/living/new_mob = new mob_path(spawn_loc)
				to_chat(viewer.mob, span_notice("Spawned [new_mob.name] at your location"))
			else
				to_chat(viewer.mob, span_warning("Path is not a mob or spawner: [mob_path]"))
			return TRUE

		if("delete_selected")
			for(var/mob/living/M in selected_mobs)
				qdel(M)
			clear_selections()
			to_chat(viewer.mob, span_notice("Deleted selected mobs"))
			return TRUE

/datum/behavior_tree_view/proc/InterceptClickOn(user, params, atom/target_atom)
	var/list/modifiers = params2list(params)
	if(modifiers["right"])
		// Right click cancels selection mode
		viewer.click_intercept = null
		viewer.mouse_pointer_icon = null
		viewer.mob.update_mouse_pointer()
		selecting_mode = FALSE
		drag_start = null
		return TRUE

	if(istype(target_atom, /atom/movable/screen))
		return FALSE

	// Check if ctrl-click for multi-select
	var/is_ctrl = modifiers["ctrl"]

	// Check if clicked on a living mob
	var/mob/living/clicked_mob = null
	if(isliving(target_atom))
		clicked_mob = target_atom
	else
		// Check if there's a mob at that location
		var/turf/T = get_turf(target_atom)
		if(T)
			for(var/mob/living/M in T)
				clicked_mob = M
				break

	if(clicked_mob)
		if(is_ctrl)
			// Multi-select with ctrl
			if(clicked_mob in selected_mobs)
				remove_from_selection(clicked_mob)
			else
				add_to_selection(clicked_mob)
			SStgui.update_uis(src)
		else
			// Single select - debug this mob
			set_target(clicked_mob)
			SStgui.update_uis(src)
			to_chat(user, span_notice("Now debugging behavior tree for: [clicked_mob.name]"))

			// Disable click intercept after selection
			viewer.click_intercept = null
			viewer.mouse_pointer_icon = null
			viewer.mob.update_mouse_pointer()
			selecting_mode = FALSE
	else
		to_chat(user, span_warning("No mob found at that location."))

	return TRUE

// Handle drag start
/datum/behavior_tree_view/proc/InterceptMouseDown(user, params, atom/object)
	var/list/modifiers = params2list(params)
	if(modifiers["shift"])
		drag_start = get_turf(object)
		return TRUE
	return FALSE

// Handle drag end - select all mobs in rectangle
/datum/behavior_tree_view/proc/InterceptMouseUp(user, params, atom/object)
	if(!drag_start)
		return FALSE

	var/turf/drag_end = get_turf(object)
	if(!drag_end)
		drag_start = null
		return FALSE

	// Get rectangle bounds
	var/min_x = min(drag_start.x, drag_end.x)
	var/max_x = max(drag_start.x, drag_end.x)
	var/min_y = min(drag_start.y, drag_end.y)
	var/max_y = max(drag_start.y, drag_end.y)
	var/z = drag_start.z

	// Select all mobs in rectangle
	clear_selections()
	for(var/mob/living/M in GLOB.mob_list)
		var/turf/M_turf = get_turf(M)
		if(!M_turf || M_turf.z != z)
			continue
		if(M_turf.x >= min_x && M_turf.x <= max_x && M_turf.y >= min_y && M_turf.y <= max_y)
			add_to_selection(M)

	SStgui.update_uis(src)
	to_chat(user, span_notice("Selected [length(selected_mobs)] mobs"))

	drag_start = null
	return TRUE
