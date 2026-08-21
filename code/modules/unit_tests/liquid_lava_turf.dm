/datum/unit_test/liquid_lava_turf_burn/Run()
	var/turf/T = run_loc_bottom_left.ChangeTurf(/turf/open/lava, null, CHANGETURF_IGNORE_AIR)
	var/turf/open/lava/LT = T
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human, T)

	var/obj/item/natural/stone/held = new(H)
	H.put_in_hands(held)
	TEST_ASSERT(held in H.held_items, "test setup must actually equip the held item before burning")

	var/burned = LT.burn_stuff(H)
	TEST_ASSERT(burned, "burn_stuff must return TRUE for an unshielded human standing in lava")
	TEST_ASSERT_EQUAL(H.stat, DEAD, "burn_stuff must instantly kill an unshielded human")
	TEST_ASSERT_NOTNULL(locate(/obj/item/ash) in T, "burn_stuff must leave ash on the turf")

	sleep(20)
	TEST_ASSERT(QDELETED(H), "burn_stuff's dust() must fully delete the mob shortly after burning")
	TEST_ASSERT(QDELETED(held), "burn_stuff must destroy the mob's equipment along with the mob, leaving no dropped loot")

	T.ChangeTurf(/turf/open/floor/rogue/cobble, null, CHANGETURF_IGNORE_AIR)

/datum/unit_test/liquid_lava_turf_bridged/Run()
	var/turf/T = run_loc_bottom_left.ChangeTurf(/turf/open/lava, null, CHANGETURF_IGNORE_AIR)
	var/turf/open/lava/LT = T
	var/obj/structure/stone_tile/bridge = new(T)
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human, T)

	var/burned = LT.burn_stuff(H)
	TEST_ASSERT(!burned, "burn_stuff must not damage a mob standing on an unfallen stone_tile bridge")
	TEST_ASSERT_NOTEQUAL(H.stat, DEAD, "a bridged burn_stuff call must not kill the mob")
	TEST_ASSERT_EQUAL(H.getFireLoss(), 0, "a bridged burn_stuff call must leave the mob unharmed")

	bridge.fallen = TRUE
	var/burned_after_fall = LT.burn_stuff(H)
	TEST_ASSERT(burned_after_fall, "burn_stuff must damage the mob once the bridge has fallen")
	TEST_ASSERT_EQUAL(H.stat, DEAD, "burn_stuff must kill the mob once is_safe() no longer protects it")

	sleep(20)
	TEST_ASSERT(QDELETED(H), "burn_stuff's dust() must fully delete the mob shortly after the bridge falls")

	qdel(bridge)
	T.ChangeTurf(/turf/open/floor/rogue/cobble, null, CHANGETURF_IGNORE_AIR)
