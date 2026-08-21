/datum/unit_test/liquid_hazard_lava/Run()
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)
	var/turf/T = run_loc_bottom_left.ChangeTurf(/turf/open/floor/rogue/cobble, null, CHANGETURF_IGNORE_AIR)
	if(!T.cell)
		T.cell = new /cell(T)
		T.cell.InitLiquids()
	var/datum/liquid/lava_fluid = T.cell.get_fluid_datum(/datum/liquid/lava)
	TEST_ASSERT_NOTNULL(lava_fluid, "test turf must have a lava fluid datum")
	T.cell.fluid_volume[lava_fluid] = MAX_FLUID_VOLUME
	SSliquid.update_fluidsum(T)

	H.forceMove(T)

	var/obj/structure/stone_tile/bridge = new(T)
	var/bridged = SSliquid.registry.lava_burn(H, T)
	TEST_ASSERT(!bridged, "lava_burn must not damage a mob standing on an unfallen stone_tile bridge")
	TEST_ASSERT_NOTEQUAL(H.stat, DEAD, "a bridged lava_burn call must not kill the mob")
	bridge.fallen = TRUE
	qdel(bridge)

	var/obj/item/natural/stone/held = new(H)
	H.put_in_hands(held)
	TEST_ASSERT(held in H.held_items, "test setup must actually equip the held item before burning")

	var/burned = SSliquid.registry.lava_burn(H, T)
	TEST_ASSERT(burned, "lava_burn must return TRUE on an unshielded human standing in a full lava cell")
	TEST_ASSERT_EQUAL(H.stat, DEAD, "lava_burn must instantly kill an unshielded human")
	TEST_ASSERT_NOTNULL(locate(/obj/item/ash) in T, "lava_burn must leave ash on the turf")

	sleep(20)
	TEST_ASSERT(QDELETED(H), "lava_burn's dust() must fully delete the mob shortly after burning")
	TEST_ASSERT(QDELETED(held), "lava_burn must destroy the mob's equipment along with the mob, leaving no dropped loot")

	SSliquid.clear_cell_fluid(T)

/datum/unit_test/liquid_hazard_lava_melt_obj/Run()
	var/turf/T = run_loc_bottom_left.ChangeTurf(/turf/open/floor/rogue/cobble, null, CHANGETURF_IGNORE_AIR)
	if(!T.cell)
		T.cell = new /cell(T)
		T.cell.InitLiquids()
	var/datum/liquid/lava_fluid = T.cell.get_fluid_datum(/datum/liquid/lava)
	TEST_ASSERT_NOTNULL(lava_fluid, "test turf must have a lava fluid datum")
	T.cell.fluid_volume[lava_fluid] = MAX_FLUID_VOLUME
	SSliquid.update_fluidsum(T)

	var/obj/item/natural/stone/rock = new(T)
	var/melted = SSliquid.registry.lava_melt_obj_check(rock, T)
	TEST_ASSERT(melted, "lava_melt_obj_check must return TRUE for a plain object on a full lava cell")
	TEST_ASSERT(QDELETED(rock), "lava_melt_obj_check must qdel a plain object standing in lava")

	SSliquid.clear_cell_fluid(T)

/datum/unit_test/liquid_hazard_lava_melt_obj_proof/Run()
	var/turf/T = run_loc_bottom_left.ChangeTurf(/turf/open/floor/rogue/cobble, null, CHANGETURF_IGNORE_AIR)
	if(!T.cell)
		T.cell = new /cell(T)
		T.cell.InitLiquids()
	var/datum/liquid/lava_fluid = T.cell.get_fluid_datum(/datum/liquid/lava)
	TEST_ASSERT_NOTNULL(lava_fluid, "test turf must have a lava fluid datum")
	T.cell.fluid_volume[lava_fluid] = MAX_FLUID_VOLUME
	SSliquid.update_fluidsum(T)

	var/obj/item/natural/stone/rock = new(T)
	rock.resistance_flags |= LAVA_PROOF
	var/melted = SSliquid.registry.lava_melt_obj_check(rock, T)
	TEST_ASSERT(!melted, "lava_melt_obj_check must not melt a LAVA_PROOF object")
	TEST_ASSERT(!QDELETED(rock), "a LAVA_PROOF object must survive lava_melt_obj_check")

	qdel(rock)
	SSliquid.clear_cell_fluid(T)

/datum/unit_test/liquid_hazard_lava_melt_obj_bridge/Run()
	var/turf/T = run_loc_bottom_left.ChangeTurf(/turf/open/floor/rogue/cobble, null, CHANGETURF_IGNORE_AIR)
	if(!T.cell)
		T.cell = new /cell(T)
		T.cell.InitLiquids()
	var/datum/liquid/lava_fluid = T.cell.get_fluid_datum(/datum/liquid/lava)
	TEST_ASSERT_NOTNULL(lava_fluid, "test turf must have a lava fluid datum")
	T.cell.fluid_volume[lava_fluid] = MAX_FLUID_VOLUME
	SSliquid.update_fluidsum(T)

	var/obj/structure/stone_tile/bridge = new(T)
	var/obj/item/natural/stone/rock = new(T)
	var/melted = SSliquid.registry.lava_melt_obj_check(rock, T)
	TEST_ASSERT(!melted, "lava_melt_obj_check must not melt an object on a stone_tile-bridged lava turf")
	TEST_ASSERT(!QDELETED(rock), "an object on a bridged lava turf must survive")

	qdel(rock)
	bridge.fallen = TRUE
	qdel(bridge)
	SSliquid.clear_cell_fluid(T)

/datum/unit_test/liquid_hazard_lava_band_crossed_sweep/Run()
	var/turf/T = run_loc_bottom_left.ChangeTurf(/turf/open/floor/rogue/cobble, null, CHANGETURF_IGNORE_AIR)
	if(!T.cell)
		T.cell = new /cell(T)
		T.cell.InitLiquids()
	var/datum/liquid/lava_fluid = T.cell.get_fluid_datum(/datum/liquid/lava)
	TEST_ASSERT_NOTNULL(lava_fluid, "test turf must have a lava fluid datum")
	T.cell.fluid_volume[lava_fluid] = MAX_FLUID_VOLUME
	SSliquid.update_fluidsum(T)
	SSliquid.sync_cell_to_native(T)

	var/obj/item/natural/stone/rock = new(T)
	SSliquid.lava_band_crossed(T)
	TEST_ASSERT(QDELETED(rock), "lava_band_crossed must sweep and melt objects on a lava-bearing turf")

	SSliquid.clear_cell_fluid(T)

/datum/unit_test/liquid_hazard_acid/Run()
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)
	var/turf/T = run_loc_top_right.ChangeTurf(/turf/open/floor/rogue/cobble, null, CHANGETURF_IGNORE_AIR)
	if(!T.cell)
		T.cell = new /cell(T)
		T.cell.InitLiquids()
	var/datum/liquid/acid_fluid = T.cell.get_fluid_datum(/datum/liquid/acid)
	TEST_ASSERT_NOTNULL(acid_fluid, "test turf must have an acid fluid datum")
	T.cell.fluid_volume[acid_fluid] = MAX_FLUID_VOLUME
	SSliquid.update_fluidsum(T)

	H.forceMove(T)

	var/pre_fireloss = H.getFireLoss()
	var/corroded = SSliquid.registry.corrode_mob(H, T)
	TEST_ASSERT(corroded, "corrode_mob must return TRUE on a human standing in a full acid cell")
	TEST_ASSERT(H.getFireLoss() > pre_fireloss, "corrode_mob must increase fire damage")

	SSliquid.clear_cell_fluid(T)

/datum/unit_test/liquid_hazard_murk/Run()
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)
	var/turf/T = run_loc_bottom_left.ChangeTurf(/turf/open/floor/rogue/cobble, null, CHANGETURF_IGNORE_AIR)
	if(!T.cell)
		T.cell = new /cell(T)
		T.cell.InitLiquids()
	var/datum/liquid/murk_fluid = T.cell.get_fluid_datum(/datum/liquid/murk)
	TEST_ASSERT_NOTNULL(murk_fluid, "test turf must have a murk fluid datum")
	T.cell.fluid_volume[murk_fluid] = MAX_FLUID_VOLUME
	SSliquid.update_fluidsum(T)

	H.forceMove(T)
	H.m_intent = MOVE_INTENT_RUN

	var/leeched = FALSE
	for(var/i in 1 to 500)
		if(SSliquid.registry.murk_leech(H, T))
			leeched = TRUE
			break
	TEST_ASSERT(leeched, "murk_leech must eventually embed a leech on a running human in a full murk cell")

	SSliquid.clear_cell_fluid(T)

/datum/unit_test/liquid_hazard_murk_spread/Run()
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)
	var/turf/source = run_loc_bottom_left.ChangeTurf(/turf/open/floor/rogue/cobble, null, CHANGETURF_IGNORE_AIR)
	if(!source.cell)
		source.cell = new /cell(source)
		source.cell.InitLiquids()
	var/datum/liquid/murk_fluid = source.cell.get_fluid_datum(/datum/liquid/murk)
	TEST_ASSERT_NOTNULL(murk_fluid, "murk spread test source turf must have a murk fluid datum")
	var/turf/neighbor = get_step(source, EAST)
	TEST_ASSERT_NOTNULL(neighbor, "murk spread test needs an adjacent turf")
	neighbor = neighbor.ChangeTurf(/turf/open/floor/rogue/cobble, null, CHANGETURF_IGNORE_AIR)
	if(!neighbor.cell)
		neighbor.cell = new /cell(neighbor)
		neighbor.cell.InitLiquids()

	SSliquid.manager.add_fluid(source, murk_fluid, 100)

	var/pumps = 0
	while(neighbor.cell.fluidsum < MIN_FLUID_VOLUME && pumps < 300)
		SSliquid.NativeFire()
		sleep(1)
		pumps++
	TEST_ASSERT(neighbor.cell.fluidsum >= MIN_FLUID_VOLUME, "murk source must spread fluid onto its neighbor within [pumps] pumps")

	var/pre_type_sum = 0
	for(var/datum/liquid/fluid as anything in neighbor.cell.fluid_volume)
		pre_type_sum += neighbor.cell.fluid_volume[fluid]
	TEST_ASSERT(pre_type_sum < neighbor.cell.fluidsum, "precondition: a freshly spread cell's type vector must not yet be materialized")

	H.forceMove(neighbor)
	H.m_intent = MOVE_INTENT_RUN

	var/leeched = FALSE
	for(var/i in 1 to 500)
		SSliquid.registry.trigger_behavior_on_enter(H, neighbor)
		for(var/obj/item/bodypart/BP as anything in H.bodyparts)
			for(var/obj/item/natural/worms/leech/L in BP.embedded_objects)
				leeched = TRUE
		if(leeched)
			break
	TEST_ASSERT(leeched, "trigger_behavior_on_enter must materialize a spread cell's type vector so on_enter behaviors can still fire")

	SSliquid.clear_cell_fluid(neighbor)
	SSliquid.clear_cell_fluid(source)
	SSliquid.NativeFire()
