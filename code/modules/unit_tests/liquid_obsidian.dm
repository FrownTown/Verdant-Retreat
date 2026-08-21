/datum/unit_test/liquid_obsidian_quench_shallow/Run()
	var/turf/T = locate(35, 10, 1).ChangeTurf(/turf/open/floor/rogue/cobble, null, CHANGETURF_IGNORE_AIR)
	if(!T.cell)
		T.cell = new /cell(T)
		T.cell.InitLiquids()
	T.cell.sim_exempt = TRUE

	var/datum/liquid/lava_fluid = T.cell.get_fluid_datum(/datum/liquid/lava)
	var/datum/liquid/water_fluid = T.cell.get_fluid_datum(WATER)
	TEST_ASSERT_NOTNULL(lava_fluid, "test turf must have a lava fluid datum")
	TEST_ASSERT_NOTNULL(water_fluid, "test turf must have a water fluid datum")

	SSliquid.manager.add_fluid(T, lava_fluid, 40)
	SSliquid.manager.add_fluid(T, water_fluid, 50)

	SSliquid.lava_cells[T] = TRUE
	SSliquid.pool_manager.process_lava_quench()

	var/turf/result = locate(35, 10, 1)
	TEST_ASSERT(istype(result, /turf/open/floor/rogue/volcanic/obsidian), "shallow quench must turn the turf into an obsidian floor")
	TEST_ASSERT(!istype(result, /turf/closed/mineral/rogue/obsidian), "shallow quench must not produce an obsidian wall")
	TEST_ASSERT(!(T in SSliquid.lava_cells), "a solidified turf must be dropped from lava_cells")

	var/remaining
	for(var/attempt in 1 to 5)
		SSliquid.NativeFire()
		remaining = vn_fluid_total(result.x, result.y, result.z)
		if(remaining == 0)
			break
		sleep(1)
	TEST_ASSERT_EQUAL(remaining, 0, "shallow quench must fully consume the lava and clear the solidified turf")

	if(result.cell)
		SSliquid.clear_cell_fluid(result)
	else
		vn_fluid_queue(VN_FLUID_OP_CLEAR, result)
	SSliquid.NativeFire()

/datum/unit_test/liquid_obsidian_quench_deep/Run()
	var/turf/T = locate(35, 12, 1).ChangeTurf(/turf/open/floor/rogue/cobble, null, CHANGETURF_IGNORE_AIR)
	if(!T.cell)
		T.cell = new /cell(T)
		T.cell.InitLiquids()
	T.cell.sim_exempt = TRUE

	var/datum/liquid/lava_fluid = T.cell.get_fluid_datum(/datum/liquid/lava)
	var/datum/liquid/water_fluid = T.cell.get_fluid_datum(WATER)
	TEST_ASSERT_NOTNULL(lava_fluid, "test turf must have a lava fluid datum")
	TEST_ASSERT_NOTNULL(water_fluid, "test turf must have a water fluid datum")

	T.cell.fluid_volume[lava_fluid] = 90
	T.cell.fluid_volume[water_fluid] = 95
	SSliquid.update_fluidsum(T)

	SSliquid.lava_cells[T] = TRUE
	SSliquid.pool_manager.process_lava_quench()

	var/turf/result = locate(35, 12, 1)
	TEST_ASSERT(istype(result, /turf/closed/mineral/rogue/obsidian), "deep quench must turn the turf into an obsidian wall")
	TEST_ASSERT(!(T in SSliquid.lava_cells), "a solidified turf must be dropped from lava_cells")

	if(result.cell)
		SSliquid.clear_cell_fluid(result)
	SSliquid.NativeFire()

/datum/unit_test/liquid_obsidian_quench_insufficient/Run()
	var/turf/T = locate(35, 14, 1).ChangeTurf(/turf/open/floor/rogue/cobble, null, CHANGETURF_IGNORE_AIR)
	if(!T.cell)
		T.cell = new /cell(T)
		T.cell.InitLiquids()
	T.cell.sim_exempt = TRUE

	var/datum/liquid/lava_fluid = T.cell.get_fluid_datum(/datum/liquid/lava)
	var/datum/liquid/water_fluid = T.cell.get_fluid_datum(WATER)
	TEST_ASSERT_NOTNULL(lava_fluid, "test turf must have a lava fluid datum")
	TEST_ASSERT_NOTNULL(water_fluid, "test turf must have a water fluid datum")

	SSliquid.manager.add_fluid(T, lava_fluid, 60)
	SSliquid.manager.add_fluid(T, water_fluid, 30)

	SSliquid.lava_cells[T] = TRUE
	SSliquid.pool_manager.process_lava_quench()

	TEST_ASSERT(istype(T, /turf/open/floor/rogue/cobble), "insufficient quench must leave the original turf unchanged")
	TEST_ASSERT_EQUAL(T.cell.fluid_volume[lava_fluid], 60, "insufficient quench must not consume any lava")
	TEST_ASSERT_EQUAL(T.cell.fluid_volume[water_fluid], 30, "insufficient quench must not consume any water")

	SSliquid.lava_cells -= T
	SSliquid.clear_cell_fluid(T)
	SSliquid.NativeFire()

/datum/unit_test/liquid_obsidian_quench_adjacent/Run()
	var/turf/T = locate(35, 16, 1).ChangeTurf(/turf/open/floor/rogue/cobble, null, CHANGETURF_IGNORE_AIR)
	if(!T.cell)
		T.cell = new /cell(T)
		T.cell.InitLiquids()
	T.cell.sim_exempt = TRUE

	var/turf/N = get_step(T, EAST)
	TEST_ASSERT_NOTNULL(N, "adjacent quench test needs an adjacent turf")
	N = N.ChangeTurf(/turf/open/floor/rogue/cobble, null, CHANGETURF_IGNORE_AIR)
	if(!N.cell)
		N.cell = new /cell(N)
		N.cell.InitLiquids()
	N.cell.sim_exempt = TRUE

	var/datum/liquid/lava_fluid = T.cell.get_fluid_datum(/datum/liquid/lava)
	var/datum/liquid/water_fluid = N.cell.get_fluid_datum(WATER)
	TEST_ASSERT_NOTNULL(lava_fluid, "adjacent quench test turf must have a lava fluid datum")
	TEST_ASSERT_NOTNULL(water_fluid, "adjacent quench test neighbor must have a water fluid datum")

	SSliquid.manager.add_fluid(T, lava_fluid, 40)
	SSliquid.manager.add_fluid(N, water_fluid, 60)

	SSliquid.lava_cells[T] = TRUE
	SSliquid.pool_manager.process_lava_quench()

	var/turf/result = locate(35, 16, 1)
	TEST_ASSERT(istype(result, /turf/open/floor/rogue/volcanic/obsidian), "adjacent quench must turn the lava turf into an obsidian floor")
	TEST_ASSERT_EQUAL(N.cell.fluid_volume[water_fluid], 20, "adjacent quench must consume exactly lava_vol of water from the neighbor")

	if(result.cell)
		SSliquid.clear_cell_fluid(result)
	SSliquid.clear_cell_fluid(N)
	SSliquid.NativeFire()

/datum/unit_test/liquid_obsidian_dissolve_floor/Run()
	var/turf/T = locate(35, 18, 1).ChangeTurf(/turf/open/floor/rogue/volcanic/obsidian, null, CHANGETURF_IGNORE_AIR)
	if(!T.cell)
		T.cell = new /cell(T)
		T.cell.InitLiquids()
	T.cell.sim_exempt = TRUE

	var/datum/liquid/acid_fluid = T.cell.get_fluid_datum(/datum/liquid/acid)
	TEST_ASSERT_NOTNULL(acid_fluid, "test turf must have an acid fluid datum")

	SSliquid.manager.add_fluid(T, acid_fluid, 30)

	SSliquid.acid_cells[T] = TRUE
	SSliquid.pool_manager.process_acid_dissolution()

	var/turf/result = locate(35, 18, 1)
	TEST_ASSERT(istype(result, /turf/open/floor/rogue/naturalstone), "acid must dissolve an obsidian floor into bare stone")
	TEST_ASSERT(!istype(result, /turf/open/floor/rogue/volcanic/obsidian), "the dissolved turf must no longer be obsidian")

	var/expected = 30 - SSliquid.pool_manager.obsidian_dissolve_cost
	SSliquid.NativeFire()
	sleep(1)
	var/region_total = 0
	for(var/dx in -2 to 2)
		for(var/dy in -2 to 2)
			var/tile_total = vn_fluid_total(result.x + dx, result.y + dy, result.z)
			if(isnum(tile_total))
				region_total += tile_total
	TEST_ASSERT_EQUAL(region_total, expected, "dissolving an obsidian floor must consume exactly obsidian_dissolve_cost acid; the remainder is conserved in the local region")

	SSliquid.acid_cells -= T
	for(var/dx in -2 to 2)
		for(var/dy in -2 to 2)
			var/turf/cleanup_turf = locate(result.x + dx, result.y + dy, result.z)
			if(!cleanup_turf)
				continue
			if(cleanup_turf.cell)
				SSliquid.clear_cell_fluid(cleanup_turf)
			else
				vn_fluid_queue(VN_FLUID_OP_CLEAR, cleanup_turf)
	SSliquid.NativeFire()

/datum/unit_test/liquid_obsidian_dissolve_wall/Run()
	locate(36, 20, 1).ChangeTurf(/turf/closed/mineral/rogue/obsidian, null, CHANGETURF_IGNORE_AIR)
	var/turf/T = locate(35, 20, 1).ChangeTurf(/turf/open/floor/rogue/cobble, null, CHANGETURF_IGNORE_AIR)
	if(!T.cell)
		T.cell = new /cell(T)
		T.cell.InitLiquids()
	T.cell.sim_exempt = TRUE

	var/datum/liquid/acid_fluid = T.cell.get_fluid_datum(/datum/liquid/acid)
	TEST_ASSERT_NOTNULL(acid_fluid, "test turf must have an acid fluid datum")

	SSliquid.manager.add_fluid(T, acid_fluid, 30)

	SSliquid.acid_cells[T] = TRUE
	SSliquid.pool_manager.process_acid_dissolution()

	var/turf/result = locate(36, 20, 1)
	TEST_ASSERT(istype(result, /turf/open/floor/rogue/volcanic/obsidian), "acid must dissolve an obsidian wall into an obsidian floor")
	TEST_ASSERT(!istype(result, /turf/closed/mineral/rogue/obsidian), "the dissolved wall must no longer be an obsidian wall")
	TEST_ASSERT_EQUAL(T.cell.fluid_volume[acid_fluid], 30 - SSliquid.pool_manager.obsidian_dissolve_cost, "wall dissolution must consume exactly obsidian_dissolve_cost acid from the neighbor")

	SSliquid.acid_cells -= T
	SSliquid.clear_cell_fluid(T)
	if(result.cell)
		SSliquid.clear_cell_fluid(result)
	SSliquid.NativeFire()

/datum/unit_test/liquid_obsidian_acid_no_quench/Run()
	var/turf/T = locate(35, 22, 1).ChangeTurf(/turf/open/floor/rogue/cobble, null, CHANGETURF_IGNORE_AIR)
	if(!T.cell)
		T.cell = new /cell(T)
		T.cell.InitLiquids()
	T.cell.sim_exempt = TRUE

	var/datum/liquid/lava_fluid = T.cell.get_fluid_datum(/datum/liquid/lava)
	var/datum/liquid/acid_fluid = T.cell.get_fluid_datum(/datum/liquid/acid)
	TEST_ASSERT_NOTNULL(lava_fluid, "test turf must have a lava fluid datum")
	TEST_ASSERT_NOTNULL(acid_fluid, "test turf must have an acid fluid datum")

	SSliquid.manager.add_fluid(T, lava_fluid, 40)
	SSliquid.manager.add_fluid(T, acid_fluid, 60)

	SSliquid.lava_cells[T] = TRUE
	SSliquid.pool_manager.process_lava_quench()

	TEST_ASSERT(istype(T, /turf/open/floor/rogue/cobble), "acid must not quench lava into obsidian")
	TEST_ASSERT_EQUAL(T.cell.fluid_volume[lava_fluid], 40, "lava must remain fully intact when only acid is present")

	SSliquid.lava_cells -= T
	SSliquid.clear_cell_fluid(T)
	SSliquid.NativeFire()
