// ==============================================================================
// QUADTREE DATUMS
// ==============================================================================

/coords/qtplayer
	/// Relevant mob the coords are associated to
	var/mob/player
	/// Truthy if player is an observer
	var/is_observer = FALSE

// Related scheme to above
/coords/qtplayer/Destroy()
	player = null
	..()
	return QDEL_HINT_IWILLGC

/coords/qtnpc
	/// Relevant mob the coords are associated to. Should always be a /mob/living or subtype of it to avoid scope errors, since this is specifically for NPCs.
	var/mob/living/npc

/coords/qtnpc/Destroy()
	npc = null
	..()
	return QDEL_HINT_IWILLGC

/coords/qthearable
	/// Relevant atom the coords are associated to.
	var/atom/movable/hearable

/coords/qthearable/Destroy()
	hearable = null
	..()
	return QDEL_HINT_IWILLGC

/datum/shape //Leaving rectangles as a subtype if anyone decides to add circles later - Did it lol - Plasmatik
	var/center_x = 0
	var/center_y = 0
	// Moving the width and height variables to the base class so they can be used by all shapes - Plasmatik
	var/width = 0
	var/height = 0

	var/initial_width = 0
	var/initial_height = 0

/datum/shape/proc/intersects(datum/shape/range)
	return

/datum/shape/proc/contains(coords/coords)
	return

/datum/shape/proc/UpdateQTMover(...)
	return

/datum/shape/rectangle


/datum/shape/rectangle/New(x, y, w, h)
	..()
	center_x = x
	center_y = y
	width = w
	initial_width = w
	height = h
	initial_height = h

/datum/shape/rectangle/UpdateQTMover(x, y)
	center_x = x
	center_y = y

/datum/shape/rectangle/intersects(datum/shape/range)
	switch(range.type) // We can use switches in these cases because we know the exact types being passed, and we get a very minor performance boost compared to if/else as the type is only evaluated once.
		if(/datum/shape/rectangle)
			var/datum/shape/rectangle/rect = range
			return !(rect.center_x + rect.width/2 < center_x - width / 2 || \
					rect.center_x  - rect.width/2 > center_x + width / 2 || \
					rect.center_y + rect.height/2 < center_y - height / 2 || \
					rect.center_y - rect.height/2 > center_y + height / 2)
		if(/datum/shape/circle) // If we're checking to see if a circle intersects a rectangle, we'll use the circle's intersect proc instead.
			return range.intersects(src)
		else
			return ..() // Fallback in case something goes wrong, this should never happen.

/datum/shape/circle/intersects(datum/shape/circle/range)


/datum/shape/rectangle/contains(coords/coords)
	return (coords.x_pos >= center_x - width / 2  \
			&& coords.x_pos <= center_x + width / 2 \
			&& coords.y_pos >= center_y - height /2  \
			&& coords.y_pos <= center_y + height / 2)

/datum/shape/circle
	var/radius = 0

/datum/shape/circle/New(x, y, r)
	..()
	center_x = x
	center_y = y
	radius = r
	width = r*2
	height = r*2

/datum/shape/circle/contains(coords/coords)
	return get_dist_euclidean_squared(center_x, center_y, coords.x_pos, coords.y_pos) <= radius**2

/datum/shape/circle/intersects(datum/shape/range)
	switch(range.type)
		if(/datum/shape/rectangle)
			var/datum/shape/rectangle/rect = range
			// To check if a circle intersects a rectangle, first we have to find the closest point on the rectangle to the circle's center
			var/closest_x = Clamp(center_x, rect.center_x - rect.width / 2, rect.center_x + rect.width / 2)
			var/closest_y = Clamp(center_y, rect.center_y - rect.height / 2, rect.center_y + rect.height / 2)

			// Then we calculate the distance between the circle's center and said closest point using Euclidean distance
			var/dist_sq = get_dist_euclidean_squared(closest_x, closest_y, center_x, center_y)

			// If the result is less than or equal to the circle's radius squared, they intersect
			return dist_sq <= radius**2

		if(/datum/shape/circle)
			// It's much easier to check if two circles intersect one another. Here, we don't have to worry about doing extra math to find the closest points, as we can compare the sum of their radii to the distance between them instead.
			var/datum/shape/circle/other = range
			var/dist_sq = get_dist_euclidean_squared(center_x, center_y, other.center_x, other.center_y)
			var/radii_sum_sq = (radius + other.radius)**2
			return dist_sq <= radii_sum_sq
		else
			return ..() // Fallback in case something goes wrong, again this shouldn't happen.

/datum/quadtree
	var/datum/quadtree/nw_branch
	var/datum/quadtree/ne_branch
	var/datum/quadtree/sw_branch
	var/datum/quadtree/se_branch
	var/datum/shape/rectangle/boundary
	var/list/coords/qtplayer/player_coords
	var/list/coords/qtnpc/npc_coords
	var/list/coords/qthearable/hearable_coords
	var/z_level
	var/is_divided
	var/final_divide = FALSE

/datum/quadtree/New(datum/shape/rectangle/rect, z)
	..()
	boundary = rect
	z_level = z
	if(boundary.width <= QUADTREE_BOUNDARY_MINIMUM_WIDTH || boundary.height <= QUADTREE_BOUNDARY_MINIMUM_HEIGHT)
		final_divide = TRUE

/datum/quadtree/Destroy()
	// Basically just DON'T use qdel, safety net provided if you do anyway
	QDEL_NULL(nw_branch)
	QDEL_NULL(ne_branch)
	QDEL_NULL(sw_branch)
	QDEL_NULL(se_branch)
	QDEL_NULL(boundary)
	QDEL_NULL(player_coords)
	QDEL_NULL(npc_coords) // Added for cleanup
	QDEL_NULL(hearable_coords)
	..()
	return QDEL_HINT_IWILLGC // Shouldn't have to begin with

/datum/quadtree/proc/subdivide() // Clarified and refactored this to make it less eye cancer - Plasmatik
	var/half_width = boundary.width / 2
	var/half_height = boundary.height / 2
	var/quarter_width = boundary.width / 4
	var/quarter_height = boundary.height / 4

	// We're gonna create four quadrants, each one being half the size of its parent
	// And our centers will be offset by 1/4 of parent's dimensions from parent's center, so we get 4 equally sized quadrants
	nw_branch = QTREE(RECT(boundary.center_x - quarter_width, boundary.center_y + quarter_height, half_width, half_height), z_level)
	ne_branch = QTREE(RECT(boundary.center_x + quarter_width, boundary.center_y + quarter_height, half_width, half_height), z_level)
	sw_branch = QTREE(RECT(boundary.center_x - quarter_width, boundary.center_y - quarter_height, half_width, half_height), z_level)
	se_branch = QTREE(RECT(boundary.center_x + quarter_width, boundary.center_y - quarter_height, half_width, half_height), z_level)
	is_divided = TRUE

/datum/quadtree/proc/insert_player(coords/qtplayer/p_coords)
	if(!boundary.contains(p_coords))
		return FALSE

	// Initialize list if needed
	if(!player_coords)
		player_coords = list()

	// If we have capacity or can't subdivide further, add here
	if(final_divide || length(player_coords) < QUADTREE_CAPACITY)
		player_coords.Add(p_coords)
		return TRUE

	// We're at capacity and can subdivide
	if(!is_divided)
		subdivide()

	// Try to insert into appropriate quadrant
	if(nw_branch.insert_player(p_coords)) return TRUE
	if(ne_branch.insert_player(p_coords)) return TRUE
	if(sw_branch.insert_player(p_coords)) return TRUE
	if(se_branch.insert_player(p_coords)) return TRUE

	// If subdivision failed (shouldn't happen with proper contains() logic)
	// Fall back to adding to current node as overflow
	player_coords.Add(p_coords)
	return TRUE

/datum/quadtree/proc/insert_npc(coords/qtnpc/n_coords)
	if(!boundary.contains(n_coords))
		return FALSE

	if(!npc_coords)
		npc_coords = list()

	if(final_divide || length(npc_coords) < QUADTREE_CAPACITY)
		npc_coords.Add(n_coords)
		return TRUE

	if(!is_divided)
		subdivide()

	if(nw_branch.insert_npc(n_coords)) return TRUE
	if(ne_branch.insert_npc(n_coords)) return TRUE
	if(sw_branch.insert_npc(n_coords)) return TRUE
	if(se_branch.insert_npc(n_coords)) return TRUE

	npc_coords.Add(n_coords)
	return TRUE

/datum/quadtree/proc/insert_hearable(coords/qthearable/h_coords)
	if(!boundary.contains(h_coords))
		return FALSE

	if(!hearable_coords)
		hearable_coords = list()

	if(final_divide || length(hearable_coords) < QUADTREE_CAPACITY)
		hearable_coords.Add(h_coords)
		return TRUE

	if(!is_divided)
		subdivide()

	if(nw_branch.insert_hearable(h_coords)) return TRUE
	if(ne_branch.insert_hearable(h_coords)) return TRUE
	if(sw_branch.insert_hearable(h_coords)) return TRUE
	if(se_branch.insert_hearable(h_coords)) return TRUE

	hearable_coords.Add(h_coords)
	return TRUE

/datum/quadtree/proc/query_range(datum/shape/range, list/found_players, flags = 0)
	if(!found_players)
		found_players = list()
	. = found_players
	if(!range?.intersects(boundary))
		return
	if(is_divided)
		nw_branch.query_range(range, found_players, flags)
		ne_branch.query_range(range, found_players, flags)
		sw_branch.query_range(range, found_players, flags)
		se_branch.query_range(range, found_players, flags)
	if(!player_coords)
		return
	for(var/coords/qtplayer/P as anything in player_coords)
		if(!P.player) continue
		if((flags & QTREE_EXCLUDE_OBSERVER) && P.is_observer) continue
		if(range.contains(P))
			if(flags & QTREE_SCAN_MOBS)
				found_players.Add(P.player)
			else if(P.player.client)
				found_players.Add(P.player.client)

/datum/quadtree/proc/query_range_npcs(datum/shape/range, list/found_npcs)
	if(!found_npcs)
		found_npcs = list()
	. = found_npcs
	if(!range?.intersects(boundary))
		return
	if(is_divided)
		nw_branch.query_range_npcs(range, found_npcs)
		ne_branch.query_range_npcs(range, found_npcs)
		sw_branch.query_range_npcs(range, found_npcs)
		se_branch.query_range_npcs(range, found_npcs)
	if(!npc_coords)
		return
	for(var/coords/qtnpc/N as anything in npc_coords)
		if(N.npc && range.contains(N))
			found_npcs.Add(N.npc)

/datum/quadtree/proc/query_range_hearables(datum/shape/range, list/found_hearables)
	if(!found_hearables)
		found_hearables = list()
	. = found_hearables
	if(!range?.intersects(boundary))
		return
	if(is_divided)
		nw_branch.query_range_hearables(range, found_hearables)
		ne_branch.query_range_hearables(range, found_hearables)
		sw_branch.query_range_hearables(range, found_hearables)
		se_branch.query_range_hearables(range, found_hearables)
	if(!hearable_coords)
		return
	for(var/coords/qthearable/H as anything in hearable_coords)
		if(H.hearable && range.contains(H))
			found_hearables.Add(H.hearable)
