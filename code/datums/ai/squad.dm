// ==============================================================================
// AI SQUAD DATUM
// ==============================================================================

/ai_squad
	var/list/members = list()
	var/mob/living/leader
	var/atom/center_of_mass
	var/max_size = 12
	var/squad_type // Typepath of the mobs in this squad, usually set to the leader's type
	var/alist/blackboard
	var/squad_tactic/current_tactic // Current tactical behavior

/ai_squad/New(mob/living/new_leader)
	if(new_leader)
		blackboard = alist()
		leader = new_leader
		squad_type = new_leader.type
		AddMember(new_leader)

	// Register with AI subsystem
	SSai.squads += src

/ai_squad/proc/AddMember(mob/living/M)
	if(!M) return
	if(M in members) return
	
	members += M
	if(M.ai_root)
		M.ai_root.blackboard[AIBLK_SQUAD_DATUM] = src
	
	if(!leader)
		leader = M
		squad_type = M.type

/ai_squad/proc/RemoveMember(mob/living/M)
	if(!M) return
	members -= M
	if(M.ai_root && M.ai_root.blackboard[AIBLK_SQUAD_DATUM] == src)
		M.ai_root.blackboard -= AIBLK_SQUAD_DATUM
	
	if(M == leader)
		leader = null
		if(length(members))
			leader = members[1]

/ai_squad/proc/update_center_of_mass()
	if(!length(members))
		center_of_mass = null
		return

	var/avg_x = 0
	var/avg_y = 0
	var/z_level = 0
	var/valid_members = 0

	for(var/mob/living/M in members)
		if(M.z)
			if(!z_level) z_level = M.z
			if(M.z == z_level)
				avg_x += M.x
				avg_y += M.y
				valid_members++

	if(valid_members)
		var/turf/T = locate(avg_x / valid_members, avg_y / valid_members, z_level)
		if(T)
			center_of_mass = T

/ai_squad/proc/RunAI()
	// Share aggressors and targets across squad
	var/list/shared_aggressors = list()

	// Collect all aggressors from all members
	for(var/mob/living/M in members)
		if(!M.ai_root) continue
		var/list/member_aggressors = M.ai_root.blackboard[AIBLK_AGGRESSORS]
		if(member_aggressors)
			shared_aggressors |= member_aggressors

	// Distribute shared aggressors to all members
	for(var/mob/living/M in members)
		if(!M.ai_root) continue
		if(!M.ai_root.blackboard[AIBLK_AGGRESSORS])
			M.ai_root.blackboard[AIBLK_AGGRESSORS] = list()
		M.ai_root.blackboard[AIBLK_AGGRESSORS] |= shared_aggressors

	// Apply current tactic
	if(current_tactic)
		current_tactic.apply_tactics()

/ai_squad/proc/set_tactic(squad_tactic/new_tactic_type)
	if(current_tactic)
		current_tactic.remove_from_squad()
		qdel(current_tactic)

	if(new_tactic_type)
		current_tactic = new new_tactic_type()
		current_tactic.assign_to_squad(src)

// Goblin-specific squad for coordinated tactics
/ai_squad/goblin
	max_size = 6

/ai_squad/goblin/New(mob/living/new_leader)
	. = ..()
	// Goblins use focus fire tactics by default (but can be changed at runtime)
	if(!current_tactic)
		set_tactic(/squad_tactic/focus_fire)

// RunAI is overridden in goblin_squad.dm for better target detection

/ai_squad/goblin/proc/assign_tactical_roles(mob/living/target)
	if(!target) return

	var/is_bait = HAS_TRAIT(target, TRAIT_MONSTERBAIT)

	// Count existing roles
	var/restrainers = 0
	var/strippers = 0
	var/violators = 0

	for(var/mob/living/M in members)
		if(!M.ai_root) continue
		var/role = M.ai_root.blackboard[AIBLK_SQUAD_ROLE]
		switch(role)
			if(GOB_SQUAD_ROLE_RESTRAINER)
				restrainers++
			if(GOB_SQUAD_ROLE_STRIPPER)
				strippers++
			if(GOB_SQUAD_ROLE_VIOLATOR)
				violators++

	// Assign roles to unassigned members
	for(var/mob/living/M in members)
		if(!M.ai_root) continue
		if(M.ai_root.blackboard[AIBLK_SQUAD_ROLE]) continue // Already has a role

		// Assign based on needs
		if(restrainers < 1)
			M.ai_root.blackboard[AIBLK_SQUAD_ROLE] = GOB_SQUAD_ROLE_RESTRAINER
			restrainers++
		else if(strippers < 2)
			M.ai_root.blackboard[AIBLK_SQUAD_ROLE] = GOB_SQUAD_ROLE_STRIPPER
			strippers++
		else if(is_bait && violators < 3)
			M.ai_root.blackboard[AIBLK_SQUAD_ROLE] = GOB_SQUAD_ROLE_VIOLATOR
			violators++
		else
			M.ai_root.blackboard[AIBLK_SQUAD_ROLE] = GOB_SQUAD_ROLE_ATTACKER

/ai_squad/Destroy()
	for(var/mob/living/M in members)
		RemoveMember(M)
	return ..()
