/datum/behavior_tree_view
	var/mob/living/target
	var/datum/behavior_tree/node/parallel/root/root
	var/client/viewer
	var/image/outline_image

/datum/behavior_tree_view/New(client/C)
	viewer = C

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
	return ADMIN_STATE(R_DEBUG)

/datum/behavior_tree_view/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "BehaviorTreeDebug")
		ui.open()

/datum/behavior_tree_view/ui_data(mob/user)
	var/list/data = list()
	if(!target || !root)
		data["has_ai"] = FALSE
		data["selecting"] = TRUE
		return data

	data["has_ai"] = TRUE
	data["selecting"] = FALSE
	data["mob_name"] = target.name
	data["blackboard"] = list()

	if(root.blackboard)
		for(var/key in root.blackboard)
			var/value = root.blackboard[key]
			data["blackboard"][key] = "[value]" // Stringify for display

	data["tree"] = get_node_data(root)
	return data

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
				node_data["children"] += list(get_node_data(child))

	else if(istype(N, /datum/behavior_tree/node/sequence))
		var/datum/behavior_tree/node/sequence/S = N
		node_data["name"] = "Sequence"
		if(S.my_nodes)
			for(var/datum/behavior_tree/node/child in S.my_nodes)
				node_data["children"] += list(get_node_data(child))
	
	else if(istype(N, /datum/behavior_tree/node/decorator))
		var/datum/behavior_tree/node/decorator/D = N
		node_data["name"] = "Decorator"
		if(D.child)
			node_data["children"] += list(get_node_data(D.child))

	return node_data

/datum/behavior_tree_view/ui_close(mob/user)
	. = ..()
	cleanup()

/datum/behavior_tree_view/proc/cleanup()
	if(outline_image && viewer)
		viewer.images -= outline_image
		qdel(outline_image)
		outline_image = null
	target = null
	root = null
	if(viewer)
		viewer.click_intercept = null
		viewer.mouse_pointer_icon = null
		if(viewer.mob)
			viewer.mob.update_mouse_pointer()

/datum/behavior_tree_view/ui_act(action, list/params)
	. = ..()
	if(.)
		return

	switch(action)
		if("start_selecting")
			// Enable click intercept mode
			viewer.click_intercept = src
			viewer.mouse_pointer_icon = 'icons/effects/supplypod_target.dmi'
			return TRUE

/datum/behavior_tree_view/proc/InterceptClickOn(user, params, atom/target_atom)
	var/list/modifiers = params2list(params)
	if(modifiers["right"])
		// Right click cancels selection mode
		viewer.click_intercept = null
		viewer.mouse_pointer_icon = null
		viewer.mob.update_mouse_pointer()
		return TRUE

	if(istype(target_atom, /atom/movable/screen))
		return FALSE

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
		set_target(clicked_mob)
		SStgui.update_uis(src)
		to_chat(user, span_notice("Now debugging behavior tree for: [clicked_mob.name]"))

		// Disable click intercept after selection
		viewer.click_intercept = null
		viewer.mouse_pointer_icon = null
		viewer.mob.update_mouse_pointer()
	else
		to_chat(user, span_warning("No mob found at that location."))

	return TRUE
