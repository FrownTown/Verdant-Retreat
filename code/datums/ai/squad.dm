// ==============================================================================
// AI SQUAD DATUM
// ==============================================================================

/ai_squad
	var/list/members = list()
	var/mob/living/leader
	var/atom/center_of_mass
	var/max_size = 10
	var/squad_type // Typepath of the mobs in this squad, usually set to the leader's type
	var/list/blackboard = new

/ai_squad/New(mob/living/new_leader)
	if(new_leader)
		leader = new_leader
		squad_type = new_leader.type
		AddMember(new_leader)

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
		M.ai_root.blackboard.Remove(AIBLK_SQUAD_DATUM)
	
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

	for(var/mob/living/M as anything in members)
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
	// Override this for specific squad logic (e.g. formations, coordinated attacks)
	return

/ai_squad/Destroy()
	for(var/mob/living/M as anything in members)
		RemoveMember(M)
	return ..()
