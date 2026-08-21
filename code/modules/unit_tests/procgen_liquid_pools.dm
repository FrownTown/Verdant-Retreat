/datum/unit_test/procgen_liquid_pools
	var/list/report = list()
	var/test_z = 0
	var/list/restore_area = list()
	var/passes = 3
	var/pool_seen_total = 0
	var/water_seen_total = 0

/datum/unit_test/procgen_liquid_pools/proc/note(text)
	report += text

/datum/unit_test/procgen_liquid_pools/proc/find_test_z()
	for(var/candidate in 1 to length(SSmapping.multiz_levels))
		var/list/level = SSmapping.multiz_levels[candidate]
		if(level[Z_LEVEL_UP] && level[Z_LEVEL_DOWN])
			return candidate
	return 0

/datum/unit_test/procgen_liquid_pools/proc/fill_walls(x1, y1, x2, y2, z)
	for(var/x = x1, x <= x2, x++)
		for(var/y = y1, y <= y2, y++)
			var/turf/T = locate(x, y, z)
			if(!T)
				continue
			if(istype(T, /turf/closed/mineral/rogue/bedrock))
				continue
			T.ChangeTurf(/turf/closed/mineral/rogue/bedrock)

/datum/unit_test/procgen_liquid_pools/proc/rect_coords(x1, y1, x2, y2)
	var/list/out = list()
	for(var/x = x1, x <= x2, x++)
		for(var/y = y1, y <= y2, y++)
			out += list(list(x, y))
	return out

/datum/unit_test/procgen_liquid_pools/proc/claim_turfs(area/procedural_generation/target, list/coords, z)
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

/datum/unit_test/procgen_liquid_pools/proc/release_turfs(list/turfs)
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

/datum/unit_test/procgen_liquid_pools/proc/clear_footprint_fluid(list/coords, z)
	for(var/list/coord as anything in coords)
		var/turf/T = locate(coord[1], coord[2], z)
		if(T && T.cell)
			SSliquid.clear_cell_fluid(T)
		var/turf/below = locate(coord[1], coord[2], z - 1)
		if(below && below.cell)
			SSliquid.clear_cell_fluid(below)

/datum/unit_test/procgen_liquid_pools/proc/new_subject()
	var/area/procedural_generation/cave/lava/subject = new
	subject.max_caverns = 4
	subject.min_cavern_size = 6
	subject.max_cavern_size = 10
	subject.min_tunnels = 3
	subject.max_tunnels = 6
	subject.max_tunnel_length = 8
	subject.min_pools = 3
	subject.max_pools = 3
	subject.min_pool_size = 8
	subject.max_pool_size = 12
	return subject

/datum/unit_test/procgen_liquid_pools/proc/run_pools_only(pass)
	var/list/coords = rect_coords(90, 15, 109, 34)

	fill_walls(90, 15, 109, 34, test_z)

	var/area/procedural_generation/cave/lava/subject = new_subject()
	var/list/claimed = claim_turfs(subject, coords, test_z)

	subject.setup_procgen()

	var/pool_seen = 0
	for(var/list/coord as anything in coords)
		var/turf/T = locate(coord[1], coord[2], test_z)
		if(!istype(T, /turf/open/floor/rogue/pool/lava))
			continue
		pool_seen++
		TEST_ASSERT_NOTNULL(T.cell, "lava pool turf at [coord[1]],[coord[2]] has no liquid cell")
		var/datum/liquid/fluid = T.cell.get_fluid_datum(/datum/liquid/lava)
		TEST_ASSERT_NOTNULL(fluid, "lava pool turf at [coord[1]],[coord[2]] has no lava fluid datum")
		TEST_ASSERT_EQUAL(T.cell.fluid_volume[fluid], MAX_FLUID_VOLUME, "lava pool turf at [coord[1]],[coord[2]] did not initialize at max fluid volume")
		TEST_ASSERT_EQUAL(T.cell.is_liquid_source, TRUE, "lava pool turf at [coord[1]],[coord[2]] is not a liquid source")

	note("pools_only #[pass]: [pool_seen] lava pool turfs in a [length(coords)]-cell footprint")
	pool_seen_total += pool_seen

	clear_footprint_fluid(coords, test_z)
	release_turfs(claimed)
	SSprocgen.fluid_cells.Cut()
	SSprocgen.mimic_turfs.Cut()

/datum/unit_test/procgen_liquid_pools/proc/run_pools_with_water(pass)
	var/list/coords = rect_coords(90, 15, 109, 34)

	fill_walls(86, 11, 113, 38, test_z - 1)
	fill_walls(90, 15, 109, 34, test_z)

	var/area/procedural_generation/cave/lava/subject = new_subject()
	subject.generate_water = TRUE
	subject.min_lakes = 4
	subject.max_lakes = 6
	subject.min_lake_size = 6
	subject.max_lake_size = 10

	var/list/claimed = claim_turfs(subject, coords, test_z)

	subject.setup_procgen()

	var/pool_seen = 0
	var/water_seen = 0
	var/list/pool_coords = list()
	var/list/water_coords = list()
	for(var/list/coord as anything in coords)
		var/key = "[coord[1]]-[coord[2]]"
		var/turf/T = locate(coord[1], coord[2], test_z)
		if(istype(T, /turf/open/floor/rogue/pool/lava))
			pool_seen++
			pool_coords[key] = TRUE
		if(istype(T, /turf/open/transparent/openspace))
			var/turf/below = GetBelow(T)
			if(istype(below, /turf/open/floor/rogue/lakebed))
				water_seen++
				water_coords[key] = TRUE

	var/overlap = 0
	for(var/key in pool_coords)
		if(water_coords[key])
			overlap++

	note("pools_with_water #[pass]: [pool_seen] lava pool turfs, [water_seen] lakebed water turfs, [overlap] overlapping cells in a [length(coords)]-cell footprint")
	pool_seen_total += pool_seen
	water_seen_total += water_seen

	TEST_ASSERT_EQUAL(overlap, 0, "[overlap] cells were carved as both a lava pool and lake water in the same pass")

	clear_footprint_fluid(coords, test_z)
	release_turfs(claimed)
	SSprocgen.fluid_cells.Cut()
	SSprocgen.mimic_turfs.Cut()

/datum/unit_test/procgen_liquid_pools/Run()
	test_z = find_test_z()
	TEST_ASSERT(test_z, "No z level on this map has both an up and a down link")
	note("running on z [test_z] of [length(SSmapping.multiz_levels)] linked levels")

	for(var/pass in 1 to passes)
		run_pools_only(pass)
		run_pools_with_water(pass)

	TEST_ASSERT(pool_seen_total > 0, "No lava pool turfs were generated across [passes] passes, so pool carving is untested")
	TEST_ASSERT(water_seen_total > 0, "No lake water was generated across [passes] passes of the pools+water case, so overlap avoidance is untested")

	fdel("data/procgen_liquid_pools_test.txt")
	var/logfile = file("data/procgen_liquid_pools_test.txt")
	for(var/line in report)
		logfile << line
