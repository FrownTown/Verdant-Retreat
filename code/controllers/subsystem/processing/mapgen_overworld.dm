#define OW_OCEAN 20
#define OW_COAST 21
#define OW_PLAINS 22
#define OW_DESERT 23
#define OW_SWAMP 24
#define OW_MOUNTAINS 25
#define OW_RIVER 26

/area/procedural_generation/overworld
	name = "Procedurally Generated Overworld"
	outdoors = TRUE
	multiz_generation = TRUE

	var/round_seed
	var/west_is_near_coast
	var/relief_levels = 0
	var/plan_only = FALSE

	var/near_shore_min_frac = 0.02
	var/near_shore_max_frac = 0.06
	var/far_shore_min_frac = 0.16
	var/far_shore_max_frac = 0.35
	var/coast_band_width = 3
	var/island_noise_threshold = 62
	var/mountain_score_threshold = 62
	var/desert_temp_min = 65
	var/desert_moisture_max = 30
	var/swamp_temp_min = 45
	var/swamp_moisture_min = 65
	var/cold_accent_temp = 20
	var/min_rivers = 1
	var/max_rivers = 2
	var/tree_density = 10
	var/murk_pool_chance = 2

	var/ow_temp_key
	var/ow_moist_key
	var/ow_elev_key
	var/ow_ridge_key
	var/ow_island_key
	var/ow_shore_key

	var/list/biome_map = list()
	var/list/height_map = list()
	var/list/near_shore_x = list()
	var/list/far_shore_x = list()
	var/list/river_paths = list()
	var/list/river_flow_map = list()
	var/list/changed_turfs = list()

/area/procedural_generation/overworld/test
	name = "test overworld"

/area/procedural_generation/overworld/setup_procgen()
	..()
	relief_levels = high_z - low_z
	build_world_plan()
	if(plan_only)
		return
	apply_world_plan()
	log_seed_line()
	cut_working_lists()

/area/procedural_generation/overworld/proc/cut_working_lists()
	biome_map = list()
	height_map = list()
	near_shore_x = list()
	far_shore_x = list()
	river_paths = list()
	river_flow_map = list()
	changed_turfs = list()

/area/procedural_generation/overworld/proc/build_world_plan()
	roll_round_seed()
	pick_coast_orientation()
	generate_shorelines()
	generate_biome_map()
	generate_rivers_ow()
	generate_height_map()
	relax_height_map()
	flatten_river_heights()

/area/procedural_generation/overworld/proc/log_seed_line()
	var/mountain_x_total = 0
	var/mountain_y_total = 0
	var/mountain_count = 0
	for(var/key in biome_map)
		if(biome_map[key] != OW_MOUNTAINS)
			continue
		var/list/coords = splittext(key, "-")
		mountain_x_total += text2num(coords[1])
		mountain_y_total += text2num(coords[2])
		mountain_count++
	var/centroid_x = mountain_count ? round(mountain_x_total / mountain_count) : 0
	var/centroid_y = mountain_count ? round(mountain_y_total / mountain_count) : 0
	var/near_side = west_is_near_coast ? "west" : "east"
	var/line = "[type] seed [round_seed] near-coast [near_side] mountain-centroid [centroid_x],[centroid_y] rivers [length(river_paths)]"
	log_mapping(line)
	SSprocgen.overworld_seed_log += line

/area/procedural_generation/overworld/proc/roll_round_seed()
	if(isnull(round_seed))
		round_seed = rand(1, 999999)
	ow_temp_key = "ow_temp_[round_seed]"
	ow_moist_key = "ow_moist_[round_seed]"
	ow_elev_key = "ow_elev_[round_seed]"
	ow_ridge_key = "ow_ridge_[round_seed]"
	ow_island_key = "ow_island_[round_seed]"
	ow_shore_key = "ow_shore_[round_seed]"
	SSnoisemap.make_noisemap(ow_temp_key, NOISE_SIMPLEX)
	SSnoisemap.make_noisemap(ow_moist_key, NOISE_SIMPLEX)
	SSnoisemap.make_noisemap(ow_elev_key, NOISE_BILLOW)
	SSnoisemap.make_noisemap(ow_ridge_key, NOISE_RIDGEDMULTI)
	SSnoisemap.make_noisemap(ow_island_key, NOISE_WORLEY)
	SSnoisemap.make_noisemap(ow_shore_key, NOISE_SIMPLEX)
	SSnoisemap.set_seed(ow_temp_key, round_seed)
	SSnoisemap.set_seed(ow_moist_key, round_seed)
	SSnoisemap.set_seed(ow_elev_key, round_seed)
	SSnoisemap.set_seed(ow_ridge_key, round_seed)
	SSnoisemap.set_seed(ow_island_key, round_seed)
	SSnoisemap.set_seed(ow_shore_key, round_seed)
	rand_seed(round_seed)

/area/procedural_generation/overworld/proc/pick_coast_orientation()
	var/roll = prob(50)
	if(isnull(west_is_near_coast))
		west_is_near_coast = roll

/area/procedural_generation/overworld/proc/generate_shorelines()
	near_shore_x = list()
	far_shore_x = list()
	var/width = max(1, high_x - low_x)
	var/near_inset = round(width * (near_shore_min_frac + rand() * (near_shore_max_frac - near_shore_min_frac)))
	var/far_inset = round(width * (far_shore_min_frac + rand() * (far_shore_max_frac - far_shore_min_frac)))
	for(var/y = low_y, y <= high_y, y++)
		var/jitter_near = (SSnoisemap.get_value(ow_shore_key, low_x, y, 0, 0.02) - 50) * 0.3
		var/jitter_far = (SSnoisemap.get_value(ow_shore_key, low_x, y, 5000, 0.015) - 50) * 0.4
		var/near_x
		var/far_x
		if(west_is_near_coast)
			near_x = low_x + near_inset + jitter_near
			far_x = high_x - far_inset + jitter_far
		else
			near_x = high_x - near_inset - jitter_near
			far_x = low_x + far_inset - jitter_far
		near_shore_x += clamp(round(near_x), low_x, high_x)
		far_shore_x += clamp(round(far_x), low_x, high_x)

/area/procedural_generation/overworld/proc/is_near_sea(x, row)
	if(west_is_near_coast)
		return x <= near_shore_x[row]
	return x >= near_shore_x[row]

/area/procedural_generation/overworld/proc/is_far_strip(x, row)
	if(west_is_near_coast)
		return x >= far_shore_x[row]
	return x <= far_shore_x[row]

/area/procedural_generation/overworld/proc/is_far_edge_margin(x)
	if(west_is_near_coast)
		return x > high_x - coast_band_width
	return x < low_x + coast_band_width

/area/procedural_generation/overworld/proc/biome_temperature(x, y)
	var/gradient = 100 * (1 - (y - low_y) / max(1, high_y - low_y))
	var/noise = (SSnoisemap.get_value(ow_temp_key, x, y, 0, 0.01) - 50) * 0.4
	return clamp(gradient + noise, 0, 100)

/area/procedural_generation/overworld/proc/generate_biome_map()
	var/list/sea_map = list()
	var/row_tick = 0
	for(var/y = low_y, y <= high_y, y++)
		var/row = y - low_y + 1
		for(var/x = low_x, x <= high_x, x++)
			if(!in_area(x, y))
				continue
			var/key = "[x]-[y]"
			var/is_sea = FALSE
			if(is_near_sea(x, row))
				is_sea = TRUE
			else if(is_far_strip(x, row))
				if(is_far_edge_margin(x))
					is_sea = TRUE
				else if(SSnoisemap.get_value(ow_island_key, x, y, 0, 0.05) < island_noise_threshold)
					is_sea = TRUE
			sea_map[key] = is_sea
		row_tick++
		if(row_tick % 8 == 0)
			CHECK_TICK

	row_tick = 0
	for(var/y = low_y, y <= high_y, y++)
		var/row = y - low_y + 1
		for(var/x = low_x, x <= high_x, x++)
			if(!in_area(x, y))
				continue
			var/key = "[x]-[y]"
			if(sea_map[key])
				biome_map[key] = OW_OCEAN
				continue

			var/is_coast = FALSE
			if(is_far_strip(x, row))
				for(var/dir in GLOB.cardinals)
					var/list/offset = offset_for_dir(x, y, dir)
					if(sea_map["[offset[1]]-[offset[2]]"])
						is_coast = TRUE
						break
			else
				var/dist_near = abs(x - near_shore_x[row])
				var/dist_far = abs(x - far_shore_x[row])
				if(min(dist_near, dist_far) <= coast_band_width)
					is_coast = TRUE

			if(is_coast)
				biome_map[key] = OW_COAST
				continue

			var/t = biome_temperature(x, y)
			var/m = SSnoisemap.get_value(ow_moist_key, x, y, 0, 0.015)
			var/e = SSnoisemap.get_value(ow_elev_key, x, y, 0, 0.006)
			var/mountain_score = e * 0.6 + (100 - t) * 0.4

			if(mountain_score >= mountain_score_threshold)
				biome_map[key] = OW_MOUNTAINS
			else if(t >= desert_temp_min && m <= desert_moisture_max)
				biome_map[key] = OW_DESERT
			else if(t >= swamp_temp_min && m >= swamp_moisture_min)
				biome_map[key] = OW_SWAMP
			else
				biome_map[key] = OW_PLAINS
		row_tick++
		if(row_tick % 8 == 0)
			CHECK_TICK

/area/procedural_generation/overworld/proc/river_touches_water(x, y)
	for(var/dir in GLOB.cardinals)
		var/list/offset = offset_for_dir(x, y, dir)
		var/nbiome = biome_map["[offset[1]]-[offset[2]]"]
		if(nbiome == OW_OCEAN || nbiome == OW_COAST)
			return TRUE
	return FALSE

/area/procedural_generation/overworld/proc/generate_rivers_ow()
	rand_seed(round_seed + 1)
	var/list/mountain_cells = list()
	for(var/key in biome_map)
		if(biome_map[key] == OW_MOUNTAINS)
			mountain_cells += key
	if(!length(mountain_cells))
		log_mapping("[type] found no mountain cells to source a river from; skipping river generation.")
		return

	var/river_count = rand(min_rivers, max_rivers)
	for(var/i in 1 to river_count)
		var/source_key = pick(mountain_cells)
		var/list/source_coords = splittext(source_key, "-")
		var/source_x = text2num(source_coords[1])
		var/source_y = text2num(source_coords[2])
		var/list/mouth = pick_river_mouth(source_x, source_y)
		if(!mouth)
			continue
		var/list/path = create_river_ow(source_x, source_y, mouth[1], mouth[2])
		if(length(path))
			river_paths += list(path)

	if(length(river_paths))
		resolve_river_flow_ow()

/area/procedural_generation/overworld/proc/pick_river_mouth(source_x, source_y)
	var/best_dist
	var/best_x
	var/best_y
	for(var/row = 1, row <= length(near_shore_x), row++)
		var/y = low_y + row - 1
		var/nx = near_shore_x[row]
		var/nd = (nx - source_x) ** 2 + (y - source_y) ** 2
		if(isnull(best_dist) || nd < best_dist)
			best_dist = nd
			best_x = nx
			best_y = y
		var/fx = far_shore_x[row]
		var/fd = (fx - source_x) ** 2 + (y - source_y) ** 2
		if(fd < best_dist)
			best_dist = fd
			best_x = fx
			best_y = y
	if(isnull(best_x))
		return null
	return list(best_x, best_y)

/area/procedural_generation/overworld/proc/create_river_ow(start_x, start_y, end_x, end_y)
	var/list/path = list()
	var/current_x = start_x
	var/current_y = start_y
	var/last_direction = get_dir(locate(start_x, start_y, low_z), locate(end_x, end_y, low_z))
	var/max_steps = (high_x - low_x) + (high_y - low_y)
	for(var/step in 1 to max_steps)
		if(!in_area(current_x, current_y))
			break
		var/key = "[current_x]-[current_y]"
		var/existing = biome_map[key]
		if(existing == OW_OCEAN || existing == OW_COAST)
			break
		biome_map[key] = OW_RIVER
		path += key
		if(river_touches_water(current_x, current_y))
			break
		if(current_x == end_x && current_y == end_y)
			break

		var/new_direction
		if(prob(80))
			new_direction = last_direction
		else
			new_direction = prob(60) ? turn(last_direction, 45) : turn(last_direction, -45)

		var/distance_to_target = abs(end_x - current_x) + abs(end_y - current_y)
		if(distance_to_target > (max_steps / 4))
			new_direction = get_dir(locate(current_x, current_y, low_z), locate(end_x, end_y, low_z))

		var/list/moved = river_move(current_x, current_y, new_direction)
		current_x = moved[1]
		current_y = moved[2]

		last_direction = new_direction

	if(length(path) && !river_touches_water(current_x, current_y))
		extend_river_to_water(current_x, current_y, path)
	return path

/area/procedural_generation/overworld/proc/extend_river_to_water(current_x, current_y, list/path)
	var/start_key = "[current_x]-[current_y]"
	var/list/visited = list()
	visited[start_key] = TRUE
	var/list/frontier = list(list(current_x, current_y))
	var/list/came_from = list()
	var/cursor = 1
	var/found_key
	while(cursor <= length(frontier))
		var/list/pos = frontier[cursor++]
		var/px = pos[1]
		var/py = pos[2]
		var/pkey = "[px]-[py]"
		if(pkey != start_key && river_touches_water(px, py))
			found_key = pkey
			break
		for(var/dir in GLOB.cardinals)
			var/list/offset = offset_for_dir(px, py, dir)
			var/nx = offset[1]
			var/ny = offset[2]
			var/nkey = "[nx]-[ny]"
			if(visited[nkey] || !in_area(nx, ny))
				continue
			var/nbiome = biome_map[nkey]
			if(nbiome == OW_OCEAN || nbiome == OW_COAST)
				continue
			visited[nkey] = TRUE
			came_from[nkey] = pkey
			frontier += list(list(nx, ny))
	if(!found_key)
		return

	var/list/extension = list()
	var/walk_key = found_key
	while(walk_key && walk_key != start_key)
		extension += walk_key
		walk_key = came_from[walk_key]
	for(var/i = length(extension), i >= 1, i--)
		var/key = extension[i]
		biome_map[key] = OW_RIVER
		path += key

/area/procedural_generation/overworld/proc/river_move(current_x, current_y, dir)
	switch(dir)
		if(NORTH)
			current_y = min(current_y + 1, high_y)
		if(SOUTH)
			current_y = max(current_y - 1, low_y)
		if(EAST)
			current_x = min(current_x + 1, high_x)
		if(WEST)
			current_x = max(current_x - 1, low_x)
		if(NORTHEAST)
			current_x = min(current_x + 1, high_x)
			current_y = min(current_y + 1, high_y)
		if(NORTHWEST)
			current_x = max(current_x - 1, low_x)
			current_y = min(current_y + 1, high_y)
		if(SOUTHEAST)
			current_x = min(current_x + 1, high_x)
			current_y = max(current_y - 1, low_y)
		if(SOUTHWEST)
			current_x = max(current_x - 1, low_x)
			current_y = max(current_y - 1, low_y)
	return list(current_x, current_y)

/area/procedural_generation/overworld/proc/resolve_river_flow_ow()
	for(var/list/path as anything in river_paths)
		for(var/i = 1, i <= length(path), i++)
			var/key = path[i]
			var/dir
			if(i < length(path))
				var/list/coords = splittext(key, "-")
				var/x = text2num(coords[1])
				var/y = text2num(coords[2])
				var/list/next_coords = splittext(path[i + 1], "-")
				var/nx = text2num(next_coords[1])
				var/ny = text2num(next_coords[2])
				dir = get_dir(locate(x, y, low_z), locate(nx, ny, low_z))
			else if(i > 1)
				dir = river_flow_map[path[i - 1]] || SOUTH
			else
				dir = SOUTH
			river_flow_map[key] = dir

/area/procedural_generation/overworld/proc/is_land_biome(biome)
	return biome == OW_PLAINS || biome == OW_DESERT || biome == OW_SWAMP || biome == OW_MOUNTAINS

/area/procedural_generation/overworld/proc/amplitude_for_biome(biome)
	switch(biome)
		if(OW_MOUNTAINS)
			return 1.0
		if(OW_DESERT)
			return 0.25
		if(OW_PLAINS)
			return 0.15
		if(OW_SWAMP)
			return 0.05
		if(OW_RIVER)
			return 1.0
	return 0

/area/procedural_generation/overworld/proc/generate_height_map()
	var/row_tick = 0
	for(var/y = low_y, y <= high_y, y++)
		for(var/x = low_x, x <= high_x, x++)
			if(!in_area(x, y))
				continue
			var/key = "[x]-[y]"
			var/biome = biome_map[key]
			if(biome == OW_OCEAN || biome == OW_COAST)
				height_map[key] = 0
				continue
			var/relief_raw = SSnoisemap.get_value(ow_ridge_key, x, y, 0, 0.01) * 0.6 + SSnoisemap.get_value(ow_elev_key, x, y, 3000, 0.02) * 0.4
			var/amplitude = amplitude_for_biome(biome)
			height_map[key] = round((relief_raw / 100) * amplitude * relief_levels, 1)
		row_tick++
		if(row_tick % 8 == 0)
			CHECK_TICK

/area/procedural_generation/overworld/proc/relax_height_map()
	var/static/list/offsets = list(list(1, 0), list(-1, 0), list(0, 1), list(0, -1))
	for(var/iteration in 1 to 3)
		var/changed = FALSE
		for(var/y = low_y, y <= high_y, y++)
			for(var/x = low_x, x <= high_x, x++)
				if(!in_area(x, y))
					continue
				var/key = "[x]-[y]"
				var/biome = biome_map[key]
				if(!is_land_biome(biome))
					continue
				for(var/list/offset as anything in offsets)
					var/nx = x + offset[1]
					var/ny = y + offset[2]
					if(!in_area(nx, ny))
						continue
					var/nkey = "[nx]-[ny]"
					var/nbiome = biome_map[nkey]
					if(!is_land_biome(nbiome))
						continue
					if(biome == OW_MOUNTAINS || nbiome == OW_MOUNTAINS)
						continue
					var/h1 = height_map[key]
					var/h2 = height_map[nkey]
					if(abs(h1 - h2) > 1)
						changed = TRUE
						if(h1 > h2)
							height_map[key] = h2 + 1
						else
							height_map[nkey] = h1 + 1
			CHECK_TICK
		if(!changed)
			break

/area/procedural_generation/overworld/proc/flatten_river_heights()
	for(var/list/path as anything in river_paths)
		var/running_min
		for(var/i = 1, i <= length(path), i++)
			var/key = path[i]
			var/h = height_map[key]
			if(isnull(h))
				h = 0
			if(!isnull(running_min) && h > running_min)
				h = running_min
			running_min = h
			height_map[key] = h
		if(length(path))
			height_map[path[length(path)]] = 0

/area/procedural_generation/overworld/proc/apply_world_plan()
	var/row_tick = 0
	for(var/y = low_y, y <= high_y, y++)
		for(var/x = low_x, x <= high_x, x++)
			var/key = "[x]-[y]"
			var/biome = biome_map[key]
			if(isnull(biome))
				continue
			apply_column(x, y, key, biome)
		row_tick++
		if(row_tick % 8 == 0)
			CHECK_TICK
	finalize_generation()

/area/procedural_generation/overworld/proc/apply_column(x, y, key, biome)
	if(biome == OW_OCEAN)
		apply_ocean_column(x, y, key)
		return
	var/h = height_map[key]
	if(isnull(h))
		h = 0
	if(h < 0)
		h = 0
	if(h > relief_levels)
		h = relief_levels
	if(low_z + h > high_z)
		h = high_z - low_z
	apply_land_column(x, y, key, biome, h)

/area/procedural_generation/overworld/proc/apply_ocean_column(x, y, key)
	var/zkey = "[low_z]"
	if(!z_turf_maps[zkey] || !z_turf_maps[zkey][key])
		return
	var/turf/T = locate(x, y, low_z)
	if(!T)
		return
	var/dist = distance_to_land(x, y)
	var/target_type
	if(dist <= 2)
		target_type = /turf/open/water/cleanshallow
	else if(dist <= 8)
		target_type = /turf/open/water/ocean
	else
		target_type = /turf/open/water/ocean/deep
	var/turf/new_turf = T.ChangeTurf(target_type, null, CHANGETURF_IGNORE_AIR | CHANGETURF_DEFER_CHANGE)
	if(!new_turf)
		return
	contain_water(new_turf)
	changed_turfs += new_turf

/area/procedural_generation/overworld/proc/distance_to_land(x, y)
	var/row = y - low_y + 1
	if(row < 1 || row > length(near_shore_x))
		return 99
	var/d = min(abs(x - near_shore_x[row]), abs(x - far_shore_x[row]))
	if(d <= 8)
		return d
	for(var/radius = 1, radius <= 4, radius++)
		for(var/dx = -radius, dx <= radius, dx++)
			for(var/dy = -radius, dy <= radius, dy++)
				if(abs(dx) != radius && abs(dy) != radius)
					continue
				var/nbiome = biome_map["[x + dx]-[y + dy]"]
				if(nbiome && nbiome != OW_OCEAN)
					return min(d, max(abs(dx), abs(dy)))
	return d

/area/procedural_generation/overworld/proc/is_exposed_face(x, y, level_being_filled)
	for(var/dir in GLOB.cardinals)
		var/list/offset = offset_for_dir(x, y, dir)
		var/nh = height_map["[offset[1]]-[offset[2]]"]
		if(isnull(nh))
			nh = 0
		if(nh < level_being_filled)
			return TRUE
	return FALSE

/area/procedural_generation/overworld/proc/apply_land_column(x, y, key, biome, h)
	for(var/lvl = 0, lvl < h, lvl++)
		var/z = low_z + lvl
		var/zkey = "[z]"
		if(!z_turf_maps[zkey] || !z_turf_maps[zkey][key])
			continue
		var/turf/T = locate(x, y, z)
		if(!T)
			continue
		var/wall_type = is_exposed_face(x, y, lvl + 1) ? /turf/closed/mineral/random/rogue : /turf/closed/mineral/rogue
		var/turf/new_turf = T.ChangeTurf(wall_type, null, CHANGETURF_IGNORE_AIR | CHANGETURF_DEFER_CHANGE)
		if(new_turf)
			changed_turfs += new_turf

	var/surface_z = low_z + h
	var/surface_zkey = "[surface_z]"
	if(!z_turf_maps[surface_zkey] || !z_turf_maps[surface_zkey][key])
		return
	var/turf/surface = locate(x, y, surface_z)
	if(!surface)
		return

	if(biome == OW_RIVER)
		apply_river_surface(x, y, key, surface)
	else
		apply_biome_surface(x, y, key, biome, surface)

	for(var/z = surface_z + 1, z <= high_z, z++)
		var/zkey2 = "[z]"
		if(!z_turf_maps[zkey2] || !z_turf_maps[zkey2][key])
			continue
		var/turf/above = locate(x, y, z)
		if(!above || istype(above, /turf/open/transparent/openspace))
			continue
		var/turf/new_turf = above.ChangeTurf(/turf/open/transparent/openspace, null, CHANGETURF_IGNORE_AIR | CHANGETURF_DEFER_CHANGE)
		if(new_turf)
			changed_turfs += new_turf

/area/procedural_generation/overworld/proc/apply_river_surface(x, y, key, turf/surface)
	var/turf/below = GetBelow(surface)
	if(below)
		var/flow = river_flow_map[key] || SOUTH
		var/turf/bed = below.carve_flow_bed(/turf/open/floor/rogue/riverbot, flow)
		if(bed)
			contain_water(bed)
			changed_turfs += bed
	var/turf/river_surface = surface.ChangeTurf(/turf/open/transparent/openspace, null, CHANGETURF_IGNORE_AIR | CHANGETURF_DEFER_CHANGE)
	if(river_surface)
		contain_water(river_surface)
		changed_turfs += river_surface

/area/procedural_generation/overworld/proc/apply_biome_surface(x, y, key, biome, turf/surface)
	var/target_type
	switch(biome)
		if(OW_SWAMP)
			target_type = roll_swamp_surface(x, y)
		if(OW_DESERT)
			target_type = roll_desert_surface()
		if(OW_MOUNTAINS)
			target_type = roll_mountain_surface(x, y)
		if(OW_PLAINS)
			target_type = roll_plains_surface(x, y)
		if(OW_COAST)
			target_type = roll_coast_surface()
	if(!target_type)
		return
	var/turf/new_turf = surface.ChangeTurf(target_type, null, CHANGETURF_IGNORE_AIR | CHANGETURF_DEFER_CHANGE)
	if(new_turf)
		changed_turfs += new_turf

/area/procedural_generation/overworld/proc/no_water_neighbor(x, y)
	for(var/dir in GLOB.cardinals)
		var/list/offset = offset_for_dir(x, y, dir)
		var/nx = offset[1]
		var/ny = offset[2]
		var/nkey = "[nx]-[ny]"
		var/nbiome = biome_map[nkey]
		if(nbiome == OW_RIVER || nbiome == OW_OCEAN || nbiome == OW_COAST)
			return FALSE
		if(nbiome == OW_SWAMP)
			var/nh = height_map[nkey]
			var/turf/NT = locate(nx, ny, low_z + (isnull(nh) ? 0 : nh))
			if(istype(NT, /turf/open/water/swamp))
				return FALSE
	return TRUE

/area/procedural_generation/overworld/proc/roll_swamp_surface(x, y)
	if(prob(25))
		return /turf/open/water/swamp
	if(prob(murk_pool_chance) && no_water_neighbor(x, y))
		return /turf/open/floor/rogue/pool/murk
	return prob(60) ? /turf/open/floor/rogue/dirt/mud : /turf/open/floor/rogue/dirt

/area/procedural_generation/overworld/proc/roll_desert_surface()
	var/roll = rand(1, 100)
	if(roll <= 80)
		return /turf/open/floor/rogue/sand
	if(roll <= 95)
		return /turf/open/floor/rogue/AzureSand
	return /turf/open/floor/rogue/naturalstone

/area/procedural_generation/overworld/proc/roll_mountain_surface(x, y)
	var/t = biome_temperature(x, y)
	var/roll = rand(1, 100)
	if(t <= 15)
		if(roll <= 55)
			return /turf/open/floor/rogue/snow
		if(roll <= 80)
			return /turf/open/floor/rogue/snowrough
		return /turf/open/floor/rogue/naturalstone
	if(roll <= 70)
		return /turf/open/floor/rogue/naturalstone
	if(roll <= 85)
		return /turf/open/floor/rogue/snowpatchy
	return /turf/open/floor/rogue/naturalstone/aquifer

/area/procedural_generation/overworld/proc/roll_plains_surface(x, y)
	var/t = biome_temperature(x, y)
	var/roll = rand(1, 100)
	if(t <= cold_accent_temp)
		if(roll <= 60)
			return /turf/open/floor/rogue/grasscold
		if(roll <= 85)
			return /turf/open/floor/rogue/dirt
		return /turf/open/floor/rogue/snowpatchy
	if(roll <= 75)
		return /turf/open/floor/rogue/grass
	if(roll <= 95)
		return /turf/open/floor/rogue/dirt
	return /turf/open/floor/rogue/grass

/area/procedural_generation/overworld/proc/roll_coast_surface()
	var/roll = rand(1, 100)
	if(roll <= 60)
		return /turf/open/floor/rogue/sand
	if(roll <= 85)
		return /turf/open/floor/rogue/AzureSand
	return /turf/open/floor/rogue/naturalstone

/area/procedural_generation/overworld/proc/finalize_generation()
	for(var/turf/T as anything in changed_turfs)
		if(!T)
			continue
		QUEUE_SMOOTH(T)
		T.AfterChange(CHANGETURF_IGNORE_AIR)
	plant_flora()

/area/procedural_generation/overworld/proc/is_grass_turf(turf/T)
	return istype(T, /turf/open/floor/rogue/grass) || istype(T, /turf/open/floor/rogue/grasscold)

/area/procedural_generation/overworld/proc/too_close_to_tree(list/planted, center_x, center_y)
	for(var/dx = -1, dx <= 1, dx++)
		for(var/dy = -1, dy <= 1, dy++)
			if(planted["[center_x + dx]-[center_y + dy]"])
				return TRUE
	return FALSE

/area/procedural_generation/overworld/proc/plant_flora()
	var/list/planted = list()
	var/list/pending_trees = list()
	for(var/turf/T as anything in changed_turfs)
		if(!T || !is_grass_turf(T))
			continue
		if(!prob(tree_density))
			continue
		if(too_close_to_tree(planted, T.x, T.y))
			continue
		if(locate(/obj/structure) in T)
			continue
		planted["[T.x]-[T.y]"] = TRUE
		pending_trees += T

	for(var/turf/T as anything in pending_trees)
		if(prob(70))
			new /obj/structure/flora/newtree(T)
		else
			new /obj/structure/flora/roguetree(T)

	if(length(pending_trees))
		SStreesetup.InitializeTrees()

#undef OW_OCEAN
#undef OW_COAST
#undef OW_PLAINS
#undef OW_DESERT
#undef OW_SWAMP
#undef OW_MOUNTAINS
#undef OW_RIVER
