#define TEST_OW_OCEAN 20
#define TEST_OW_COAST 21
#define TEST_OW_PLAINS 22
#define TEST_OW_DESERT 23
#define TEST_OW_SWAMP 24
#define TEST_OW_MOUNTAINS 25
#define TEST_OW_RIVER 26

/datum/unit_test/procgen_overworld
	var/list/report = list()
	var/list/restore_area = list()
	var/base_z = 0
	var/run_length = 0
	var/snapshot_seed
	var/snapshot_west
	var/list/biome_snapshot
	var/list/height_snapshot
	var/footprint_x1 = 55
	var/footprint_y1 = 5
	var/footprint_x2 = 124
	var/footprint_y2 = 69
	var/test_island_noise_threshold = 85
	var/test_desert_temp_min = 55
	var/test_swamp_temp_min = 40

/datum/unit_test/procgen_overworld/proc/note(text)
	report += text

/datum/unit_test/procgen_overworld/proc/find_test_z_run(run_length_needed)
	var/max_z = length(SSmapping.multiz_levels)
	for(var/base = 2, base + run_length_needed - 1 <= max_z, base++)
		var/list/base_level = SSmapping.multiz_levels[base]
		if(!base_level[Z_LEVEL_DOWN])
			continue
		var/ok = TRUE
		for(var/i = 0, i < run_length_needed - 1, i++)
			var/list/lower = SSmapping.multiz_levels[base + i]
			var/list/upper = SSmapping.multiz_levels[base + i + 1]
			if(!lower[Z_LEVEL_UP] || !upper[Z_LEVEL_DOWN])
				ok = FALSE
				break
		if(ok)
			return base
	return 0

/datum/unit_test/procgen_overworld/proc/fill_turf_type(x1, y1, x2, y2, z, type)
	for(var/x = x1, x <= x2, x++)
		for(var/y = y1, y <= y2, y++)
			var/turf/T = locate(x, y, z)
			if(!T)
				continue
			if(T.type != type)
				T.ChangeTurf(type)

/datum/unit_test/procgen_overworld/proc/claim_turfs(area/procedural_generation/target, list/coords, z)
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

/datum/unit_test/procgen_overworld/proc/release_turfs(list/turfs)
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

/datum/unit_test/procgen_overworld/proc/rect_coords(x1, y1, x2, y2)
	var/list/out = list()
	for(var/x = x1, x <= x2, x++)
		for(var/y = y1, y <= y2, y++)
			out += list(list(x, y))
	return out

/datum/unit_test/procgen_overworld/proc/is_land_biome_t(biome)
	return biome == TEST_OW_PLAINS || biome == TEST_OW_DESERT || biome == TEST_OW_SWAMP || biome == TEST_OW_MOUNTAINS

/datum/unit_test/procgen_overworld/proc/stamp_footprint()
	fill_turf_type(footprint_x1, footprint_y1, footprint_x2, footprint_y2, base_z - 1, /turf/closed/mineral/rogue/bedrock)
	fill_turf_type(footprint_x1, footprint_y1, footprint_x2, footprint_y2, base_z, /turf/closed/mineral/rogue)
	for(var/z = base_z + 1, z <= base_z + run_length - 1, z++)
		fill_turf_type(footprint_x1, footprint_y1, footprint_x2, footprint_y2, z, /turf/open/transparent/openspace)

/datum/unit_test/procgen_overworld/proc/configure_test_thresholds(area/procedural_generation/overworld/subject)
	subject.island_noise_threshold = test_island_noise_threshold
	subject.desert_temp_min = test_desert_temp_min
	subject.swamp_temp_min = test_swamp_temp_min

/datum/unit_test/procgen_overworld/proc/assert_coasts_both_sides(area/procedural_generation/overworld/subject)
	var/mid_y = round((subject.low_y + subject.high_y) / 2)
	var/west_biome = subject.biome_map["[subject.low_x]-[mid_y]"]
	var/east_biome = subject.biome_map["[subject.high_x]-[mid_y]"]
	note("coasts: west edge biome [west_biome], east edge biome [east_biome]")
	TEST_ASSERT(west_biome == TEST_OW_OCEAN || west_biome == TEST_OW_COAST, "west map edge is not ocean/coast")
	TEST_ASSERT(east_biome == TEST_OW_OCEAN || east_biome == TEST_OW_COAST, "east map edge is not ocean/coast")

/datum/unit_test/procgen_overworld/proc/assert_shore_asymmetry(area/procedural_generation/overworld/subject)
	var/near_total = 0
	var/far_total = 0
	var/rows = length(subject.near_shore_x)
	for(var/row = 1, row <= rows, row++)
		if(subject.west_is_near_coast)
			near_total += subject.near_shore_x[row] - subject.low_x
			far_total += subject.high_x - subject.far_shore_x[row]
		else
			near_total += subject.high_x - subject.near_shore_x[row]
			far_total += subject.far_shore_x[row] - subject.low_x
	var/near_width = near_total / rows
	var/far_width = far_total / rows
	note("shore widths: near [near_width], far [far_width]")
	TEST_ASSERT(far_width > near_width + 2, "far shore strip is not meaningfully wider than the near shore strip")

/datum/unit_test/procgen_overworld/proc/island_found_in(area/procedural_generation/overworld/subject)
	var/list/far_land = list()
	for(var/y = subject.low_y, y <= subject.high_y, y++)
		var/row = y - subject.low_y + 1
		var/far_x = subject.far_shore_x[row]
		for(var/x = subject.low_x, x <= subject.high_x, x++)
			var/in_far = subject.west_is_near_coast ? (x >= far_x) : (x <= far_x)
			if(!in_far)
				continue
			var/key = "[x]-[y]"
			var/biome = subject.biome_map[key]
			if(biome && biome != TEST_OW_OCEAN)
				far_land[key] = TRUE

	var/list/visited = list()
	var/found_island = FALSE
	for(var/key in far_land)
		if(visited[key])
			continue
		var/list/frontier = list(key)
		visited[key] = TRUE
		var/touches_shoreline = FALSE
		var/cursor = 1
		while(cursor <= length(frontier))
			var/ckey = frontier[cursor++]
			var/list/coords = splittext(ckey, "-")
			var/cx = text2num(coords[1])
			var/cy = text2num(coords[2])
			var/crow = cy - subject.low_y + 1
			if(round(subject.far_shore_x[crow]) == cx)
				touches_shoreline = TRUE
			for(var/list/offset as anything in list(list(1, 0), list(-1, 0), list(0, 1), list(0, -1)))
				var/nkey = "[cx + offset[1]]-[cy + offset[2]]"
				if(!far_land[nkey] || visited[nkey])
					continue
				visited[nkey] = TRUE
				frontier += nkey
		if(!touches_shoreline)
			found_island = TRUE

	note("islands: [length(far_land)] far-strip land cells scanned, found=[found_island]")
	return found_island

/datum/unit_test/procgen_overworld/proc/run_island_retry_check()
	var/list/coords = rect_coords(footprint_x1, footprint_y1, footprint_x2, footprint_y2)
	var/found = FALSE
	for(var/attempt in 1 to 6)
		stamp_footprint()
		var/area/procedural_generation/overworld/test/subject = new
		subject.plan_only = TRUE
		configure_test_thresholds(subject)
		var/list/claimed = list()
		for(var/z = base_z, z <= base_z + run_length - 1, z++)
			claimed += claim_turfs(subject, coords, z)

		subject.setup_procgen()
		if(island_found_in(subject))
			found = TRUE

		release_turfs(claimed)
		if(found)
			break
	TEST_ASSERT(found, "no island (far-strip land disconnected from the far shoreline) was found across 6 fresh seeds")

/datum/unit_test/procgen_overworld/proc/assert_all_biomes_present(area/procedural_generation/overworld/subject)
	var/seen_mountains = FALSE
	var/seen_desert = FALSE
	var/seen_swamp = FALSE
	var/seen_plains = FALSE
	var/seen_coast = FALSE
	for(var/key in subject.biome_map)
		switch(subject.biome_map[key])
			if(TEST_OW_MOUNTAINS)
				seen_mountains = TRUE
			if(TEST_OW_DESERT)
				seen_desert = TRUE
			if(TEST_OW_SWAMP)
				seen_swamp = TRUE
			if(TEST_OW_PLAINS)
				seen_plains = TRUE
			if(TEST_OW_COAST)
				seen_coast = TRUE
	note("biomes present: mountains [seen_mountains] desert [seen_desert] swamp [seen_swamp] plains [seen_plains] coast [seen_coast]")
	TEST_ASSERT(seen_mountains, "no mountain cells generated")
	TEST_ASSERT(seen_desert, "no desert cells generated")
	TEST_ASSERT(seen_swamp, "no swamp cells generated")
	TEST_ASSERT(seen_plains, "no plains cells generated")
	TEST_ASSERT(seen_coast, "no coast cells generated")

/datum/unit_test/procgen_overworld/proc/assert_mountains_north(area/procedural_generation/overworld/subject)
	var/y_total = 0
	var/count = 0
	for(var/key in subject.biome_map)
		if(subject.biome_map[key] != TEST_OW_MOUNTAINS)
			continue
		var/list/coords = splittext(key, "-")
		y_total += text2num(coords[2])
		count++
	TEST_ASSERT(count > 0, "no mountain cells to compute a centroid from")
	var/centroid_y = y_total / count
	var/midline = (subject.low_y + subject.high_y) / 2
	note("mountains: centroid y [centroid_y], midline [midline]")
	TEST_ASSERT(centroid_y > midline, "mountain centroid is not north of the footprint midline")

/datum/unit_test/procgen_overworld/proc/assert_temperature_direction(area/procedural_generation/overworld/subject)
	var/mid_x = round((subject.low_x + subject.high_x) / 2)
	var/t_south = subject.biome_temperature(mid_x, subject.low_y)
	var/t_north = subject.biome_temperature(mid_x, subject.high_y)
	note("temperature: south [t_south], north [t_north]")
	TEST_ASSERT(t_south > t_north, "south is not warmer than north")

/datum/unit_test/procgen_overworld/proc/assert_heights_bounded(area/procedural_generation/overworld/subject)
	var/violations = 0
	var/checked = 0
	for(var/key in subject.biome_map)
		var/biome = subject.biome_map[key]
		if(!is_land_biome_t(biome))
			continue
		var/list/coords = splittext(key, "-")
		var/x = text2num(coords[1])
		var/y = text2num(coords[2])
		for(var/list/offset as anything in list(list(1, 0), list(0, 1)))
			var/nx = x + offset[1]
			var/ny = y + offset[2]
			var/nkey = "[nx]-[ny]"
			var/nbiome = subject.biome_map[nkey]
			if(!is_land_biome_t(nbiome))
				continue
			if(biome == TEST_OW_MOUNTAINS || nbiome == TEST_OW_MOUNTAINS)
				continue
			var/h1 = subject.height_map[key]
			var/h2 = subject.height_map[nkey]
			if(isnull(h1) || isnull(h2))
				continue
			checked++
			if(abs(h1 - h2) > 1)
				violations++
	note("heights: [checked] land-land pairs checked (excluding mountain-adjacent), [violations] exceed |dh|=1")
	TEST_ASSERT_EQUAL(violations, 0, "some non-mountain land-land neighbor pairs have |dh| > 1")

/datum/unit_test/procgen_overworld/proc/assert_river_mouths(area/procedural_generation/overworld/subject)
	if(!length(subject.river_paths))
		note("rivers: no rivers were generated this run, skipping river-plan assertions")
		return
	for(var/list/path as anything in subject.river_paths)
		if(!length(path))
			continue
		var/final_key = path[length(path)]
		var/h = subject.height_map[final_key]
		TEST_ASSERT_EQUAL(h, 0, "river final tile [final_key] does not have height 0")
		var/list/coords = splittext(final_key, "-")
		var/x = text2num(coords[1])
		var/y = text2num(coords[2])
		var/adjacent_water = (subject.biome_map[final_key] == TEST_OW_OCEAN || subject.biome_map[final_key] == TEST_OW_COAST)
		if(!adjacent_water)
			for(var/dir in GLOB.cardinals)
				var/list/offset = subject.offset_for_dir(x, y, dir)
				var/nbiome = subject.biome_map["[offset[1]]-[offset[2]]"]
				if(nbiome == TEST_OW_OCEAN || nbiome == TEST_OW_COAST)
					adjacent_water = TRUE
					break
		TEST_ASSERT(adjacent_water, "river final tile [final_key] is not itself or adjacent to ocean/coast")

/datum/unit_test/procgen_overworld/proc/assert_river_beds_in_world(area/procedural_generation/overworld/subject)
	if(!length(subject.river_paths))
		return
	var/checked = 0
	var/river_index = 0
	for(var/list/path as anything in subject.river_paths)
		river_index++
		var/path_index = 0
		for(var/key in path)
			path_index++
			var/list/coords = splittext(key, "-")
			var/x = text2num(coords[1])
			var/y = text2num(coords[2])
			var/h = subject.height_map[key]
			if(isnull(h))
				h = 0
			var/turf/surface = locate(x, y, subject.low_z + h)
			if(!surface)
				continue
			checked++
			if(!istype(surface, /turf/open/transparent/openspace))
				note("river-debug: river [river_index] tile [path_index]/[length(path)] key [key] h=[h] biome=[subject.biome_map[key]] surface_type=[surface.type] flow=[subject.river_flow_map[key]]")
			TEST_ASSERT(istype(surface, /turf/open/transparent/openspace), "river surface at [key] is not openspace")
			var/turf/below = GetBelow(surface)
			TEST_ASSERT(istype(below, /turf/open/floor/rogue/riverbot), "river surface at [key] has no riverbot bed below")
			TEST_ASSERT(below.cell && below.cell.flow_dir, "riverbot below [key] has no flow_dir set")
	note("rivers: [checked] river surface tiles verified in-world")

/datum/unit_test/procgen_overworld/proc/assert_wall_heights(area/procedural_generation/overworld/subject)
	var/list/candidates = list()
	for(var/key in subject.biome_map)
		var/biome = subject.biome_map[key]
		if(biome == TEST_OW_OCEAN || biome == TEST_OW_COAST || biome == TEST_OW_RIVER)
			continue
		var/h = subject.height_map[key]
		if(h && h >= 1)
			candidates += key
	if(!length(candidates))
		note("wall heights: no elevated (h>=1) columns available to sample; run [run_length] may be too shallow for this seed")
		return

	var/samples = min(5, length(candidates))
	var/list/picked = list()
	for(var/i in 1 to samples)
		var/key = pick(candidates)
		candidates -= key
		picked += key

	for(var/key in picked)
		var/h = subject.height_map[key]
		var/list/coords = splittext(key, "-")
		var/x = text2num(coords[1])
		var/y = text2num(coords[2])
		var/turf/below_surface = locate(x, y, subject.low_z + h - 1)
		var/turf/surface = locate(x, y, subject.low_z + h)
		TEST_ASSERT(iswall(below_surface), "column [key] (h=[h]) turf below surface is not a wall")
		TEST_ASSERT(!istype(surface, /turf/open/transparent/openspace) || subject.biome_map[key] == TEST_OW_RIVER, "column [key] (h=[h]) surface turf is openspace but is not a river")
		if(subject.low_z + h + 1 <= subject.low_z + run_length - 1)
			var/turf/above = locate(x, y, subject.low_z + h + 1)
			TEST_ASSERT(istype(above, /turf/open/transparent/openspace), "column [key] (h=[h]) turf above surface is not openspace")
	note("wall heights: verified [length(picked)] elevated columns")

/datum/unit_test/procgen_overworld/proc/run_full_pipeline()
	var/list/coords = rect_coords(footprint_x1, footprint_y1, footprint_x2, footprint_y2)
	stamp_footprint()

	var/area/procedural_generation/overworld/test/subject = new
	subject.plan_only = TRUE
	configure_test_thresholds(subject)
	var/list/claimed = list()
	for(var/z = base_z, z <= base_z + run_length - 1, z++)
		claimed += claim_turfs(subject, coords, z)

	subject.setup_procgen()
	note("seed [subject.round_seed] west_is_near_coast [subject.west_is_near_coast] relief_levels [subject.relief_levels]")

	assert_coasts_both_sides(subject)
	assert_shore_asymmetry(subject)
	island_found_in(subject)
	assert_all_biomes_present(subject)
	assert_mountains_north(subject)
	assert_temperature_direction(subject)
	assert_heights_bounded(subject)
	assert_river_mouths(subject)

	snapshot_seed = subject.round_seed
	snapshot_west = subject.west_is_near_coast
	biome_snapshot = subject.biome_map.Copy()
	height_snapshot = subject.height_map.Copy()

	subject.apply_world_plan()

	assert_river_beds_in_world(subject)
	assert_wall_heights(subject)

	for(var/turf/T as anything in subject.changed_turfs)
		if(T && T.cell)
			SSliquid.clear_cell_fluid(T)

	release_turfs(claimed)
	SSprocgen.fluid_cells.Cut()
	SSprocgen.mimic_turfs.Cut()

/datum/unit_test/procgen_overworld/proc/run_determinism()
	if(isnull(snapshot_seed))
		note("determinism: skipped, the full pipeline run produced no seed to replay")
		return

	var/list/coords = rect_coords(footprint_x1, footprint_y1, footprint_x2, footprint_y2)
	stamp_footprint()

	var/area/procedural_generation/overworld/test/subject = new
	subject.plan_only = TRUE
	configure_test_thresholds(subject)
	subject.round_seed = snapshot_seed
	subject.west_is_near_coast = snapshot_west
	var/list/claimed = list()
	for(var/z = base_z, z <= base_z + run_length - 1, z++)
		claimed += claim_turfs(subject, coords, z)

	subject.setup_procgen()

	var/mismatches = 0
	var/checked = 0
	var/logged = 0
	for(var/key in biome_snapshot)
		checked++
		var/biome_diff = (subject.biome_map[key] != biome_snapshot[key])
		var/height_diff = (subject.height_map[key] != height_snapshot[key])
		if(biome_diff)
			mismatches++
		if(height_diff)
			mismatches++
		if((biome_diff || height_diff) && logged < 15)
			logged++
			note("determinism-debug: key [key] biome [biome_snapshot[key]]->[subject.biome_map[key]] height [height_snapshot[key]]->[subject.height_map[key]]")
	note("determinism: [checked] keys compared against the forced-seed replay, [mismatches] mismatches")
	TEST_ASSERT_EQUAL(mismatches, 0, "a forced-seed second run produced a different biome/height map than the first")

	release_turfs(claimed)

/datum/unit_test/procgen_overworld/proc/run_coast_orientation_random()
	var/seen_true = FALSE
	var/seen_false = FALSE
	for(var/i in 1 to 20)
		var/area/procedural_generation/overworld/test/subject = new
		subject.pick_coast_orientation()
		if(subject.west_is_near_coast)
			seen_true = TRUE
		else
			seen_false = TRUE
	note("coast orientation: TRUE seen [seen_true], FALSE seen [seen_false] across 20 rolls")
	TEST_ASSERT(seen_true, "pick_coast_orientation() never rolled TRUE across 20 fresh instances")
	TEST_ASSERT(seen_false, "pick_coast_orientation() never rolled FALSE across 20 fresh instances")

/datum/unit_test/procgen_overworld/Run()
	run_length = 3
	base_z = find_test_z_run(3)
	if(!base_z)
		run_length = 2
		base_z = find_test_z_run(2)
	if(!base_z)
		TEST_FAIL("No usable run of 2 or 3 consecutive z-linked levels with a level below for bedrock exists on this map")
		return

	note("running on z [base_z]..[base_z + run_length - 1] (run [run_length]) of [length(SSmapping.multiz_levels)] linked levels")

	run_full_pipeline()
	run_island_retry_check()
	run_determinism()
	run_coast_orientation_random()

	fdel("data/procgen_overworld_test.txt")
	var/logfile = file("data/procgen_overworld_test.txt")
	for(var/line in report)
		logfile << line

#undef TEST_OW_OCEAN
#undef TEST_OW_COAST
#undef TEST_OW_PLAINS
#undef TEST_OW_DESERT
#undef TEST_OW_SWAMP
#undef TEST_OW_MOUNTAINS
#undef TEST_OW_RIVER
