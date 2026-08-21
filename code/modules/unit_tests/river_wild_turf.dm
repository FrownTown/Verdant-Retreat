/datum/unit_test/river_wild_turf
	var/list/report = list()
	var/test_z = 0
	var/list/restore_area = list()

/datum/unit_test/river_wild_turf/proc/note(text)
	report += text

/datum/unit_test/river_wild_turf/proc/find_test_z()
	for(var/candidate in 1 to length(SSmapping.multiz_levels))
		var/list/level = SSmapping.multiz_levels[candidate]
		if(level[Z_LEVEL_UP] && level[Z_LEVEL_DOWN])
			return candidate
	return 0

/datum/unit_test/river_wild_turf/proc/fill_walls(x1, y1, x2, y2, z)
	for(var/x = x1, x <= x2, x++)
		for(var/y = y1, y <= y2, y++)
			var/turf/T = locate(x, y, z)
			if(!T)
				continue
			if(istype(T, /turf/closed/mineral/rogue/bedrock))
				continue
			T.ChangeTurf(/turf/closed/mineral/rogue/bedrock)

/datum/unit_test/river_wild_turf/proc/rect_coords(x1, y1, x2, y2)
	var/list/out = list()
	for(var/x = x1, x <= x2, x++)
		for(var/y = y1, y <= y2, y++)
			out += list(list(x, y))
	return out

/datum/unit_test/river_wild_turf/proc/claim_turfs(area/procedural_generation/target, list/coords, z)
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

/datum/unit_test/river_wild_turf/proc/release_turfs(list/turfs)
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

/datum/unit_test/river_wild_turf/proc/test_river_wild()
	var/x = 52
	var/y = 10
	var/turf/seed_below = locate(x, y, test_z - 1)
	TEST_ASSERT(seed_below, "no turf below the river/wild test coordinate")
	seed_below.ChangeTurf(/turf/closed/mineral/rogue/bedrock)

	var/turf/T = locate(x, y, test_z)
	TEST_ASSERT(T, "no turf at the river/wild test coordinate")
	T = T.ChangeTurf(/turf/open/water/river/wild, null, CHANGETURF_IGNORE_AIR)

	TEST_ASSERT(istype(T, /turf/open/transparent/openspace), "river/wild surface turf is [T.type], expected openspace")

	var/turf/below = GetBelow(T)
	TEST_ASSERT(below, "no turf below the river/wild surface")
	TEST_ASSERT(istype(below, /turf/open/floor/rogue/riverbot), "river/wild bed is [below.type], expected riverbot")
	TEST_ASSERT(below.cell, "river/wild bed has no cell")
	TEST_ASSERT_EQUAL(below.cell.is_liquid_source, TRUE, "river/wild bed is_liquid_source")
	TEST_ASSERT_EQUAL(below.cell.fluidsum, MAX_FLUID_VOLUME, "river/wild bed fluidsum")
	TEST_ASSERT(below in SSmapping.water_bed_turfs, "river/wild bed not registered in SSmapping.water_bed_turfs")

	note("river_wild: surface [T.type], bed [below.type], fluidsum [below.cell.fluidsum], source [below.cell.is_liquid_source]")

	if(T.cell)
		SSliquid.clear_cell_fluid(T)
	if(below.cell)
		SSliquid.clear_cell_fluid(below)

/datum/unit_test/river_wild_turf/proc/test_river_host_regression()
	var/x = 52
	var/y = 12
	var/turf/seed_below = locate(x, y, test_z - 1)
	TEST_ASSERT(seed_below, "no turf below the river host-regression test coordinate")
	seed_below.ChangeTurf(/turf/closed/mineral/rogue/bedrock)

	var/turf/T = locate(x, y, test_z)
	TEST_ASSERT(T, "no turf at the river host-regression test coordinate")
	T = T.ChangeTurf(/turf/open/water/river, null, CHANGETURF_IGNORE_AIR)

	var/turf/below = GetBelow(T)
	TEST_ASSERT(below, "no turf below the plain river surface")
	TEST_ASSERT(istype(below, /turf/open/floor/rogue/sand), "plain river bed is [below.type], expected sand")
	TEST_ASSERT(below.cell, "plain river bed has no cell")
	TEST_ASSERT_EQUAL(below.cell.is_liquid_source, FALSE, "plain river bed is_liquid_source, the host's turf must stay a one-shot fill")
	TEST_ASSERT_EQUAL(below.cell.fluidsum, 100, "plain river bed fluidsum")

	note("river_host_regression: bed [below.type], fluidsum [below.cell.fluidsum], source [below.cell.is_liquid_source]")

	if(T.cell)
		SSliquid.clear_cell_fluid(T)
	if(below.cell)
		SSliquid.clear_cell_fluid(below)

/datum/unit_test/river_wild_turf/proc/test_lakebed_procgen()
	var/x = 52
	var/y = 14
	var/turf/T = locate(x, y, test_z)
	TEST_ASSERT(T, "no turf at the lakebed/procgen test coordinate")
	T = T.ChangeTurf(/turf/open/floor/rogue/lakebed/procgen, null, CHANGETURF_IGNORE_AIR)
	TEST_ASSERT(T.cell, "lakebed/procgen has no cell")
	var/datum/liquid/water_fluid = T.cell.get_fluid_datum(WATER)
	TEST_ASSERT_NOTNULL(water_fluid, "lakebed/procgen cell has no water fluid datum")
	TEST_ASSERT_EQUAL(T.cell.fluid_volume[water_fluid], MAX_FLUID_VOLUME, "lakebed/procgen must initialize at max fluid volume")
	TEST_ASSERT_EQUAL(T.cell.is_liquid_source, FALSE, "lakebed/procgen must not be a liquid source")

	var/x2 = 52
	var/y2 = 16
	var/turf/T2 = locate(x2, y2, test_z)
	TEST_ASSERT(T2, "no turf at the plain lakebed test coordinate")
	T2 = T2.ChangeTurf(/turf/open/floor/rogue/lakebed, null, CHANGETURF_IGNORE_AIR)
	TEST_ASSERT(T2.cell, "plain lakebed has no cell")
	TEST_ASSERT_EQUAL(T2.cell.is_liquid_source, TRUE, "plain lakebed must remain a liquid source")

	note("lakebed_procgen: procgen source [T.cell.is_liquid_source], plain lakebed source [T2.cell.is_liquid_source]")

	if(T.cell)
		SSliquid.clear_cell_fluid(T)
	if(T2.cell)
		SSliquid.clear_cell_fluid(T2)

/datum/unit_test/river_wild_turf/proc/test_cave_lakebed_procgen()
	var/list/coords = rect_coords(56, 40, 75, 59)
	var/lakebed_seen = 0
	var/registered_seen = 0
	var/contain_seen = 0

	for(var/pass in 1 to 3)
		fill_walls(52, 36, 79, 63, test_z - 1)
		fill_walls(56, 40, 75, 59, test_z)

		var/area/procedural_generation/cave/test/subject = new
		subject.generate_water = TRUE
		subject.min_lakes = 6
		subject.max_lakes = 8
		subject.min_lake_size = 6
		subject.max_lake_size = 10
		var/list/claimed = claim_turfs(subject, coords, test_z)

		subject.setup_procgen()

		for(var/list/coord as anything in coords)
			var/turf/T = locate(coord[1], coord[2], test_z)
			if(!istype(T, /turf/open/transparent/openspace))
				continue
			var/turf/below = GetBelow(T)
			if(!istype(below, /turf/open/floor/rogue/lakebed/procgen))
				continue
			lakebed_seen++
			if(below in SSmapping.water_bed_turfs)
				registered_seen++
			if(below.cell && below.cell.contain_max)
				contain_seen++

		for(var/list/coord as anything in coords)
			var/turf/T = locate(coord[1], coord[2], test_z)
			if(T && T.cell)
				SSliquid.clear_cell_fluid(T)
			var/turf/below = locate(coord[1], coord[2], test_z - 1)
			if(below && below.cell)
				SSliquid.clear_cell_fluid(below)

		release_turfs(claimed)
		SSprocgen.fluid_cells.Cut()
		SSprocgen.mimic_turfs.Cut()

	note("cave_lakebed_procgen: [lakebed_seen] lakebed/procgen tiles seen, [registered_seen] registered water beds, [contain_seen] with contain_max set, across 3 passes")

	TEST_ASSERT(lakebed_seen > 0, "No lakebed/procgen tiles were generated across 3 passes of the flooded test cave, so cave water-bed carving is untested")
	TEST_ASSERT_EQUAL(registered_seen, lakebed_seen, "[lakebed_seen - registered_seen] lakebed/procgen tiles were not registered in SSmapping.water_bed_turfs")
	TEST_ASSERT_EQUAL(contain_seen, lakebed_seen, "[lakebed_seen - contain_seen] lakebed/procgen tiles did not have contain_max set")

/datum/unit_test/river_wild_turf/Run()
	test_z = find_test_z()
	TEST_ASSERT(test_z, "No z level on this map has both an up and a down link")
	note("running on z [test_z] of [length(SSmapping.multiz_levels)] linked levels")

	test_river_wild()
	test_river_host_regression()
	test_lakebed_procgen()
	test_cave_lakebed_procgen()

	fdel("data/river_wild_turf_test.txt")
	var/logfile = file("data/river_wild_turf_test.txt")
	for(var/line in report)
		logfile << line
