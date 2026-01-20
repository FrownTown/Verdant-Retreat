// ==============================================================================
// PATHFINDING HELPERS
// ==============================================================================

// Global public API proc. This is the one you call elsewhere.
/proc/A_Star(mob/living/mover, turf/start, turf/end) as /list
	return SSpathfinding.FindPath(mover, start, end)

// --- Algorithm Helper Procs ---

/proc/heuristic(turf/start, turf/end) as num // Simple "3D" manhattan distance
	var/dx = abs(start.x - end.x)
	var/dy = abs(start.y - end.y)
	var/dz = abs(start.z - end.z)

	return (dx + dy) * STRAIGHT_COST + (dz * Z_LEVEL_CHANGE_COST)

/proc/reconstruct_path(alist/parent, turf/current) as /list
	var/list/total_path = list(current)
	while(parent[current])
		current = parent[current]
		total_path.Insert(1, current)
	return total_path

/proc/get_neighbors_3d(mob/living/mover, turf/T) as /list
	var/list/neighbors = list()

	for(var/turf/neighbor as anything in orange(1, T))
		// First, check if the NPC can just walk there normally.
		if(T.CanPass(mover, neighbor))
			neighbors += neighbor
		// If the path is blocked by density, check if it's an obstacle we can smash.
		else if(neighbor.density && mover.ai_root?.ai_flags & AI_FLAG_SMASH_OBSTACLES)
			var/is_special_obstacle = FALSE
			// Check for complex obstacles that have their own special interactions.
			for(var/atom/movable/AM in neighbor)
				if(istype(AM, /obj/structure/mineral_door) || istype(AM, /obj/structure/table) || istype(AM, /obj/structure/fluff/railing) || istype(AM, /obj/structure/chair))
					is_special_obstacle = TRUE
					break

			// If it's not a special interactive object, check if it's a generic smashable object like a window or grille.
			if(!is_special_obstacle)
				var/is_smashable_object = FALSE
				for(var/obj/structure/S in neighbor)
					if(istype(S, /obj/structure/roguewindow))
						is_smashable_object = TRUE
						break

				if(is_smashable_object)
					neighbors += neighbor

	var/haszmover = FALSE
	for(var/atom/A in T.contents)
		if(istype(A, /obj/structure/ladder) || istype(A, /obj/structure/stairs))
			haszmover = TRUE
			break

	if(haszmover)
		var/turf/above = GetAbove(T)
		if(above && mover.can_zTravel(above, UP))
			neighbors += above
		var/turf/below = GetBelow(T)
		if(below && mover.can_zTravel(below, DOWN))
			neighbors += below

	return neighbors

/proc/get_move_cost(mob/living/mover, turf/from_turf, turf/to_turf) as num
	var/cost = STRAIGHT_COST
	var/obstacle_cost = 0

	// Get the NPC's strength stat to calculate a discount for smashing.
	var/strength_bonus = 0
	if(mover.STASTR) // Safety check - STASTR might not exist on all mob types
		strength_bonus = mover.STASTR * 2

	for(var/atom/movable/AM in to_turf)
		if(AM.density)
			if(istype(AM, /obj/structure/mineral_door))
				var/obj/structure/mineral_door/D = AM
				if(D.locked)
					// Check if mob is provoked - either has a target or is a hostile mob with a target
					var/is_provoked = (mover.ai_root?.target || (istype(mover, /mob/living/simple_animal/hostile) && mover:target))
					if(is_provoked)
						var/obj/item/weapon = mover.get_active_held_item()
						// Check if we can bash the door based on weapon force and door health
						var/door_health = D.obj_integrity ? D.obj_integrity : D.max_integrity
						if(weapon && weapon.force && door_health)
							// Cost based on how hard it is to break - more health = higher cost
							var/break_difficulty = door_health / max(1, (weapon.force + strength_bonus))
							obstacle_cost = max(50, 100 * break_difficulty)
							break
						else if(strength_bonus > 20)
							// Very strong mobs can try to bash without a weapon
							obstacle_cost = max(100, 200 - strength_bonus)
							break
						else
							return 10000 // We are incapable of breaking this door
					else
						return 10000 // An unprovoked NPC sees a locked door as a wall.
				else
					obstacle_cost = 10 // Low cost to open an unlocked door.

				break

			if(istype(AM, /obj/structure/fluff/railing) || istype(AM, /obj/structure/ladder) || istype(AM, /obj/structure/table))
				obstacle_cost = 15 // Cost to climb something.
				break

			if(istype(AM, /obj/structure/roguewindow))
				// Cost to break a window based on strength
				obstacle_cost = max(5, 50 - strength_bonus)
				break

	// Calculate final cost based on Z-level change or standard movement
	if(from_turf.z != to_turf.z)
		cost = Z_LEVEL_CHANGE_COST + obstacle_cost
	else
		cost += obstacle_cost

	return cost

/proc/CanReach(mob/living/mover, turf/start, turf/end, depth = INFINITY) // A simple helper function to check if a path exists between two turfs. By default, has no depth limit. If you want to limit it, pass in a number.

	if (!mover || !start || !end)
		return FALSE


	var/list/path = A_Star(mover, start, end)


	if(path && length(path))
		return TRUE

	return FALSE

// ==============================================================================
// AStar LEGACY IMPLEMENTATION (FOR REFERENCE ONLY; DO NOT USE)
// ==============================================================================
/*

/proc/PathWeightCompare(datum/PathNode/a, datum/PathNode/b)
	return a.estimated_cost - b.estimated_cost


// adjacent and dist are proc paths
/proc/AStar(var/start, var/end, adjacent, dist, var/max_nodes, var/max_node_depth = 30, var/min_target_dist = 0, var/min_node_dist, var/id, var/datum/exclude)
	var/PriorityQueue/open = new /PriorityQueue(/proc/PathWeightCompare)
	var/list/closed = list()
	var/list/path
	var/list/path_node_by_position = list()
	start = get_turf(start)
	if(!start)
		return 0

	open.Enqueue(new /datum/PathNode(start, null, 0, call(start, dist)(end), 0))

	while(!open.IsEmpty() && !path)
		var/datum/PathNode/current = open.Dequeue()
		closed.Add(current.source)

		if(current.source == end || call(current.source, dist)(end) <= min_target_dist)
			path = new /list(current.nodes_traversed + 1)
			path[path.len] = current.source
			var/index = path.len - 1

			while(current.previous_node)
				current = current.previous_node
				path[index--] = current.source
			break

		if(min_node_dist && max_node_depth)
			if(call(current.source, min_node_dist)(end) + current.nodes_traversed >= max_node_depth)
				continue

		if(max_node_depth)
			if(current.nodes_traversed >= max_node_depth)
				continue

		for(var/datum/datum in call(current.source, adjacent)(id))
			if(datum == exclude)
				continue

			var/best_estimated_cost = current.estimated_cost + call(current.source, dist)(datum)

			//handle removal of sub-par positions
			if(datum in path_node_by_position)
				var/datum/PathNode/target = path_node_by_position[datum]
				if(target.best_estimated_cost)
					if(best_estimated_cost + call(datum, dist)(end) < target.best_estimated_cost)
						open.Remove(target)
					else
						continue

			var/datum/PathNode/next_node = new (datum, current, best_estimated_cost, call(datum, dist)(end), current.nodes_traversed + 1)
			path_node_by_position[datum] = next_node
			open.Enqueue(next_node)

			if(max_nodes && open.Length() > max_nodes)
				open.Remove(open.Length())

	return path

	*/
	
// ==============================================================================
// LINE OF SIGHT CHECKING VIA BRESENHAM'S LINE ALGORITHM
// ==============================================================================

/proc/__blocked(x, y, z, checkforcover = FALSE)
	var/turf/T = locate(x, y, z)
	if(!T) return TRUE

	if(T.density && T.opacity) return TRUE

	for(var/atom/A in T.contents)
		if(A.density && A.opacity)
			return TRUE
	return FALSE

/proc/los_blocked(atom/M, atom/N, checkforcover = FALSE)
	if(!M || !N || M.z != N.z)
		return TRUE

	var/px = M.x, py = M.y
	var/dx = N.x - px,  dy = N.y - py
	var/dxabs = abs(dx), dyabs = abs(dy)
	var/sdx = SIGN(dx), sdy = SIGN(dy)
	var/xerr = dxabs >> 1, yerr = dyabs >> 1

	// skip the starting turf (M's own tile) then begin stepping
	if(dxabs >= dyabs)
		for(var/i = dxabs; i > 0; --i)
			yerr += dyabs
			if(yerr >= dxabs)  { yerr -= dxabs; py += sdy }
			px += sdx
			if(__blocked(px, py, M.z, checkforcover)) return TRUE
	else
		for(var/i = dyabs; i > 0; --i)
			xerr += dxabs
			if(xerr >= dyabs) { xerr -= dyabs; px += sdx }
			py += sdy
			if(__blocked(px, py, M.z, checkforcover)) return TRUE

	return FALSE
