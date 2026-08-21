// A dmm tile definition must reference exactly one area: stacked /area paths corrupt the area atom at map load.
/datum/unit_test/dmm_single_area_keys/Run()
	var/list/self_check = scan_dmm_text({""aaa" = (/turf/open/floor,/area/rogue,/area/rogue/indoors)
"aab" = (/obj/structure/table,/turf/open/floor,/area/rogue)
"aac" = (/turf/open/floor{name = "odd, /area lookalike"; dir = 4},/area/rogue)
"})
	TEST_ASSERT_EQUAL(length(self_check), 1, "The dmm key scanner failed its self-check: expected 1 flagged key, got [length(self_check)] ([jointext(self_check, "; ")])")
	TEST_ASSERT(findtext(self_check[1], "aaa"), "The dmm key scanner flagged the wrong key in its self-check: [self_check[1]]")

	var/list/failures = list()
	var/scanned = 0
	for(var/path in list_dmm_files("_maps/"))
		scanned++
		var/list/bad_keys = scan_dmm_text(file2text(path))
		if(length(bad_keys))
			failures += "[path]: [jointext(bad_keys, ", ")]"

	TEST_ASSERT(scanned, "No .dmm files were found under _maps/")
	TEST_ASSERT(!length(failures), "Tile definitions with more than one /area path: [jointext(failures, " | ")]")

/datum/unit_test/dmm_single_area_keys/proc/list_dmm_files(dir)
	var/list/found = list()
	for(var/entry in flist(dir))
		if(copytext(entry, -1) == "/")
			found += list_dmm_files("[dir][entry]")
		else if(copytext(entry, -4) == ".dmm")
			found += "[dir][entry]"
	return found

/datum/unit_test/dmm_single_area_keys/proc/scan_dmm_text(text)
	var/list/bad_keys = list()
	var/grid_start = findtext(text, regex(@"\n\(\d+,\d+,\d+\) = \{"))
	var/header = grid_start ? copytext(text, 1, grid_start) : text
	for(var/chunk in splittext("\n[header]", "\n\""))
		var/key_end = findtext(chunk, "\"")
		if(!key_end)
			continue
		var/areas = 0
		var/pos = 1
		while(TRUE)
			pos = findtext(chunk, "/area", pos)
			if(!pos)
				break
			var/prefix = pos > 1 ? copytext(chunk, pos - 1, pos) : ""
			if(prefix == "(" || prefix == ",")
				areas++
			pos += 5
		if(areas > 1)
			bad_keys += "\"[copytext(chunk, 1, key_end)]\" ([areas] areas)"
	return bad_keys
