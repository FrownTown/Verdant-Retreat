/datum/unit_test/liquid_pool_turf_lava/Run()
	var/turf/open/floor/rogue/pool/lava/T = run_loc_bottom_left.ChangeTurf(/turf/open/floor/rogue/pool/lava, null, CHANGETURF_IGNORE_AIR)
	TEST_ASSERT_NOTNULL(T.cell, "lava pool must have a liquid cell")
	var/datum/liquid/fluid = T.cell.get_fluid_datum(/datum/liquid/lava)
	TEST_ASSERT_NOTNULL(fluid, "lava pool cell must have a lava fluid datum")
	TEST_ASSERT_EQUAL(T.cell.fluid_volume[fluid], MAX_FLUID_VOLUME, "lava pool must initialize at max fluid volume")
	TEST_ASSERT_EQUAL(T.cell.is_liquid_source, TRUE, "lava pool must be a liquid source")

	SSliquid.clear_cell_fluid(T)

/datum/unit_test/liquid_pool_turf_acid/Run()
	var/turf/open/floor/rogue/pool/acid/T = run_loc_top_right.ChangeTurf(/turf/open/floor/rogue/pool/acid, null, CHANGETURF_IGNORE_AIR)
	TEST_ASSERT_NOTNULL(T.cell, "acid pool must have a liquid cell")
	var/datum/liquid/fluid = T.cell.get_fluid_datum(/datum/liquid/acid)
	TEST_ASSERT_NOTNULL(fluid, "acid pool cell must have an acid fluid datum")
	TEST_ASSERT_EQUAL(T.cell.fluid_volume[fluid], MAX_FLUID_VOLUME, "acid pool must initialize at max fluid volume")
	TEST_ASSERT_EQUAL(T.cell.is_liquid_source, TRUE, "acid pool must be a liquid source")

	SSliquid.clear_cell_fluid(T)

/datum/unit_test/liquid_pool_turf_blood/Run()
	var/turf/open/floor/rogue/pool/blood/T = run_loc_bottom_left.ChangeTurf(/turf/open/floor/rogue/pool/blood, null, CHANGETURF_IGNORE_AIR)
	TEST_ASSERT_NOTNULL(T.cell, "blood pool must have a liquid cell")
	var/datum/liquid/fluid = T.cell.get_fluid_datum(/datum/liquid/blood)
	TEST_ASSERT_NOTNULL(fluid, "blood pool cell must have a blood fluid datum")
	TEST_ASSERT_EQUAL(T.cell.fluid_volume[fluid], MAX_FLUID_VOLUME, "blood pool must initialize at max fluid volume")
	TEST_ASSERT_EQUAL(T.cell.is_liquid_source, FALSE, "blood pool must not be a liquid source")

	SSliquid.clear_cell_fluid(T)

/datum/unit_test/liquid_pool_turf_murk/Run()
	var/turf/open/floor/rogue/pool/murk/T = run_loc_top_right.ChangeTurf(/turf/open/floor/rogue/pool/murk, null, CHANGETURF_IGNORE_AIR)
	TEST_ASSERT_NOTNULL(T.cell, "murk pool must have a liquid cell")
	var/datum/liquid/fluid = T.cell.get_fluid_datum(/datum/liquid/murk)
	TEST_ASSERT_NOTNULL(fluid, "murk pool cell must have a murk fluid datum")
	TEST_ASSERT_EQUAL(T.cell.fluid_volume[fluid], MAX_FLUID_VOLUME, "murk pool must initialize at max fluid volume")
	TEST_ASSERT_EQUAL(T.cell.is_liquid_source, TRUE, "murk pool must be a liquid source")

	SSliquid.clear_cell_fluid(T)
