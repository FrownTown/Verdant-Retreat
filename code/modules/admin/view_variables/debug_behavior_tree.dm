/datum/behavior_tree_view
	var/mob/living/target
	var/datum/behavior_tree/node/parallel/root/root

/datum/behavior_tree_view/New(mob/living/M)
	target = M
	if(istype(target))
		root = target.ai_root

/datum/behavior_tree_view/ui_state(mob/user)
	return ADMIN_STATE("[R_DEBUG]")

/datum/behavior_tree_view/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "BehaviorTreeDebug")
		ui.open()

/datum/behavior_tree_view/ui_data(mob/user)
	var/list/data = list()
	if(!target || !root)
		data["has_ai"] = FALSE
		return data
	
	data["has_ai"] = TRUE
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

/datum/behavior_tree_view/ui_act(action, list/params)
	. = ..()
	if(.)
		return
