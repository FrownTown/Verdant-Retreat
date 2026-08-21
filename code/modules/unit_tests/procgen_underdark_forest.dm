/datum/unit_test/procgen_underdark_forest
	var/list/report = list()
	var/test_z = 0
	var/list/restore_area = list()

/datum/unit_test/procgen_underdark_forest/proc/note(text)
	report += text

/datum/unit_test/procgen_underdark_forest/proc/find_test_z()
	for(var/candidate in 1 to length(SSmapping.multiz_levels))
		var/list/level = SSmapping.multiz_levels[candidate]
		if(level[Z_LEVEL_UP] && level[Z_LEVEL_DOWN])
			return candidate
	return 0

/datum/unit_test/procgen_underdark_forest/proc/fill_walls(x1, y1, x2, y2)
	for(var/x = x1, x <= x2, x++)
		for(var/y = y1, y <= y2, y++)
			for(var/z in list(test_z, test_z - 1))
				var/turf/T = locate(x, y, z)
				if(!T)
					continue
				if(istype(T, /turf/closed/mineral/rogue/bedrock))
					continue
				T.ChangeTurf(/turf/closed/mineral/rogue/bedrock)

/datum/unit_test/procgen_underdark_forest/proc/purge_atoms(x1, y1, x2, y2)
	for(var/x = x1, x <= x2, x++)
		for(var/y = y1, y <= y2, y++)
			var/turf/T = locate(x, y, test_z)
			if(!T)
				continue
			for(var/obj/structure/S in T)
				qdel(S)
			for(var/obj/item/I in T)
				qdel(I)

/datum/unit_test/procgen_underdark_forest/proc/claim_turfs(area/procedural_generation/target, list/coords)
	var/list/claimed = list()
	for(var/list/coord as anything in coords)
		var/turf/T = locate(coord[1], coord[2], test_z)
		if(!T)
			continue
		var/area/old_area = T.loc
		if(!restore_area["[T.x]-[T.y]"])
			restore_area["[T.x]-[T.y]"] = old_area
		target.contents += T
		T.change_area(old_area, target)
		claimed += T
	return claimed

/datum/unit_test/procgen_underdark_forest/proc/release_turfs(list/turfs)
	for(var/turf/T as anything in turfs)
		var/area/original = restore_area["[T.x]-[T.y]"]
		if(!original)
			continue
		var/area/current = T.loc
		if(current == original)
			continue
		original.contents += T
		T.change_area(current, original)

/datum/unit_test/procgen_underdark_forest/proc/rect_coords(x1, y1, x2, y2)
	var/list/out = list()
	for(var/x = x1, x <= x2, x++)
		for(var/y = y1, y <= y2, y++)
			out += list(list(x, y))
	return out

/datum/unit_test/procgen_underdark_forest/proc/is_big_mushroom(atom/candidate)
	if(istype(candidate, /obj/structure/flora/rogueshroom))
		return TRUE
	if(istype(candidate, /obj/structure/flora/mushroomcluster))
		return TRUE
	return FALSE

/datum/unit_test/procgen_underdark_forest/proc/is_small_mushroom(atom/candidate)
	if(istype(candidate, /obj/structure/flora/tinymushrooms))
		return TRUE
	if(istype(candidate, /obj/structure/zizo_bane))
		return TRUE
	if(istype(candidate, /obj/structure/flora/roguegrass))
		return TRUE
	if(istype(candidate, /obj/item/natural/stone))
		return TRUE
	if(istype(candidate, /obj/item/natural/rock))
		return TRUE
	return FALSE

/datum/unit_test/procgen_underdark_forest/proc/run_case()
	var/x1 = 8
	var/y1 = 70
	var/x2 = 47
	var/y2 = 109
	var/list/coords = rect_coords(x1, y1, x2, y2)
	fill_walls(x1, y1, x2, y2)
	purge_atoms(x1, y1, x2, y2)

	var/area/procedural_generation/cave/underdark_forest/test/subject = new
	var/list/claimed = claim_turfs(subject, coords)

	subject.setup_procgen()

	var/carved = 0
	var/dirt_seen = 0
	var/mud_seen = 0
	var/stone_seen = 0
	var/pool_seen = 0
	var/openspace_seen = 0
	var/big_structures = 0
	var/small_structures = 0
	var/item_structures = 0
	var/overlap_violations = 0
	var/bad_footing_violations = 0
	var/list/big_keys = list()

	for(var/list/coord as anything in coords)
		var/turf/T = locate(coord[1], coord[2], test_z)
		if(!T)
			continue
		if(!iswall(T))
			carved++
		if(istype(T, /turf/open/floor/rogue/dirt/mud))
			mud_seen++
		else if(istype(T, /turf/open/floor/rogue/dirt))
			dirt_seen++
		else if(istype(T, /turf/open/floor/rogue/naturalstone))
			stone_seen++
		else if(istype(T, /turf/open/floor/rogue/pool/murk))
			pool_seen++
		else if(istype(T, /turf/open/transparent/openspace))
			openspace_seen++

		var/list/structures_here = list()
		for(var/obj/structure/S in T)
			structures_here += S
		for(var/obj/item/natural/stone/ST in T)
			structures_here += ST
		for(var/obj/item/natural/rock/R in T)
			structures_here += R
		if(length(structures_here) > 1)
			overlap_violations++

		var/bad_footing = iswall(T) || istype(T, /turf/open/transparent/openspace) || istype(T, /turf/open/floor/rogue/pool/murk)
		var/big_here = FALSE
		for(var/atom/S as anything in structures_here)
			if(is_big_mushroom(S))
				big_structures++
				big_here = TRUE
			else if(istype(S, /obj/item/natural/stone) || istype(S, /obj/item/natural/rock))
				item_structures++
			else if(is_small_mushroom(S))
				small_structures++
			if(bad_footing)
				bad_footing_violations++
		if(big_here)
			big_keys += "[coord[1]]-[coord[2]]"

	var/adjacent_big_violations = 0
	for(var/key in big_keys)
		var/list/xy = splittext(key, "-")
		var/cx = text2num(xy[1])
		var/cy = text2num(xy[2])
		for(var/list/offset as anything in list(list(1, 0), list(-1, 0), list(0, 1), list(0, -1)))
			var/neighbor_key = "[cx + offset[1]]-[cy + offset[2]]"
			if(neighbor_key in big_keys)
				adjacent_big_violations++

	note("carved [carved] of [length(coords)] cells")
	note("floor mix -> dirt [dirt_seen], mud [mud_seen], naturalstone [stone_seen], murk pool [pool_seen], openspace [openspace_seen]")
	note("mushrooms -> [big_structures] big structures, [small_structures] small structures, [item_structures] item scatter")
	note("violations -> [overlap_violations] tile overlaps, [bad_footing_violations] bad footing, [adjacent_big_violations] adjacent big pairs")

	for(var/list/coord as anything in coords)
		var/turf/T = locate(coord[1], coord[2], test_z)
		if(!T)
			continue
		for(var/obj/structure/flora/F in T)
			qdel(F)
		for(var/obj/structure/zizo_bane/Z in T)
			qdel(Z)
		for(var/obj/item/natural/rock/R in T)
			qdel(R)
		for(var/obj/item/natural/stone/ST in T)
			qdel(ST)
		if(T.cell)
			SSliquid.clear_cell_fluid(T)
		var/turf/below = locate(coord[1], coord[2], test_z - 1)
		if(below && below.cell)
			SSliquid.clear_cell_fluid(below)

	release_turfs(claimed)
	SSprocgen.fluid_cells.Cut()
	SSprocgen.mimic_turfs.Cut()
	SSliquid.NativeFire()

	return list(
		"carved" = carved,
		"cells" = length(coords),
		"dirt" = dirt_seen,
		"mud" = mud_seen,
		"stone" = stone_seen,
		"big" = big_structures,
		"small" = small_structures,
		"items" = item_structures,
		"overlaps" = overlap_violations,
		"footing" = bad_footing_violations,
		"adjacent" = adjacent_big_violations
	)

/datum/unit_test/procgen_underdark_forest/Run()
	test_z = find_test_z()
	TEST_ASSERT(test_z, "No z level on this map has both an up and a down link, so the underdark cave-forest cannot be tested")
	note("running on z [test_z] of [length(SSmapping.multiz_levels)] linked levels")

	var/list/stats = run_case()

	fdel("data/procgen_underdark_forest_test.txt")
	var/logfile = file("data/procgen_underdark_forest_test.txt")
	for(var/line in report)
		logfile << line

	TEST_ASSERT(stats["carved"] >= 300, "Only [stats["carved"]] of [stats["cells"]] cells were carved open; the huge-cavern tuning is not producing sprawling caverns")
	TEST_ASSERT(stats["dirt"] >= 1, "No plain dirt cavern floor was generated")
	TEST_ASSERT(stats["mud"] >= 1, "No mud cavern floor was generated")
	TEST_ASSERT(stats["stone"] >= 1, "No naturalstone cavern floor was generated")
	TEST_ASSERT(stats["big"] + stats["small"] + stats["items"] >= 5, "Only [stats["big"] + stats["small"] + stats["items"]] mushroom/flora objects were placed in the footprint")
	TEST_ASSERT_EQUAL(stats["overlaps"], 0, "[stats["overlaps"]] tiles had more than one structure/item stacked on them")
	TEST_ASSERT_EQUAL(stats["footing"], 0, "[stats["footing"]] mushrooms are standing on a wall or water/pool turf")
	TEST_ASSERT_EQUAL(stats["adjacent"], 0, "[stats["adjacent"]] big mushrooms are cardinally adjacent to another big mushroom")
