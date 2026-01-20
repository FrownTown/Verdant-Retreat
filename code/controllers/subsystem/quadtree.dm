// ==============================================================================
// QUADTREE SUBSYSTEM
// ==============================================================================

PROCESSING_SUBSYSTEM_DEF(quadtree)
	name = "Quadtree"
	wait = 0.5 SECONDS
	priority = SS_PRIORITY_QUADTREE
	init_order = INIT_ORDER_QUADTREE
	runlevels = RUNLEVELS_DEFAULT
	flags = SS_KEEP_TIMING

	var/list/cur_quadtrees
	var/list/new_quadtrees
	var/list/player_feed

	var/list/cur_npc_carbon_quadtrees
	var/list/new_npc_carbon_quadtrees
	var/list/npc_carbon_feed

	var/list/cur_npc_simple_quadtrees
	var/list/new_npc_simple_quadtrees
	var/list/npc_simple_feed

	var/list/cur_hearable_quadtrees
	var/list/new_hearable_quadtrees
	var/list/hearable_feed

	var/list/unregister_queue


/datum/controller/subsystem/processing/quadtree/Initialize()
	NEW_SS_GLOBAL(SSquadtree)

	cur_quadtrees = new/list(world.maxz)
	new_quadtrees = new/list(world.maxz)
	cur_npc_carbon_quadtrees = new/list(world.maxz)
	new_npc_carbon_quadtrees = new/list(world.maxz)
	cur_npc_simple_quadtrees = new/list(world.maxz)
	new_npc_simple_quadtrees = new/list(world.maxz)
	cur_hearable_quadtrees = new/list(world.maxz)
	new_hearable_quadtrees = new/list(world.maxz)
	npc_carbon_feed = list()
	npc_simple_feed = list()
	hearable_feed = list()
	unregister_queue = list()

	var/datum/shape/rectangle/R
	for(var/i in 1 to world.maxz)
		R = RECT(world.maxx/2, world.maxy/2, world.maxx, world.maxy)
		new_quadtrees[i] = QTREE(R, i)
		new_npc_carbon_quadtrees[i] = QTREE(R, i)
		new_npc_simple_quadtrees[i] = QTREE(R, i)
		new_hearable_quadtrees[i] = QTREE(R, i)

/datum/controller/subsystem/processing/quadtree/fire(resumed = FALSE)
	if(!resumed)
		if(length(unregister_queue))
			for(var/mob/M as anything in unregister_queue)
				if(M.client)
					player_feed -= M

				else if(iscarbon(M))
					npc_carbon_feed -= M

				else if(issimple(M))
					npc_simple_feed -= M

			
		// --- Reset Player Trees ---
		player_feed = GLOB.player_list.Copy()
		cur_quadtrees = new_quadtrees
		new_quadtrees = new/list(world.maxz)
		for(var/i in 1 to world.maxz)
			new_quadtrees[i] = QTREE(RECT(world.maxx/2,world.maxy/2, world.maxx, world.maxy), i)

		// --- Reset NPC Trees ---
		var/list/npc_feeds = GLOB.npc_list.Copy()
		var/list/carbon_feed = list()
		var/list/simple_feed = list()
		
		for(var/mob/living/M as anything in npc_feeds)
			if(iscarbon(M))
				carbon_feed += M
			else if(issimple(M))
				simple_feed += M

		npc_carbon_feed = carbon_feed
		cur_npc_carbon_quadtrees = new_npc_carbon_quadtrees
		new_npc_carbon_quadtrees = new/list(world.maxz)
		for(var/i in 1 to world.maxz)
			new_npc_carbon_quadtrees[i] = QTREE(RECT(world.maxx/2,world.maxy/2, world.maxx, world.maxy), i)

		// --- Reset NPC Simple Trees ---
		npc_simple_feed = simple_feed
		for(var/i in 1 to 4)
			for(var/mob/living/simple_animal/M as anything in GLOB.simple_animals[i])
				npc_simple_feed += M

		cur_npc_simple_quadtrees = new_npc_simple_quadtrees
		new_npc_simple_quadtrees = new/list(world.maxz)
		for(var/i in 1 to world.maxz)
			new_npc_simple_quadtrees[i] = QTREE(RECT(world.maxx/2,world.maxy/2, world.maxx, world.maxy), i)

		// --- Reset Hearable Trees ---
		hearable_feed = GLOB.hearables.Copy()
		cur_hearable_quadtrees = new_hearable_quadtrees
		new_hearable_quadtrees = new/list(world.maxz)
		for(var/i in 1 to world.maxz)
			new_hearable_quadtrees[i] = QTREE(RECT(world.maxx/2,world.maxy/2, world.maxx, world.maxy), i)


	// --- Populate Player Trees ---
	while(length(player_feed))
		var/mob/mob_found = player_feed[length(player_feed)]
		player_feed.len--
		if(!mob_found) continue
		var/turf/T = get_turf(mob_found)
		if(!T?.z || length(new_quadtrees) < T.z) continue
		var/coords/qtplayer/p_coords = new /coords/qtplayer
		p_coords.player = mob_found
		p_coords.x_pos = T.x
		p_coords.y_pos = T.y
		p_coords.z_pos = T.z
		if(isobserver(mob_found))
			p_coords.is_observer = TRUE
		var/datum/quadtree/QT = new_quadtrees[T.z]
		QT.insert_player(p_coords)
		if(MC_TICK_CHECK) return

	// --- Populate NPC Carbon Trees ---
	while(length(npc_carbon_feed))
		var/mob/living/mob_found = npc_carbon_feed[length(npc_carbon_feed)]
		npc_carbon_feed.len--
		if(!mob_found) continue
		var/turf/T = get_turf(mob_found)
		if(!T?.z || length(new_npc_carbon_quadtrees) < T.z) continue
		var/coords/qtnpc/n_coords = new /coords/qtnpc
		n_coords.npc = mob_found
		n_coords.x_pos = T.x
		n_coords.y_pos = T.y
		n_coords.z_pos = T.z
		var/datum/quadtree/QT = new_npc_carbon_quadtrees[T.z]
		QT.insert_npc(n_coords)
		if(MC_TICK_CHECK) return

	// --- Populate NPC Simple Trees ---
	while(length(npc_simple_feed))
		var/mob/living/mob_found = npc_simple_feed[length(npc_simple_feed)]
		npc_simple_feed.len--
		if(!mob_found) continue
		var/turf/T = get_turf(mob_found)
		if(!T?.z || length(new_npc_simple_quadtrees) < T.z) continue
		var/coords/qtnpc/n_coords = new /coords/qtnpc
		n_coords.npc = mob_found
		n_coords.x_pos = T.x
		n_coords.y_pos = T.y
		n_coords.z_pos = T.z
		var/datum/quadtree/QT = new_npc_simple_quadtrees[T.z]
		QT.insert_npc(n_coords)
		if(MC_TICK_CHECK) return

	// --- Populate Hearable Trees ---
	while(length(hearable_feed))
		var/atom/movable/hearable_found = hearable_feed[length(hearable_feed)]
		hearable_feed.len--
		if(QDELETED(hearable_found)) continue
		var/turf/T = get_turf(hearable_found)
		if(!T?.z || length(new_hearable_quadtrees) < T.z) continue
		var/coords/qthearable/h_coords = new /coords/qthearable
		h_coords.hearable = hearable_found
		h_coords.x_pos = T.x
		h_coords.y_pos = T.y
		h_coords.z_pos = T.z
		var/datum/quadtree/QT = new_hearable_quadtrees[T.z]
		QT.insert_hearable(h_coords)
		if(MC_TICK_CHECK) return
		
/datum/controller/subsystem/processing/quadtree/proc/OnMobMoved(mob/living/moved_mob)
	SIGNAL_HANDLER
	var/turf/T = get_turf(moved_mob)
	if(!T) return

	if(!moved_mob.qt_range)
		return

	// Updates the mob's tracked coordinates within the quadtree structure
	moved_mob.qt_range.UpdateQTMover(moved_mob.x, moved_mob.y)

	if(isobserver(moved_mob)) return

	var/list/nearby_entities = npcs_in_range(moved_mob.qt_range, T.z)
	
	if(!moved_mob.ai_root)
		for(var/mob/living/M as anything in nearby_entities)
			if(M.ai_root && !los_blocked(moved_mob, M))
				SSai.WakeUp(M)
	else
		nearby_entities -= moved_mob
		for(var/mob/living/M as anything in nearby_entities)
			if(M.ai_root && !moved_mob.faction_check_mob(M) && !los_blocked(moved_mob, M))
				SSai.WakeUp(M)

/datum/controller/subsystem/processing/quadtree/proc/RegisterMob(mob/living/M)
	RegisterSignal(M, COMSIG_MOB_MOVED, PROC_REF(OnMobMoved))
	if(M.client)
		player_feed += M

	else if(iscarbon(M))
		npc_carbon_feed += M

	else if(issimple(M))
		npc_simple_feed += M

/datum/controller/subsystem/processing/quadtree/proc/UnregisterMob(mob/living/M)
	UnregisterSignal(M, COMSIG_MOB_MOVED)
	unregister_queue += M

/datum/controller/subsystem/processing/quadtree/proc/players_in_range(datum/shape/range, z_level, flags = 0)
	var/list/players = list()
	if(!cur_quadtrees) return players
	if(z_level && length(cur_quadtrees) >= z_level)
		var/datum/quadtree/Q = cur_quadtrees[z_level]
		if(!Q) return players
		Q.query_range(range, players, flags)
	return players

// Combined search for all NPCs (Carbon and Simple)

/datum/controller/subsystem/processing/quadtree/proc/npcs_in_range(datum/shape/range, z_level)
	return npc_carbons_in_range(range, z_level) + npc_simples_in_range(range, z_level)

// Search for NPC Carbons
/datum/controller/subsystem/processing/quadtree/proc/npc_carbons_in_range(datum/shape/range, z_level)
	var/list/npcs = list()
	if(!cur_npc_carbon_quadtrees) return npcs
	if(z_level && length(cur_npc_carbon_quadtrees) >= z_level)
		var/datum/quadtree/Q = cur_npc_carbon_quadtrees[z_level]
		if(!Q) return npcs
		Q.query_range_npcs(range, npcs)
	return npcs

// Search for NPC Simples
/datum/controller/subsystem/processing/quadtree/proc/npc_simples_in_range(datum/shape/range, z_level)
	var/list/npcs = list()
	if(!cur_npc_simple_quadtrees) return npcs
	if(z_level && length(cur_npc_simple_quadtrees) >= z_level)
		var/datum/quadtree/Q = cur_npc_simple_quadtrees[z_level]
		if(!Q) return npcs
		Q.query_range_npcs(range, npcs)
	return npcs

// Search for Hearables
/datum/controller/subsystem/processing/quadtree/proc/hearables_in_range(datum/shape/range, z_level)
	var/list/hearables = list()
	if(!cur_hearable_quadtrees) return hearables
	if(z_level && length(cur_hearable_quadtrees) >= z_level)
		var/datum/quadtree/Q = cur_hearable_quadtrees[z_level]
		if(!Q) return hearables
		Q.query_range_hearables(range, hearables)
	return hearables
