// ==============================================================================
// QUADTREE SUBSYSTEM
// ==============================================================================

/datum/controller/subsystem/quadtree/Initialize()
	NEW_SS_GLOBAL(SSquadtree)

	cur_quadtrees = new/list(world.maxz)
	new_quadtrees = new/list(world.maxz)
	cur_npc_carbon_quadtrees = new/list(world.maxz)
	new_npc_carbon_quadtrees = new/list(world.maxz)
	cur_npc_simple_quadtrees = new/list(world.maxz)
	new_npc_simple_quadtrees = new/list(world.maxz)
	npc_carbon_feed = list()
	npc_simple_feed = list()

	var/datum/shape/rectangle/R
	for(var/i in 1 to world.maxz)
		R = RECT(world.maxx/2, world.maxy/2, world.maxx, world.maxy)
		new_quadtrees[i] = QTREE(R, i)
		new_npc_carbon_quadtrees[i] = QTREE(R, i)
		new_npc_simple_quadtrees[i] = QTREE(R, i)

/datum/controller/subsystem/quadtree/fire(resumed = FALSE)
	if(!resumed)
		// --- Reset Player Trees ---
		player_feed = GLOB.player_list.Copy()
		cur_quadtrees = new_quadtrees
		new_quadtrees = new/list(world.maxz)
		for(var/i in 1 to world.maxz)
			new_quadtrees[i] = QTREE(RECT(world.maxx/2,world.maxy/2, world.maxx, world.maxy), i)

		// --- Reset NPC Carbon Trees ---
		npc_carbon_feed = GLOB.npc_list.Copy()
		cur_npc_carbon_quadtrees = new_npc_carbon_quadtrees
		new_npc_carbon_quadtrees = new/list(world.maxz)
		for(var/i in 1 to world.maxz)
			new_npc_carbon_quadtrees[i] = QTREE(RECT(world.maxx/2,world.maxy/2, world.maxx, world.maxy), i)

		// --- Reset NPC Simple Trees ---
		// Get all simple animals with ai_root from SSai
		npc_simple_feed = list()
		if(SSai && SSai.active_mobs)
			for(var/mob/living/simple_animal/M as anything in SSai.active_mobs)
				if(M.ai_root)
					npc_simple_feed += M
		if(SSai && SSai.sleeping_mobs)
			for(var/mob/living/simple_animal/M as anything in SSai.sleeping_mobs)
				if(M.ai_root)
					npc_simple_feed += M

		cur_npc_simple_quadtrees = new_npc_simple_quadtrees
		new_npc_simple_quadtrees = new/list(world.maxz)
		for(var/i in 1 to world.maxz)
			new_npc_simple_quadtrees[i] = QTREE(RECT(world.maxx/2,world.maxy/2, world.maxx, world.maxy), i)


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

/datum/controller/subsystem/quadtree/proc/players_in_range(datum/shape/range, z_level, flags = 0)
	var/list/players = list()
	if(!cur_quadtrees) return players
	if(z_level && length(cur_quadtrees) >= z_level)
		var/datum/quadtree/Q = cur_quadtrees[z_level]
		if(!Q) return players
		Q.query_range(range, players, flags)
	return players

// Search for NPC Carbons (Old AI)
/datum/controller/subsystem/quadtree/proc/npc_carbons_in_range(datum/shape/range, z_level)
	var/list/npcs = list()
	if(!cur_npc_carbon_quadtrees) return npcs
	if(z_level && length(cur_npc_carbon_quadtrees) >= z_level)
		var/datum/quadtree/Q = cur_npc_carbon_quadtrees[z_level]
		if(!Q) return npcs
		Q.query_range_npcs(range, npcs)
	return npcs

// Search for NPC Simples (New AI)
/datum/controller/subsystem/quadtree/proc/npc_simples_in_range(datum/shape/range, z_level)
	var/list/npcs = list()
	if(!cur_npc_simple_quadtrees) return npcs
	if(z_level && length(cur_npc_simple_quadtrees) >= z_level)
		var/datum/quadtree/Q = cur_npc_simple_quadtrees[z_level]
		if(!Q) return npcs
		Q.query_range_npcs(range, npcs)
	return npcs

SUBSYSTEM_DEF(quadtree)
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
