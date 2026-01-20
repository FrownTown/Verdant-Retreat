/**
 * returns every hearaing movable in view to the turf of source not taking into account lighting
 * useful when you need to maintain always being able to hear something if a sound is emitted from it and you can see it (and youre in range).
 * otherwise this is just a more expensive version of get_hearers_in_LOS().
 *
 * * view_radius - what radius search circle we are using, worse performance as this increases
 * * source - object at the center of our search area. everything in get_turf(source) is guaranteed to be part of the search area
 * * contents_type - the type of contents we want to be looking for. defaults to hearing sensitive
 */
/proc/get_hearers_in_view(view_radius, atom/source, contents_type=RECURSIVE_CONTENTS_HEARING_SENSITIVE)
	var/turf/center_turf = get_turf(source)
	if(!center_turf)
		return

	. = list()

	if(view_radius <= 0)//special case for if only source cares
		for(var/atom/movable/target as anything in center_turf)
			var/list/recursive_contents = target.important_recursive_contents?[contents_type]
			if(recursive_contents)
				. += recursive_contents
		return .

	// Use Quadtree to find candidates
	var/datum/shape/rectangle/rect = new(center_turf.x, center_turf.y, view_radius*2 + 1, view_radius*2 + 1)
	var/list/candidates = SSquadtree.hearables_in_range(rect, center_turf.z)
	QDEL_NULL(rect)

	for(var/atom/movable/AM in candidates)
		if(!los_blocked(source, AM) && get_dist(center_turf, AM) <= view_radius)
			. += AM

	return .

/**
 * The exact same as get_hearers_in_view, but not limited by visibility. Does no filtering for traits, line of sight, or any other such criteria.
 * Filtering is intended to be done by whatever calls this function.
 *
 * This function exists to allow for mobs to hear speech without line of sight, if such a thing is needed.
 *
 * * radius - what radius search circle we are using, worse performance as this increases
 * * source - object at the center of our search area. everything in get_turf(source) is guaranteed to be part of the search area
 * * contents_type - the type of contents we want to be looking for. defaults to hearing sensitive
 */
/proc/get_hearers_in_range(range, atom/source, contents_type=RECURSIVE_CONTENTS_HEARING_SENSITIVE)
	var/turf/center_turf = get_turf(source)
	if(!center_turf)
		return

	. = list()

	if(range <= 0)//special case for if only source cares
		for(var/atom/movable/target as anything in center_turf)
			var/list/recursive_contents = target.important_recursive_contents?[contents_type]
			if(recursive_contents)
				. += recursive_contents
		return .

	// Use Quadtree
	var/datum/shape/rectangle/rect = new(center_turf.x, center_turf.y, range*2 + 1, range*2 + 1)
	var/list/candidates = SSquadtree.hearables_in_range(rect, center_turf.z)
	QDEL_NULL(rect)

	for(var/atom/movable/hearable as anything in candidates)
		if (get_dist(center_turf, hearable) <= range)
			. += hearable

	return .

/**
 * Returns a list of movable atoms that are hearing sensitive in view_radius and line of sight to source
 * the majority of the work is passed off to the quadtree if view_radius > 0
 * because view() isnt a raycasting algorithm, this does not hold symmetry to it. something in view might not be hearable with this.
 * if you want that use get_hearers_in_view() - however thats significantly more expensive
 *
 * * view_radius - what radius search circle we are using, worse performance as this increases but not as much as it used to
 * * source - object at the center of our search area. everything in get_turf(source) is guaranteed to be part of the search area
 */
/proc/get_hearers_in_LOS(view_radius, atom/source, contents_type=RECURSIVE_CONTENTS_HEARING_SENSITIVE)
	var/turf/center_turf = get_turf(source)
	if(!center_turf)
		return

	if(view_radius <= 0)//special case for if only source cares
		. = list()
		for(var/atom/movable/target as anything in center_turf)
			var/list/hearing_contents = target.important_recursive_contents?[contents_type]
			if(hearing_contents)
				. += hearing_contents
		return

	var/datum/shape/rectangle/rect = new(center_turf.x, center_turf.y, view_radius*2 + 1, view_radius*2 + 1)
	var/list/candidates = SSquadtree.hearables_in_range(rect, center_turf.z)
	QDEL_NULL(rect)

	. = list()

	for(var/atom/movable/target as anything in candidates)
		var/turf/target_turf = get_turf(target)
		var/distance = get_dist(center_turf, target_turf)

		if(distance > view_radius)
			continue

		if(distance < 2) //we should always be able to see something 0 or 1 tiles away
			. += target
			continue

		var/turf/inbetween_turf = center_turf
		var/blocked = FALSE
		for(var/step_counter in 1 to distance)
			inbetween_turf = get_step_towards(inbetween_turf, target_turf)

			if(inbetween_turf == target_turf)
				break

			if(inbetween_turf.opacity)
				blocked = TRUE
				break
		
		if(!blocked)
			. += target


//Used when converting pixels to tiles to make them accurate
#define OFFSET_X (0.5 / world.icon_size)
#define OFFSET_Y (0.5 / world.icon_size)

///Calculate if two atoms are in sight, returns TRUE or FALSE
/proc/inLineOfSight(X1,Y1,X2,Y2,Z=1,PX1=16.5,PY1=16.5,PX2=16.5,PY2=16.5)
	var/turf/current_turf
	if(X1 == X2)
		if(Y1 == Y2)
			return TRUE //Light cannot be blocked on same tile
		else
			var/sign = SIGN(Y2-Y1)
			Y1 += sign
			while(Y1 != Y2)
				current_turf = locate(X1, Y1, Z)
				if(current_turf.opacity)
					return FALSE
				Y1 += sign
	else
		//This looks scary but we're just calculating a linear function (y = mx + b)

		//m = y/x
		var/m = (world.icon_size*(Y2-Y1) + (PY2-PY1)) / (world.icon_size*(X2-X1) + (PX2-PX1))//In pixels

		//b = y - mx
		var/b = (Y1 + PY1/world.icon_size - OFFSET_Y) - m*(X1 + PX1/world.icon_size - OFFSET_X)//In tiles

		var/signX = SIGN(X2-X1)
		var/signY = SIGN(Y2-Y1)
		if(X1 < X2)
			b += m
		while(X1 != X2 || Y1 != Y2)
			if(round(m*X1 + b - Y1)) // Basically, if y >= mx+b
				Y1 += signY //Line exits tile vertically
			else
				X1 += signX //Line exits tile horizontally
			current_turf = locate(X1, Y1, Z)
			if(current_turf.opacity)
				return FALSE
	return TRUE

#undef OFFSET_X
#undef OFFSET_Y

/proc/is_in_sight(atom/first_atom, atom/second_atom)
	var/turf/first_turf = get_turf(first_atom)
	var/turf/second_turf = get_turf(second_atom)

	if(!first_turf || !second_turf)
		return FALSE

	return inLineOfSight(first_turf.x, first_turf.y, second_turf.x, second_turf.y, first_turf.z)

///Returns all atoms present in a circle around the center
/proc/circle_range(center = usr,radius = 3)

	var/turf/center_turf = get_turf(center)
	var/list/atoms = new/list()
	var/rsq = radius * (radius + 0.5)

	for(var/atom/checked_atom as anything in range(radius, center_turf))
		var/dx = checked_atom.x - center_turf.x
		var/dy = checked_atom.y - center_turf.y
		if(dx * dx + dy * dy <= rsq)
			atoms += checked_atom

	return atoms

///Returns all atoms present in a circle around the center but uses view() instead of range() (Currently not used)
/proc/circle_view(center=usr,radius=3)

	var/turf/center_turf = get_turf(center)
	var/list/atoms = new/list()
	var/rsq = radius * (radius + 0.5)

	for(var/atom/checked_atom as anything in view(radius, center_turf))
		var/dx = checked_atom.x - center_turf.x
		var/dy = checked_atom.y - center_turf.y
		if(dx * dx + dy * dy <= rsq)
			atoms += checked_atom

	return atoms

///Returns the distance between two atoms
/proc/get_dist_euclidean(atom/first_location, atom/second_location)
	var/dx = first_location.x - second_location.x
	var/dy = first_location.y - second_location.y

	var/dist = sqrt(dx ** 2 + dy ** 2)

	return dist

///Returns a list of turfs around a center based on RANGE_TURFS()
/proc/circle_range_turfs(center = usr, radius = 3)

	var/turf/center_turf = get_turf(center)
	var/list/turfs = new/list()
	var/rsq = radius * (radius + 0.5)

	for(var/turf/checked_turf as anything in RANGE_TURFS(radius, center_turf))
		var/dx = checked_turf.x - center_turf.x
		var/dy = checked_turf.y - center_turf.y
		if(dx * dx + dy * dy <= rsq)
			turfs += checked_turf
	return turfs

///Returns a list of turfs around a center based on view()
/proc/circle_view_turfs(center=usr,radius=3) //Is there even a diffrence between this proc and circle_range_turfs()? // Yes
	var/turf/center_turf = get_turf(center)
	var/list/turfs = new/list()
	var/rsq = radius * (radius + 0.5)

	for(var/turf/checked_turf in view(radius, center_turf))
		var/dx = checked_turf.x - center_turf.x
		var/dy = checked_turf.y - center_turf.y
		if(dx * dx + dy * dy <= rsq)
			turfs += checked_turf
	return turfs

///Returns the list of turfs around the outside of a center based on RANGE_TURFS()
/proc/border_diamond_range_turfs(atom/center = usr, radius = 3)
	var/turf/center_turf = get_turf(center)
	var/list/turfs = list()

	for(var/turf/checked_turf as anything in RANGE_TURFS(radius, center_turf))
		var/dx = checked_turf.x - center_turf.x
		var/dy = checked_turf.y - center_turf.y
		var/abs_sum = abs(dx) + abs(dy)
		if(abs_sum == radius)
			turfs += checked_turf
	return turfs

///Returns a slice of a list of turfs, defined by the ones that are inside the inner/outer angle's bounds
/proc/slice_off_turfs(atom/center, list/turf/turfs, inner_angle, outer_angle)
	var/turf/center_turf = get_turf(center)
	var/list/sliced_turfs = list()

	for(var/turf/checked_turf as anything in turfs)
		var/angle_to = Get_Angle(center_turf, checked_turf)
		if(angle_to < inner_angle || angle_to > outer_angle)
			continue
		sliced_turfs += checked_turf
	return sliced_turfs

/**
 * Get a bounding box of a list of atoms.
 *
 * Arguments:
 * - atoms - List of atoms. Can accept output of view() and range() procs.
 *
 * Returns: list(x1, y1, x2, y2)
 */
/proc/get_bbox_of_atoms(list/atoms)
	var/list/list_x = list()
	var/list/list_y = list()
	for(var/_a in atoms)
		var/atom/a = _a
		list_x += a.x
		list_y += a.y
	return list(
		min(list_x),
		min(list_y),
		max(list_x),
		max(list_y))

/// Like view but bypasses luminosity check
/proc/get_hear(range, atom/source)
	var/lum = source.luminosity
	source.luminosity = 6

	. = view(range, source)
	source.luminosity = lum

///Returns the open turf next to the center in a specific direction
/proc/get_open_turf_in_dir(atom/center, dir)
	var/turf/open/get_turf = get_step(center, dir)
	if(istype(get_turf))
		return get_turf

///Returns a list with all the adjacent open turfs. Clears the list of nulls in the end.
/proc/get_adjacent_open_turfs(atom/center)
	var/list/hand_back = list()
	// Inlined get_open_turf_in_dir, just to be fast
	var/turf/open/new_turf = get_step(center, NORTH)
	if(istype(new_turf))
		hand_back += new_turf
	new_turf = get_step(center, SOUTH)
	if(istype(new_turf))
		hand_back += new_turf
	new_turf = get_step(center, EAST)
	if(istype(new_turf))
		hand_back += new_turf
	new_turf = get_step(center, WEST)
	if(istype(new_turf))
		hand_back += new_turf
	return hand_back

///Returns a list with all the adjacent areas by getting the adjacent open turfs
/proc/get_adjacent_open_areas(atom/center)
	. = list()
	var/list/adjacent_turfs = get_adjacent_open_turfs(center)
	for(var/near_turf in adjacent_turfs)
		. |= get_area(near_turf)

/**
 * Returns a list with the names of the areas around a center at a certain distance
 * Returns the local area if no distance is indicated
 * Returns an empty list if the center is null
**/
/proc/get_areas_in_range(distance = 0, atom/center = usr)
	if(!distance)
		var/turf/center_turf = get_turf(center)
		return center_turf ? list(center_turf.loc) : list()
	if(!center)
		return list()

	var/list/turfs = RANGE_TURFS(distance, center)
	var/list/areas = list()
	for(var/turf/checked_turf as anything in turfs)
		areas |= checked_turf.loc
	return areas

///Returns a list of all areas that are adjacent to the center atom's area, clear the list of nulls at the end.
/proc/get_adjacent_areas(atom/center)
	. = list(
		get_area(get_ranged_target_turf(center, NORTH, 1)),
		get_area(get_ranged_target_turf(center, SOUTH, 1)),
		get_area(get_ranged_target_turf(center, EAST, 1)),
		get_area(get_ranged_target_turf(center, WEST, 1))
		)
	list_clear_nulls(.)

///Returns a list of all turfs that are adjacent to the center atom's turf, clear the list of nulls at the end.
/proc/get_adjacent_turfs(atom/center)
	. = list(
		get_step(center, NORTH),
		get_step(center, SOUTH),
		get_step(center, EAST),
		get_step(center, WEST)
		)
	list_clear_nulls(.)

///Checks if the mob provided (must_be_alone) is alone in an area
/proc/alone_in_area(area/the_area, mob/must_be_alone, check_type = /mob/living/carbon)
	var/area/our_area = get_area(the_area)
	for(var/carbon in GLOB.alive_mob_list)
		if(!istype(carbon, check_type))
			continue
		if(carbon == must_be_alone)
			continue
		if(our_area == get_area(carbon))
			return FALSE
	return TRUE

/**
 * Behaves like the orange() proc, but only looks in the outer range of the function (The "peel" of the orange).
 * This is useful for things like checking if a mob is in a certain range, but not within a smaller range.
 *
 * @params outer_range - The outer range of the cicle to pull from.
 * @params inner_range - The inner range of the circle to NOT pull from.
 * @params center - The center of the circle to pull from, can be an atom (we'll apply get_turf() to it within circle_x_turfs procs.)
 * @params view_based - If TRUE, we'll use circle_view_turfs instead of circle_range_turfs procs.
 */
/proc/turf_peel(outer_range, inner_range, center, view_based = FALSE)
	if(inner_range > outer_range) // If the inner range is larger than the outer range, you're using this wrong.
		CRASH("Turf peel inner range is larger than outer range!")
	var/list/peel = list()
	var/list/outer
	var/list/inner
	if(view_based)
		outer = circle_view_turfs(center, outer_range)
		inner = circle_view_turfs(center, inner_range)
	else
		outer = circle_range_turfs(center, outer_range)
		inner = circle_range_turfs(center, inner_range)
	for(var/turf/possible_spawn as anything in outer)
		if(possible_spawn in inner)
			continue
		peel += possible_spawn

	if(!length(peel))
		return center //Offer the center only as a default case when we don't have a valid circle.
	return peel

///check if 2 diagonal turfs are blocked by dense objects
/proc/diagonally_blocked(turf/our_turf, turf/dest_turf)
	if(get_dist(our_turf, dest_turf) != 1)
		return FALSE
	var/direction_to_turf = get_dir(dest_turf, our_turf)
	if(!ISDIAGONALDIR(direction_to_turf))
		return FALSE
	for(var/direction_check in GLOB.cardinals)
		if(!(direction_check & direction_to_turf))
			continue
		var/turf/test_turf = get_step(dest_turf, direction_check)
		if(isnull(test_turf))
			continue
		if(!test_turf.is_blocked_turf(exclude_mobs = TRUE))
			return FALSE
	return TRUE
