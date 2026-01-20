// ==============================================================================
// AI SUBSYSTEM
// ==============================================================================

#define AI_SQUADS // Enable AI squad functionality. Comment out to disable.

PROCESSING_SUBSYSTEM_DEF(ai)
	name = "AI"
	priority = SS_PRIORITY_AI
	flags = SS_KEEP_TIMING
	runlevels = RUNLEVEL_GAME
	wait = 1 // Process every tick to check for thonk delays. This is insanely fast anyway compared to the other subsystems.

	// Using associative lists for performance. Checking for a key is much faster than searching a list. We learned this from liquids, lads.
	var/list/active_mobs
	var/list/sleeping_mobs
	var/list/unregister_queue
	var/list/sleep_queue
	#ifdef AI_SQUADS
	var/list/squads
	var/list/squads_to_remove
	var/next_squad_update_tick = 0
	#endif

/datum/controller/subsystem/processing/ai/Initialize()
	..()
	NEW_SS_GLOBAL(SSai)

	active_mobs = list()
	sleeping_mobs = list()
	unregister_queue = list()
	sleep_queue = list()
	squads = list()
	squads_to_remove = list()
	// Register movement tracking for player mobs - this will be set up as players log in/spawn

/datum/controller/subsystem/processing/ai/proc/Register(mob/living/M)
	if(M && M.ai_root && !sleeping_mobs[M]) // Only register if it's not already sleeping.
		active_mobs[M] = TRUE
		M.ai_root.next_think_tick = world.time + M.ai_root.next_think_delay
		GLOB.npc_list |= M

/datum/controller/subsystem/processing/ai/proc/Unregister(mob/living/M)
	if(M)
		#ifdef AI_SQUADS
		if(M.ai_root.blackboard[AIBLK_SQUAD_DATUM])
			var/ai_squad/squad = M.ai_root.blackboard[AIBLK_SQUAD_DATUM]
			squad.RemoveMember(M)
		#endif
		active_mobs.Remove(M)
		sleeping_mobs.Remove(M)
		GLOB.npc_list -= M
		QDEL_NULL(M.ai_root)

/datum/controller/subsystem/processing/ai/proc/WakeUp(mob/living/M)
	if(sleeping_mobs[M])
		sleeping_mobs.Remove(M)
		active_mobs[M] = TRUE
		M.ai_root.blackboard.Remove(AIBLK_HIBERNATION_TIMER)
		M.ai_root.next_think_tick = world.time // Let it think immediately
		M.ai_root.next_sleep_tick = world.time + M.ai_root.next_sleep_delay

/datum/controller/subsystem/processing/ai/proc/GoToSleep(mob/living/M)
	if(active_mobs[M])
		if(M.ai_root.next_sleep_tick < world.time)
			active_mobs.Remove(M)
			sleeping_mobs[M] = TRUE

/datum/controller/subsystem/processing/ai/proc/on_max_z_changed()
	// Resize lists if necessary when max Z changes
	// For now, this is just a placeholder to satisfy the call from World.dm
	return

// Processing our active mobs
/datum/controller/subsystem/processing/ai/fire(var/time_delta)
	var/current_time = world.time

	for(var/mob/living/M as anything in active_mobs)
		if(!M || M.stat == DEAD || M.client)
			unregister_queue |= M
			continue

		var/turf/T = get_turf(M)
		if(!T) // How the fuck could this even happen? Let's not process it, just in case. Jesus Christ.
			unregister_queue |= M
			continue

		M.RunMovement()

		// Check if enough time has passed for the mob to think again.
		if(current_time >= M.ai_root.next_think_tick)
			if(!(M.ai_root.ai_flags & (AI_FLAG_PERSISTENT|AI_FLAG_ASSUMEDIRECTCONTROL)))

				var/list/nearby_players = SSquadtree.players_in_range(M.qt_range, T.z, QTREE_SCAN_MOBS|QTREE_EXCLUDE_OBSERVER)


				if(!length(nearby_players))

					if(!M.ai_root.blackboard[AIBLK_HIBERNATION_TIMER])
						M.ai_root.blackboard[AIBLK_HIBERNATION_TIMER] = current_time + AI_HIBERNATION_DELAY

					if(current_time >= M.ai_root.blackboard[AIBLK_HIBERNATION_TIMER])
						sleep_queue |= M
						continue
				else
					M.ai_root.blackboard.Remove(AIBLK_HIBERNATION_TIMER)

			M.RunAI()
			M.ai_root.next_think_tick = current_time + M.ai_root.next_think_delay

	for(var/mob/living/M as anything in unregister_queue)
		#ifdef AI_SQUADS
		var/ai_squad/squad = M.ai_root.blackboard[AIBLK_SQUAD_DATUM]
		if(squad)
			squad.RemoveMember(M)
		#endif
		Unregister(M)

	for(var/mob/living/M as anything in sleep_queue)
		GoToSleep(M)

	unregister_queue.len = 0
	sleep_queue.len = 0
	#ifdef AI_SQUADS
	if(current_time > next_squad_update_tick)
		for(var/ai_squad/S as anything in squads)
			if(length(S.members))
				S.RunAI()
			else
				squads_to_remove |= S

				if(S)
					S.update_center_of_mass()

					// Check if squad should split
					if(length(S.members) > S.max_size)
						SplitSquad(S)
						continue // Skip to next squad as this one is now gone.

					// Check if squad should merge with another
					for(var/ai_squad/other_squad as anything in squads)
						// Removed IS12-specific /ai_squad/sweepers type check
						if(S == other_squad) continue
						if(S.squad_type != other_squad.squad_type) continue

						if(get_dist(S.center_of_mass, other_squad.center_of_mass) < AI_SQUAD_MERGE_DIST)
							if(length(S.members) + length(other_squad.members) <= S.max_size)
								// Merge the smaller squad into the larger one.
								if(length(S.members) > length(other_squad.members))
									MergeSquads(S, other_squad)
								else
									MergeSquads(other_squad, S)
								break // Stop checking this squad as it has changed.

			next_squad_update_tick = current_time + 2 SECONDS

	for(var/ai_squad/squad as anything in squads_to_remove)
		squads -= squad
		qdel(squad)

/datum/controller/subsystem/processing/ai/proc/MakeSquad(var/mob/living/leader, special_squad_type)
	var/ai_squad/squad = special_squad_type ? new special_squad_type(leader) : new /ai_squad(leader)
	squads += squad
	AddToSquad(leader, squad)
	return squad

/datum/controller/subsystem/processing/ai/proc/AddToSquad(var/mob/living/M, var/ai_squad/squad)
	if(!istype(M) || !istype(squad)) return

	// If the mob was already in a squad, remove it first.
	var/ai_squad/old_squad = M.ai_root.blackboard[AIBLK_SQUAD_DATUM]
	if(old_squad)
		old_squad.RemoveMember(M)

	squad.AddMember(M)

/datum/controller/subsystem/processing/ai/proc/FindOrCreateSquadFor(mob/living/M)
	var/ai_squad/best_squad = find_best_squad_for(M)

	if(best_squad)
		best_squad.AddMember(M)
	else
		var/squad_type = M.get_preferred_squad_type()
		var/ai_squad/new_squad = new squad_type(M)
		squads += new_squad
		new_squad.AddMember(M)

// Helper proc to find the most suitable squad for an NPC to join.
/datum/controller/subsystem/processing/ai/proc/find_best_squad_for(mob/living/M)
	var/ai_squad/best_squad = null
	var/closest_dist = AI_SQUAD_MAX_JOIN_DIST // A global define for max join range

	for(var/ai_squad/S as anything in squads)
		if(S.squad_type != M.type) continue // Must be the same type of NPC.
		if(length(S.members) >= S.max_size) continue // Must not be full.

		if(!S.center_of_mass) S.update_center_of_mass()
		var/atom/ref = S.center_of_mass ? S.center_of_mass : S.leader

		var/dist = get_dist(M, ref)
		if(dist < closest_dist)
			best_squad = S
			closest_dist = dist

	return best_squad

// Merges squad B into squad A.
/datum/controller/subsystem/processing/ai/proc/MergeSquads(ai_squad/A, ai_squad/B)
	for(var/mob/living/M as anything in B.members)
		A.AddMember(M)

	squads -= B
	qdel(B)

// Splits a large squad into two smaller ones.
/datum/controller/subsystem/processing/ai/proc/SplitSquad(ai_squad/S)
	if(S.members.len < 2) return // Can't split a squad of one.

	// Find the two members who are farthest apart to be the new leaders.
	var/mob/living/new_leader_A = S.members[1]
	var/mob/living/new_leader_B
	for(var/mob/living/member as anything in S.members)
		if(member == new_leader_A) continue
		if(!new_leader_B)
			new_leader_B = member
		if(get_dist(new_leader_A, member) > get_dist(new_leader_A, new_leader_B))
			new_leader_B = member

	var/ai_squad/new_squad_A = new /ai_squad(new_leader_A)
	var/ai_squad/new_squad_B = new /ai_squad(new_leader_B)
	squads.Add(new_squad_A, new_squad_B)

	// Re-assign all original members to the closest new leader, but prioritize keeping the squads evenly sized.
	for(var/mob/living/M as anything in S.members)
		if(length(new_squad_A.members) <= (length(new_squad_B.members)))
			if(get_dist(M, new_leader_A) <= get_dist(M, new_leader_B))
				new_squad_A.AddMember(M)
				continue

		new_squad_B.AddMember(M)

	squads -= S
	qdel(S)

// Snowflake Sweeper split logic for the subsystem lol
/datum/controller/subsystem/processing/ai/proc/SplitSquadForHunt(ai_squad/parent_squad, mob/living/hunt_target)
	if (length(parent_squad.members) < 4)
		return // Don't split if the squad is too small

	var/list/candidates_with_dist = list()

	for(var/mob/living/member as anything in parent_squad.members)
		candidates_with_dist += list(list("mob" = member, "dist" = get_dist(member, hunt_target)))

	sortTim(candidates_with_dist, /proc/cmp_dist_list_asc)

	var/list/sorted_candidates = list()
	for (var/list/item as anything in candidates_with_dist)
		sorted_candidates += item["mob"]

	var/list/hunt_team_members = list()
	var/num_hunters = min(3, length(sorted_candidates) - 1)
	for (var/i = 1; i <= num_hunters; i++)
		hunt_team_members += sorted_candidates[i]

	if (!length(hunt_team_members))
		return

	// Create the new hunt squad
	var/mob/living/hunt_leader = hunt_team_members[1]
	var/ai_squad/hunt_squad = new /ai_squad(hunt_leader)
	hunt_squad.squad_type = parent_squad.squad_type
	squads += hunt_squad

	// Move members from the parent squad to the new hunt squad
	for (var/mob/living/hunter as anything in hunt_team_members)
		parent_squad.RemoveMember(hunter)
		hunt_squad.AddMember(hunter)

	// Assign the target to the new squad
	hunt_squad.blackboard[AIBLK_SQUAD_HUNT_TARGET] = hunt_target
	for (var/mob/living/hunter as anything in hunt_squad.members)
		hunter.ai_root.target = hunt_target

	#endif AI_SQUADS

//================================================================
//SUBSYSTEM HELPERS
//================================================================

// Below are any functions or types that are useful for interacting with this subsystem, or with NPCs in general.

/mob/var/datum/shape/qt_range // Each mob has a single shape datum to define the quadtree's areas of interest for running searches. This is more performant than creating and destroying the shape datums on every tick.

#undef AI_SQUADS
