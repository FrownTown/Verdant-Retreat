// ==============================================================================
// BEHAVIOR TREE FRAMEWORK
// ==============================================================================

// The root node is also a general data holder for the mob's AI. It holds information about the mob's state, such as where it's going, who it's killing, etc. and tracks simple timestamp-based cooldown timers for various actions.
// Please make sure you only instantiate variables ON the root node... You could describe doing otherwise as "memory pollution."

/datum/behavior_tree/node
	var/node_state = NODE_FAILURE
	var/active_node_text // Debug text showing the currently running node

	#ifdef BT_DEBUG
	var/next_log_tick = 0
	var/next_log_delay = 5 SECONDS
	#endif

/datum/behavior_tree/node/parallel/root
	var/list/path // This should always be instantiated if we're creating a mob that has one of these anyways, but still do it in InitAI, not in a node definition.
	var/atom/move_destination // This is where we're going.
	var/atom/target // And this is who we're KILLING.
	var/atom/obj_target // And if we're targeting an object, we'll cast it here.
	var/datum/behavior_tree/node/main_node // Reference to the node that handles the main behavior tree
	var/datum/behavior_tree/node/move_node // Reference to the node that handles processing the mob's movement.

	var/alist/blackboard

	// These are timestamp variables to track when commonly-done things should happen. Very lightweight compared to a timer datum. These can get randomized later.
	// Anything that needs to be checked every tick should be stored here, rather than in the blackboard, to minimize list operations.

	var/next_think_tick // The world.time when this mob can think again.
	var/next_chatter_tick
	var/next_emote_tick
	var/next_attack_tick
	var/next_move_tick
	var/next_repath_tick
	var/next_sleep_tick

	var/next_think_delay // How many ticks to wait between AI evaluations. Default = 0.5s based on cycle_pause_fast
	var/next_chatter_delay
	var/next_emote_delay
	var/next_attack_delay
	var/next_move_delay
	var/next_repath_delay
	var/next_sleep_delay

	var/next_repath_default

	var/ai_flags // A bitfield
	var/current_command // If the mob is carrying out a command given by AI commander, we store its state here.

	var/list/bt_action_cache // For goap stuff.

	// These are caches that hold an instance of every goap_goal and goap_action subtype so the NPC can use them at will. This helps with performance by preventing either A)
	// having to create a new instance of a goap_goal or goap_action every time it's needed, or B) having to share the same instance of a goap_goal or goap_action between multiple NPCs and cause memory leaks and race conditions.
	var/list/goap_goals_cache
	var/list/goap_actions_cache

/mob/living/proc/init_ai_root(typepath)
	if(ai_root) return

	ai_root = new /datum/behavior_tree/node/parallel/root(typepath, src)
	ai_root.blackboard = new
	SSai.Register(src)


// =============================================================================
// UNUSED GOAP STUFF
// =============================================================================
// This comes from the GOAP implementation I wrote for IS12 Reborn. This is not
// currently used on this codebase, but may be useful in the future. If you're
// interested in GOAP, you will need to refactor these helpers to run on the
// parallel/root node.
/*
/datum/behavior_tree/node/proc/build_bt_action_index()
	if(!bt_action_cache)
		bt_action_cache = list()

	if(length(bt_action_cache))
		return
	_bt_index_walk(src)

/datum/behavior_tree/node/proc/_bt_index_walk(datum/behavior_tree/node/N)
	if(!N) return

	// If this is an action node, index the instance and key it to its typepath for easy access later.
	if(istype(N, /datum/behavior_tree/node/action))
		var/datum/behavior_tree/node/action/A = N
		if(A.my_action)
			var/path = A.my_action.type
			if(path && !bt_action_cache[path])
				bt_action_cache[path] = A.my_action
	else if(istype(N, /datum/behavior_tree/node/decorator))
		var/datum/behavior_tree/node/decorator/D = N
		_bt_index_walk(D.child)
	else if(istype(N, /datum/behavior_tree/node/sequence) || istype(N, /datum/behavior_tree/node/selector))
		var/list/nodes = N:my_nodes
		if(!nodes || !islist(nodes)) return
		for(var/datum/behavior_tree/node/child as anything in nodes)
			_bt_index_walk(child)

/datum/behavior_tree/node/proc/get_bt_action_instance(action_path)
	if(!ispath(action_path))
		return null
	return bt_action_cache[action_path]
*/

/datum/behavior_tree/node/proc/evaluate(mob/living/npc, atom/target, list/blackboard)
	return NODE_FAILURE

// This is a helper to check the timeout for special actions, like climbing ladders etc. It should only ever be called on a mob's ai_root node.
/datum/behavior_tree/node/parallel/root/proc/check_action_timeout(mob/living/user, duration = 2 SECONDS)
	if(!user.ai_root.blackboard[AIBLK_ACTION_TIMEOUT])
		user.ai_root.blackboard[AIBLK_ACTION_TIMEOUT] = world.time + duration
		return AI_ACTION_FIRST_ATTEMPT

	if(world.time > user.ai_root.blackboard[AIBLK_ACTION_TIMEOUT])
		return AI_ACTION_TIMED_OUT

	return AI_ACTION_WAITING

// SELECTOR (equivalent to logical OR)
// Tries each child node in order until one succeeds or is running. Fails if all children fail.
/datum/behavior_tree/node/selector
	var/list/my_nodes = list()

/datum/behavior_tree/node/selector/New()
	..()
	var/list/created = list()
	for (var/type in my_nodes)
		created += new type()
	my_nodes = created

/datum/behavior_tree/node/selector/evaluate(mob/living/npc, atom/target, list/blackboard)
	for(var/datum/behavior_tree/node/L as anything in my_nodes)
		switch(L.evaluate(npc, target, blackboard))
			if(NODE_FAILURE)
				continue
			if(NODE_SUCCESS)
				node_state = NODE_SUCCESS
				#ifdef BT_DEBUG
				if(world.time > next_log_tick)
					next_log_tick = world.time + next_log_delay
					var/state_string = "UNKNOWN"
					switch(node_state)
						if(NODE_SUCCESS) state_string = "SUCCESS"
						if(NODE_FAILURE) state_string = "FAILURE"
						if(NODE_RUNNING) state_string = "RUNNING"
					world.log << "BT DEBUG: [npc] -> Selector ([src.type]) -> [state_string]"
				#endif
				return node_state
			if(NODE_RUNNING)
				#ifdef BT_DEBUG
				if(world.time > next_log_tick)
					next_log_tick = world.time + next_log_delay
					var/state_string = "UNKNOWN"
					switch(node_state)
						if(NODE_SUCCESS) state_string = "SUCCESS"
						if(NODE_FAILURE) state_string = "FAILURE"
						if(NODE_RUNNING) state_string = "RUNNING"
					world.log << "BT DEBUG: [npc] -> Selector ([src.type]) -> [state_string]"
				#endif
				node_state = NODE_RUNNING
				return node_state
	node_state = NODE_FAILURE
	#ifdef BT_DEBUG
	if(world.time > next_log_tick)
		next_log_tick = world.time + next_log_delay
		var/state_string = "UNKNOWN"
		switch(node_state)
			if(NODE_SUCCESS) state_string = "SUCCESS"
			if(NODE_FAILURE) state_string = "FAILURE"
			if(NODE_RUNNING) state_string = "RUNNING"
		world.log << "BT DEBUG: [npc] -> Selector ([src.type]) -> [state_string]"
	#endif

	return node_state

/datum/behavior_tree/node/selector/Destroy()
	for(var/datum/D as anything in my_nodes)
		D.Destroy()
	my_nodes.len = 0
	. = ..()


// SEQUENCE (equivalent to logical AND)
// Runs each child node in order. Fails if any of its children do.
/datum/behavior_tree/node/sequence
	var/list/my_nodes = list()

/datum/behavior_tree/node/sequence/New()
	..()
	var/list/created = list()
	for (var/type in my_nodes)
		created += new type()
	my_nodes = created

/datum/behavior_tree/node/sequence/evaluate(mob/living/npc, atom/target, list/blackboard)
	for(var/datum/behavior_tree/node/L as anything in my_nodes)
		switch(L.evaluate(npc, target, blackboard))
			if(NODE_FAILURE)
				node_state = NODE_FAILURE
				#ifdef BT_DEBUG
				if(world.time > next_log_tick)
					next_log_tick = world.time + next_log_delay
					var/state_string = "UNKNOWN"
					switch(node_state)
						if(NODE_SUCCESS) state_string = "SUCCESS"
						if(NODE_FAILURE) state_string = "FAILURE"
						if(NODE_RUNNING) state_string = "RUNNING"
					world.log << "BT DEBUG: [npc] -> Sequence ([src.type]) -> [state_string]"
				#endif
				return node_state
			if(NODE_SUCCESS)
				continue
			if(NODE_RUNNING)
				node_state = NODE_RUNNING
				#ifdef BT_DEBUG
				if(world.time > next_log_tick)
					next_log_tick = world.time + next_log_delay
					var/state_string = "UNKNOWN"
					switch(node_state)
						if(NODE_SUCCESS) state_string = "SUCCESS"
						if(NODE_FAILURE) state_string = "FAILURE"
						if(NODE_RUNNING) state_string = "RUNNING"
					world.log << "BT DEBUG: [npc] -> Sequence ([src.type]) -> [state_string]"
				#endif
				return node_state
	node_state = NODE_SUCCESS
	#ifdef BT_DEBUG
	if(world.time > next_log_tick)
		next_log_tick = world.time + next_log_delay
		var/state_string = "UNKNOWN"
		switch(node_state)
			if(NODE_SUCCESS) state_string = "SUCCESS"
			if(NODE_FAILURE) state_string = "FAILURE"
			if(NODE_RUNNING) state_string = "RUNNING"
		world.log << "BT DEBUG: [npc] -> Sequence ([src.type]) -> [state_string]"
	#endif
	return node_state

/datum/behavior_tree/node/sequence/Destroy()
	// When a sequence is deleted, it tells all its children to delete themselves.
	for(var/datum/D as anything in my_nodes)
		D.Destroy()
	my_nodes.len = 0
	. = ..()

// PARALLEL
// Special node for situations where it is desirable to always run multiple nodes regardless of their state or return value.
// This is primarily used for separating thinking and movement trees, but could also have other applications.
// Always runs all children. Returns NODE_FAILURE if any fail; NODE_RUNNING if any are running and none failed; NODE_SUCCESS otherwise.
// Currently, the return values are not used for anything, but this may change in the future.
/datum/behavior_tree/node/parallel
	var/list/my_nodes = list()

/datum/behavior_tree/node/parallel/New()
	..()
	var/list/created = list()
	for (var/type in my_nodes)
		created += new type()
	my_nodes = created

/datum/behavior_tree/node/parallel/evaluate(mob/living/npc, atom/target, list/blackboard)
	var/any_running = FALSE
	var/any_failed = FALSE
	for(var/datum/behavior_tree/node/L as anything in my_nodes)
		var/result = L.evaluate(npc, target, blackboard)
		if(result == NODE_FAILURE)
			any_failed = TRUE
		else if(result == NODE_RUNNING)
			any_running = TRUE
	
	if(any_failed)
		node_state = NODE_FAILURE
	else if(any_running)
		node_state = NODE_RUNNING
	else
		node_state = NODE_SUCCESS
	return node_state

/datum/behavior_tree/node/parallel/Destroy()
	for(var/datum/D as anything in my_nodes)
		D.Destroy()
	my_nodes.len = 0
	. = ..()

// ACTION (These are the "leaf" nodes that do the actual work by running bt_action datums.)
// This is a wrapper class. Each instance can hold a specific action datum.
/datum/behavior_tree/node/action
	var/bt_action/my_action
	var/invert = FALSE // If TRUE, success becomes failure and vice-versa.

/datum/behavior_tree/node/action/New(set_invert)
	..()
	if(my_action)
		my_action = new my_action()
	if(set_invert)
		invert = set_invert

/datum/behavior_tree/node/action/evaluate(mob/living/npc, atom/target, list/blackboard)
	if(!my_action)
		#ifdef BT_DEBUG
		if(world.time > next_log_tick)
			next_log_tick = world.time + next_log_delay
			var/state_string = "UNKNOWN"
			switch(node_state)
				if(NODE_SUCCESS) state_string = "SUCCESS"
				if(NODE_FAILURE) state_string = "FAILURE"
				if(NODE_RUNNING) state_string = "RUNNING"
			world.log << "BT DEBUG: [npc] -> Action ([src.type]) -> [state_string] due to missing bt_action from [src.type]!"
		#endif
		return NODE_FAILURE

	switch(my_action.evaluate(npc, target, blackboard))
		if(NODE_SUCCESS)
			node_state = invert ? NODE_FAILURE : NODE_SUCCESS
			#ifdef BT_DEBUG
			if(world.time > next_log_tick)
				next_log_tick = world.time + next_log_delay
				var/state_string = "UNKNOWN"
				switch(node_state)
					if(NODE_SUCCESS) state_string = "SUCCESS"
					if(NODE_FAILURE) state_string = "FAILURE"
					if(NODE_RUNNING) state_string = "RUNNING"
				world.log << "BT DEBUG: [npc] -> Action ([src.type]) -> [state_string]"
			#endif
			return node_state
		if(NODE_FAILURE)
			node_state = invert ? NODE_SUCCESS : NODE_FAILURE
			#ifdef BT_DEBUG
			if(world.time > next_log_tick)
				next_log_tick = world.time + next_log_delay
				var/state_string = "UNKNOWN"
				switch(node_state)
					if(NODE_SUCCESS) state_string = "SUCCESS"
					if(NODE_FAILURE) state_string = "FAILURE"
					if(NODE_RUNNING) state_string = "RUNNING"
				world.log << "BT DEBUG: [npc] -> Action ([src.type]) -> [state_string]"
			#endif
			return node_state
		if(NODE_RUNNING)
			node_state = NODE_RUNNING
			if(npc.ai_root)
				var/txt = "[my_action.type]"
				var/last_slash = findlasttext(txt, "/")
				if(last_slash)
					txt = copytext(txt, last_slash + 1)
				npc.ai_root.active_node_text = txt

			#ifdef BT_DEBUG
			if(world.time > next_log_tick)
				next_log_tick = world.time + next_log_delay
				var/state_string = "UNKNOWN"
				switch(node_state)
					if(NODE_SUCCESS) state_string = "SUCCESS"
					if(NODE_FAILURE) state_string = "FAILURE"
					if(NODE_RUNNING) state_string = "RUNNING"
				world.log << "BT DEBUG: [npc] -> Action ([src.type]) -> [state_string]"
			#endif
			return node_state

	#ifdef BT_DEBUG
	if(world.time > next_log_tick)
		next_log_tick = world.time + next_log_delay
		var/state_string = "UNKNOWN"
		switch(node_state)
			if(NODE_SUCCESS) state_string = "SUCCESS"
			if(NODE_FAILURE) state_string = "FAILURE"
			if(NODE_RUNNING) state_string = "RUNNING"
		world.log << "BT DEBUG: [npc] -> Action ([src.type]) -> [state_string]"
	#endif

	return NODE_FAILURE

/datum/behavior_tree/node/action/Destroy()
	// The action wrapper also needs to clean up the action datum it holds.
	my_action.Destroy()
	. = ..(QDEL_HINT_IWILLGC)

// Decorator node, for things like Inverters, Succeeders, etc.
/datum/behavior_tree/node/decorator
	var/datum/behavior_tree/node/child

/datum/behavior_tree/node/decorator/New()
	..()
	if(child)
		child = new child()

/datum/behavior_tree/node/decorator/Destroy()
	if(child)
		child.Destroy()
	. = ..(QDEL_HINT_IWILLGC)
