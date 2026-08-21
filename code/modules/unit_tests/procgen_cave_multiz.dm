/datum/unit_test/procgen_cave_multiz
	var/list/report = list()
	var/list/restore_area = list()
	var/lower_z = 0
	var/upper_z = 0

/datum/unit_test/procgen_cave_multiz/proc/note(text)
	report += text

/datum/unit_test/procgen_cave_multiz/proc/find_test_z_pair()
	for(var/candidate in 1 to length(SSmapping.multiz_levels) - 1)
		var/list/lower = SSmapping.multiz_levels[candidate]
		var/list/upper = SSmapping.multiz_levels[candidate + 1]
		if(lower[Z_LEVEL_UP] && upper[Z_LEVEL_DOWN])
			return candidate
	return 0

/datum/unit_test/procgen_cave_multiz/proc/find_water_test_z()
	for(var/candidate in 1 to length(SSmapping.multiz_levels) - 1)
		var/list/level = SSmapping.multiz_levels[candidate]
		var/list/next_level = SSmapping.multiz_levels[candidate + 1]
		if(level[Z_LEVEL_UP] && level[Z_LEVEL_DOWN] && next_level[Z_LEVEL_DOWN])
			return candidate
	return 0

/datum/unit_test/procgen_cave_multiz/proc/fill_walls(x1, y1, x2, y2, z1, z2)
	for(var/x = x1, x <= x2, x++)
		for(var/y = y1, y <= y2, y++)
			for(var/z = z1, z <= z2, z++)
				var/turf/T = locate(x, y, z)
				if(!T)
					continue
				if(istype(T, /turf/closed/wall/mineral/rogue/stone))
					continue
				T.ChangeTurf(/turf/closed/wall/mineral/rogue/stone)

/datum/unit_test/procgen_cave_multiz/proc/claim_turfs(area/procedural_generation/target, list/coords, z)
	var/list/claimed = list()
	for(var/list/coord as anything in coords)
		var/turf/T = locate(coord[1], coord[2], z)
		if(!T)
			continue
		var/area/old_area = T.loc
		var/key = "[T.x]-[T.y]-[T.z]"
		if(!restore_area[key])
			restore_area[key] = old_area
		target.contents += T
		T.change_area(old_area, target)
		claimed += T
	return claimed

/datum/unit_test/procgen_cave_multiz/proc/release_turfs(list/turfs)
	for(var/turf/T as anything in turfs)
		var/key = "[T.x]-[T.y]-[T.z]"
		var/area/original = restore_area[key]
		if(!original)
			continue
		var/area/current = T.loc
		if(current == original)
			continue
		original.contents += T
		T.change_area(current, original)

/datum/unit_test/procgen_cave_multiz/proc/rect_coords(x1, y1, x2, y2)
	var/list/out = list()
	for(var/x = x1, x <= x2, x++)
		for(var/y = y1, y <= y2, y++)
			out += list(list(x, y))
	return out

/datum/unit_test/procgen_cave_multiz/proc/coord_set(list/coords)
	var/list/out = list()
	for(var/list/coord as anything in coords)
		out["[coord[1]]-[coord[2]]"] = TRUE
	return out

/datum/unit_test/procgen_cave_multiz/proc/find_shafts(list/lower_coords, list/upper_coords, z, next_z)
	var/list/lower_set = coord_set(lower_coords)
	var/list/upper_set = coord_set(upper_coords)
	var/list/shafts = list()
	for(var/key in upper_set)
		if(!lower_set[key])
			continue
		var/list/coords = splittext(key, "-")
		var/x = text2num(coords[1])
		var/y = text2num(coords[2])
		var/turf/UT = locate(x, y, next_z)
		if(!istype(UT, /turf/open/transparent/openspace))
			continue
		var/turf/LT = locate(x, y, z)
		if(LT && !iswall(LT) && !istype(LT, /turf/open/transparent/openspace))
			shafts += key
	return shafts

/datum/unit_test/procgen_cave_multiz/proc/shaft_reaches_carved_floor(x, y, z, list/footprint_set)
	for(var/list/offset as anything in list(list(1, 0), list(-1, 0), list(0, 1), list(0, -1)))
		var/nx = x + offset[1]
		var/ny = y + offset[2]
		var/neighbor_key = "[nx]-[ny]"
		if(!footprint_set[neighbor_key])
			continue
		var/turf/NT = locate(nx, ny, z)
		if(NT && !iswall(NT) && !istype(NT, /turf/open/transparent/openspace))
			return TRUE
	return FALSE

/datum/unit_test/procgen_cave_multiz/proc/bfs_reaches_upper(list/lower_coords, list/upper_coords, list/shafts, z, next_z)
	var/list/lower_set = coord_set(lower_coords)
	var/list/upper_set = coord_set(upper_coords)
	var/list/shaft_set = list()
	for(var/key in shafts)
		shaft_set[key] = TRUE

	var/list/visited = list()
	var/list/frontier = list()
	for(var/key in lower_set)
		var/list/coords = splittext(key, "-")
		var/turf/T = locate(text2num(coords[1]), text2num(coords[2]), z)
		if(T && !iswall(T))
			frontier += key
			visited[key] = TRUE

	var/cursor = 1
	while(cursor <= length(frontier))
		var/key = frontier[cursor++]
		var/list/coords = splittext(key, "-")
		var/cx = text2num(coords[1])
		var/cy = text2num(coords[2])
		for(var/list/offset as anything in list(list(1, 0), list(-1, 0), list(0, 1), list(0, -1)))
			var/neighbor_key = "[cx + offset[1]]-[cy + offset[2]]"
			if(!lower_set[neighbor_key] || visited[neighbor_key])
				continue
			var/turf/NT = locate(cx + offset[1], cy + offset[2], z)
			if(!NT || iswall(NT))
				continue
			visited[neighbor_key] = TRUE
			frontier += neighbor_key
		if(shaft_set[key] && shaft_reaches_carved_floor(cx, cy, next_z, upper_set))
			return TRUE
	return FALSE

/datum/unit_test/procgen_cave_multiz/proc/test_connectivity()
	var/list/coords = rect_coords(90, 10, 109, 29)
	fill_walls(90, 10, 109, 29, lower_z, upper_z)

	var/area/procedural_generation/cave/multiz/test/subject = new
	subject.min_links_per_component = 8
	subject.max_links_per_component = 8
	var/list/claimed = claim_turfs(subject, coords, lower_z) + claim_turfs(subject, coords, upper_z)

	subject.setup_procgen()

	var/list/shafts = find_shafts(coords, coords, lower_z, upper_z)
	note("connectivity: [length(shafts)] shafts placed in a [length(coords)]-cell footprint")
	TEST_ASSERT(length(shafts) > 0, "No climb shafts were placed connecting z [lower_z] to z [upper_z]")

	var/reached = bfs_reaches_upper(coords, coords, shafts, lower_z, upper_z)
	TEST_ASSERT(reached, "No carved cell on z [lower_z] can reach a carved cell on z [upper_z] via cardinal steps and climb shafts")

	release_turfs(claimed)
	SSprocgen.fluid_cells.Cut()
	SSprocgen.mimic_turfs.Cut()

/datum/unit_test/procgen_cave_multiz/proc/test_islands()
	var/list/west = rect_coords(60, 40, 71, 51)
	var/list/east = rect_coords(85, 40, 96, 51)
	var/list/coords = west + east
	fill_walls(60, 40, 96, 51, lower_z, upper_z)

	var/area/procedural_generation/cave/multiz/test/subject = new
	subject.min_links_per_component = 8
	subject.max_links_per_component = 8
	var/list/claimed = claim_turfs(subject, coords, lower_z) + claim_turfs(subject, coords, upper_z)

	subject.setup_procgen()

	var/list/shafts = find_shafts(coords, coords, lower_z, upper_z)
	var/list/west_set = coord_set(west)
	var/list/east_set = coord_set(east)
	var/west_shafts = 0
	var/east_shafts = 0
	for(var/key in shafts)
		if(west_set[key])
			west_shafts++
		if(east_set[key])
			east_shafts++

	note("islands: west [west_shafts] shafts, east [east_shafts] shafts")
	TEST_ASSERT(west_shafts > 0, "The west island has no climb shaft connecting z [lower_z] to z [upper_z]")
	TEST_ASSERT(east_shafts > 0, "The east island has no climb shaft connecting z [lower_z] to z [upper_z]")

	release_turfs(claimed)
	SSprocgen.fluid_cells.Cut()
	SSprocgen.mimic_turfs.Cut()

/datum/unit_test/procgen_cave_multiz/proc/test_water_exclusion()
	var/water_z = find_water_test_z()
	if(!water_z)
		note("water exclusion: skipped, no z has both an up and a down link plus a linked upper level")
		return
	var/water_upper_z = water_z + 1

	var/list/coords = rect_coords(90, 100, 109, 119)
	var/total_shafts = 0
	var/total_violations = 0
	var/water_cells_seen = 0
	var/carved_lower_seen = 0

	for(var/pass in 1 to 3)
		fill_walls(86, 96, 113, 123, water_z - 1, water_z - 1)
		fill_walls(90, 100, 109, 119, water_z, water_upper_z)

		var/area/procedural_generation/cave/multiz/test/subject = new
		subject.generate_water = TRUE
		subject.min_lakes = 6
		subject.max_lakes = 8
		subject.min_lake_size = 6
		subject.max_lake_size = 10
		var/list/claimed = claim_turfs(subject, coords, water_z) + claim_turfs(subject, coords, water_upper_z)

		subject.setup_procgen()

		for(var/list/coord as anything in coords)
			var/turf/T = locate(coord[1], coord[2], water_z)
			if(T && !iswall(T))
				carved_lower_seen++

		var/list/upper_set = coord_set(coords)
		for(var/key in upper_set)
			var/list/xy = splittext(key, "-")
			var/lx = text2num(xy[1])
			var/ly = text2num(xy[2])
			var/turf/LT = locate(lx, ly, water_z)
			if(LT && istype(LT, /turf/open/transparent/openspace))
				water_cells_seen++
			var/turf/UT = locate(lx, ly, water_upper_z)
			if(!istype(UT, /turf/open/transparent/openspace))
				continue
			total_shafts++
			var/turf/BT = GetBelow(UT)
			if(!BT || istype(BT, /turf/open/transparent/openspace) || (BT in SSprocgen.fluid_cells))
				total_violations++

		for(var/list/coord as anything in coords)
			var/turf/T = locate(coord[1], coord[2], water_z)
			if(T && T.cell)
				SSliquid.clear_cell_fluid(T)
			var/turf/below = locate(coord[1], coord[2], water_z - 1)
			if(below && below.cell)
				SSliquid.clear_cell_fluid(below)

		release_turfs(claimed)
		SSprocgen.fluid_cells.Cut()
		SSprocgen.mimic_turfs.Cut()

	note("water exclusion: [total_shafts] shafts across 3 passes, [carved_lower_seen] carved lower cells, [water_cells_seen] water cells seen, [total_violations] violations")
	TEST_ASSERT_EQUAL(total_violations, 0, "[total_violations] climb shafts opened above a water or openspace tile across 3 passes")
	TEST_ASSERT(water_cells_seen > 0, "No water was generated across 3 passes, so containment is untested")

/datum/unit_test/procgen_cave_multiz/proc/test_z_gap()
	var/gap_upper_z = lower_z + 2
	if(gap_upper_z > length(SSmapping.multiz_levels))
		note("z-gap: skipped, only a 2-z linked run exists past z [lower_z]")
		return
	if(!locate(1, 1, gap_upper_z))
		note("z-gap: skipped, z [gap_upper_z] has no turfs")
		return

	var/list/coords = rect_coords(60, 80, 79, 99)
	fill_walls(60, 80, 79, 99, lower_z, lower_z)
	fill_walls(60, 80, 79, 99, gap_upper_z, gap_upper_z)

	var/area/procedural_generation/cave/multiz/test/subject = new
	var/list/claimed = claim_turfs(subject, coords, lower_z) + claim_turfs(subject, coords, gap_upper_z)

	subject.setup_procgen()

	var/carved_gap = 0
	for(var/list/coord as anything in coords)
		var/turf/T = locate(coord[1], coord[2], lower_z + 1)
		if(T && istype(T, /turf/open/transparent/openspace))
			carved_gap++

	note("z-gap: [carved_gap] openspace turfs on the skipped z [lower_z + 1]")
	TEST_ASSERT_EQUAL(carved_gap, 0, "the skipped z [lower_z + 1] had [carved_gap] openspace turfs carved into it despite having no claimed footprint")

	release_turfs(claimed)
	SSprocgen.fluid_cells.Cut()
	SSprocgen.mimic_turfs.Cut()

/datum/unit_test/procgen_cave_multiz/proc/test_backward_compat()
	var/list/coords = rect_coords(90, 80, 109, 99)
	fill_walls(90, 80, 109, 99, lower_z, upper_z)

	var/list/before_lower = list()
	var/list/before_upper = list()
	for(var/list/coord as anything in coords)
		var/turf/LT = locate(coord[1], coord[2], lower_z)
		var/turf/UT = locate(coord[1], coord[2], upper_z)
		if(LT)
			before_lower["[coord[1]]-[coord[2]]"] = LT.type
		if(UT)
			before_upper["[coord[1]]-[coord[2]]"] = UT.type

	var/area/procedural_generation/cave/test/subject = new
	var/list/claimed = claim_turfs(subject, coords, lower_z) + claim_turfs(subject, coords, upper_z)

	subject.setup_procgen()

	var/target_z = subject.z
	var/off_z = (target_z == lower_z) ? upper_z : lower_z
	var/list/off_before = (off_z == lower_z) ? before_lower : before_upper

	var/changed = 0
	for(var/list/coord as anything in coords)
		var/turf/T = locate(coord[1], coord[2], off_z)
		var/before_type = off_before["[coord[1]]-[coord[2]]"]
		if(T && before_type && T.type != before_type)
			changed++

	note("backward-compat: single-z cave targeted z [target_z], [changed] turfs on the off-level z [off_z] changed type")
	TEST_ASSERT_EQUAL(changed, 0, "[changed] turfs on the off-level z [off_z] changed type when a single-z (multiz_generation FALSE) cave's contents spanned two z levels")

	release_turfs(claimed)
	SSprocgen.fluid_cells.Cut()
	SSprocgen.mimic_turfs.Cut()

/datum/unit_test/procgen_cave_multiz/Run()
	lower_z = find_test_z_pair()
	TEST_ASSERT(lower_z, "No adjacent z pair on this map has UP on the lower level and DOWN on the upper level")
	upper_z = lower_z + 1
	note("running on z [lower_z] -> z [upper_z] of [length(SSmapping.multiz_levels)] linked levels")

	test_connectivity()
	test_islands()
	test_water_exclusion()
	test_z_gap()
	test_backward_compat()

	fdel("data/procgen_cave_multiz_test.txt")
	var/logfile = file("data/procgen_cave_multiz_test.txt")
	for(var/line in report)
		logfile << line
