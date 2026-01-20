GLOBAL_LIST_INIT(deadite_animal_migration_points, list())
#define BB_DEADITE_MIGRATION_PATH "deadite_migration_path"
#define BB_DEADITE_MIGRATION_TARGET "deadite_migration_target"
#define BB_DEADITE_TRAVEL_TARGET "deadite_travel_target"

/obj/effect/landmark/events/deadite_animal_migration_point
	name = "Deadite Migration Point"
	//If you don't manually set an order on these, they won't work
	//Do not set these more than 10 tiles apart or the AI will struggle
	var/order = 0

/obj/effect/landmark/events/deadite_animal_migration_point/Initialize(mapload)
	. = ..()
	GLOB.deadite_animal_migration_points += src
	icon_state = ""
	if(!order)
		order = 1

/proc/cmp_deadite_migration_point_asc(obj/effect/landmark/events/deadite_animal_migration_point/A, obj/effect/landmark/events/deadite_animal_migration_point/B)
	return A.order - B.order

/proc/get_sorted_migration_points()
	var/list/points = GLOB.deadite_animal_migration_points.Copy()
	sortTim(points, GLOBAL_PROC_REF(cmp_deadite_migration_point_asc))
	return points

/datum/round_event_control/deadite_animal_migration
	name = "Deadite Animal Migration"
	track = EVENT_TRACK_MODERATE
	typepath = /datum/round_event/deadite_migration/deadite
	weight = 3
	max_occurrences = 2
	min_players = 20
	earliest_start = 20 MINUTES

	tags = list(
		TAG_TRICKERY,
		TAG_UNEXPECTED,
	)

/datum/round_event/deadite_migration
	var/list/animals = list()

/datum/round_event/deadite_migration/start()
	. = ..()
	var/list/sorted_points = get_sorted_migration_points()
	// Build full migration path with all points
	var/list/migration_turfs = list()
	for(var/obj/effect/landmark/events/deadite_animal_migration_point/point in sorted_points)
		var/turf/T = get_turf(point)
		if(T)
			migration_turfs += T

	if(!length(migration_turfs))
		return
	
	var/turf/spawn_turf = migration_turfs[1]
	var/turf/end_turf = migration_turfs[migration_turfs.len]
	var/players_amt = get_active_player_count(alive_check = 1, afk_check = 1, human_check = 1)
	//Scale amount with pop.
	var/lower_limit = 3 + ROUND_UP(players_amt / 10)
	var/upper_limit = 5 + ROUND_UP(players_amt / 7)

	var/mob/living/simple_animal/hostile/retaliate/rogue/animal = pick(animals)
	for(var/i = 1 to rand(lower_limit, upper_limit))
		var/mob/living/simple_animal/hostile/retaliate/rogue/created = new animal(spawn_turf)
		created.faction = list("undead")
		created.gold_core_spawnable = NO_SPAWN
		created.aggressive = TRUE
		if(created.ai_root)
			created.ai_root.blackboard["deadite_migration_path"] = migration_turfs
			// The tree will handle picking the first target from the path
		else
			created.GiveTarget(end_turf)
		//Stagger the mobs.
		sleep(rand(1 SECONDS, 3 SECONDS))

//JUST undead wolves for now. Saigas are far too strong.
/datum/round_event/deadite_migration/deadite
	animals = list(
		/mob/living/simple_animal/hostile/retaliate/rogue/wolf_undead,
	)

/datum/round_event_control/deadite_animal_migration/canSpawnEvent(players_amt, gamemode, fake_check)
	if(!LAZYLEN(GLOB.deadite_animal_migration_points))
		return FALSE
