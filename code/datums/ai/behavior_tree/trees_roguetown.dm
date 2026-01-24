// ==============================================================================
// ROGUETOWN BEHAVIOR TREES
// ==============================================================================

// ------------------------------------------------------------------------------
// NODE WRAPPERS
// ------------------------------------------------------------------------------

/datum/behavior_tree/node/action/has_target_check
	my_action = /bt_action/has_target

/datum/behavior_tree/node/action/find_target
	my_action = /bt_action/find_target

/datum/behavior_tree/node/action/target_in_range
	my_action = /bt_action/target_in_range

/datum/behavior_tree/node/action/attack_melee
	my_action = /bt_action/attack_melee

/datum/behavior_tree/node/action/move_to_target
	my_action = /bt_action/move_to_target

/datum/behavior_tree/node/action/idle_wander
	my_action = /bt_action/idle_wander

/datum/behavior_tree/node/action/use_ability
	my_action = /bt_action/use_ability

/datum/behavior_tree/node/action/attack_ranged
	my_action = /bt_action/attack_ranged

/datum/behavior_tree/node/action/find_food
	my_action = /bt_action/find_food

/datum/behavior_tree/node/action/eat_food
	my_action = /bt_action/eat_food

/datum/behavior_tree/node/action/mimic_disguise
	my_action = /bt_action/mimic_disguise

/datum/behavior_tree/node/action/mimic_undisguise
	my_action = /bt_action/mimic_undisguise

/datum/behavior_tree/node/action/move_to_dest
	my_action = /bt_action/move_to_destination

/datum/behavior_tree/node/action/dreamfiend_blink
	my_action = /bt_action/dreamfiend_blink

/datum/behavior_tree/node/action/check_hunger
	my_action = /bt_action/check_hunger

/datum/behavior_tree/node/action/flee_target
	my_action = /bt_action/flee_target

/datum/behavior_tree/node/action/find_and_set
	my_action = /bt_action/find_and_set

/datum/behavior_tree/node/action/set_move_target_key
	my_action = /bt_action/set_move_target_key

/datum/behavior_tree/node/action/minion_follow
	my_action = /bt_action/minion_follow

/datum/behavior_tree/node/action/call_reinforcements
	my_action = /bt_action/call_reinforcements

/datum/behavior_tree/node/action/random_speech
	my_action = /bt_action/random_speech

/datum/behavior_tree/node/action/maintain_distance
	my_action = /bt_action/maintain_distance

/datum/behavior_tree/node/action/eat_dead_body
	my_action = /bt_action/eat_dead_body

/datum/behavior_tree/node/action/static_melee_attack
	my_action = /bt_action/static_melee_attack

/datum/behavior_tree/node/action/deadite_migrate
	my_action = /bt_action/deadite_migrate

/datum/behavior_tree/node/action/colossus_stomp
	my_action = /bt_action/colossus_stomp

/datum/behavior_tree/node/action/behemoth_quake
	my_action = /bt_action/behemoth_quake

/datum/behavior_tree/node/action/leyline_teleport
	my_action = /bt_action/leyline_teleport

/datum/behavior_tree/node/action/obelisk_activate
	my_action = /bt_action/obelisk_activate

/datum/behavior_tree/node/action/dryad_vine
	my_action = /bt_action/dryad_vine

/datum/behavior_tree/node/action/chicken_check_ready
	my_action = /bt_action/chicken_check_ready

/datum/behavior_tree/node/action/chicken_lay_egg
	my_action = /bt_action/chicken_lay_egg

/datum/behavior_tree/node/action/chicken_find_nest
	my_action = /bt_action/chicken_find_nest

/datum/behavior_tree/node/action/chicken_check_material
	my_action = /bt_action/chicken_check_material

/datum/behavior_tree/node/action/chicken_build_nest
	my_action = /bt_action/chicken_build_nest

/datum/behavior_tree/node/action/chicken_find_material
	my_action = /bt_action/chicken_find_material

// ------------------------------------------------------------------------------
// SEQUENCES AND SELECTORS (DEFINITIONS)
// ------------------------------------------------------------------------------

/datum/behavior_tree/node/sequence/idle
	my_nodes = list(
		/datum/behavior_tree/node/action/idle_wander
	)

/datum/behavior_tree/node/sequence/attack_sequence
	my_nodes = list(
		/datum/behavior_tree/node/action/target_in_range,
		/datum/behavior_tree/node/action/attack_melee
	)

/datum/behavior_tree/node/selector/acquire_target
	my_nodes = list(
		/datum/behavior_tree/node/decorator/progress_validator/target_persistence/simple_has_target_wrapped,
		/datum/behavior_tree/node/action/simple_animal_check_aggressors_action,
		/datum/behavior_tree/node/decorator/retry/simple_find_target_wrapped
	)

// Wrap has_target in target_persistence decorator for simple_animals
// This gives simple animals 4 seconds to "remember" a target after losing sight
/datum/behavior_tree/node/decorator/progress_validator/target_persistence/simple_has_target_wrapped
	child = /datum/behavior_tree/node/action/has_target_check
	persistence_time = 4 SECONDS

// Wrap find_target in retry decorator for simple_animals
// This prevents spamming target searches every tick
/datum/behavior_tree/node/decorator/retry/simple_find_target_wrapped
	child = /datum/behavior_tree/node/action/find_target
	cooldown = 2 SECONDS
	max_failures = 1

/datum/behavior_tree/node/selector/engage_target
	my_nodes = list(
		/datum/behavior_tree/node/sequence/attack_sequence,
		/datum/behavior_tree/node/action/move_to_target,
		/datum/behavior_tree/node/sequence/simple_pursue_search
	)

// Pursue and search sequence for simple_animals - runs when we've lost the target
/datum/behavior_tree/node/sequence/simple_pursue_search
	my_nodes = list(
		/datum/behavior_tree/node/decorator/timeout/simple_pursue_last_known,
		/datum/behavior_tree/node/decorator/timeout/simple_search_area_wrapped
	)

// Pursue to last known location with 10 second timeout for simple_animals
/datum/behavior_tree/node/decorator/timeout/simple_pursue_last_known
	child = /datum/behavior_tree/node/action/simple_animal_pursue_last_known_action
	limit = 10 SECONDS

// Search area with 10 second timeout for simple_animals
/datum/behavior_tree/node/decorator/timeout/simple_search_area_wrapped
	child = /datum/behavior_tree/node/action/simple_animal_search_area_action
	limit = 10 SECONDS

/datum/behavior_tree/node/sequence/combat
	my_nodes = list(
		/datum/behavior_tree/node/selector/acquire_target,
		/datum/behavior_tree/node/selector/engage_target
	)

/datum/behavior_tree/node/sequence/scavenge
	my_nodes = list(
		/datum/behavior_tree/node/action/check_hunger,
		/datum/behavior_tree/node/action/find_food,
		/datum/behavior_tree/node/action/eat_food
	)

/datum/behavior_tree/node/sequence/idle_mimic
	my_nodes = list(
		/datum/behavior_tree/node/action/mimic_disguise,
		/datum/behavior_tree/node/action/find_target // Look for victims
	)

/datum/behavior_tree/node/sequence/combat_mimic
	my_nodes = list(
		/datum/behavior_tree/node/selector/acquire_target, // Reuse generic acquire
		/datum/behavior_tree/node/action/mimic_undisguise,
		/datum/behavior_tree/node/selector/engage_target // Reuse engage (move/attack)
	)

/datum/behavior_tree/node/selector/attack_choice_direbear
	my_nodes = list(
		/datum/behavior_tree/node/action/use_ability,
		/datum/behavior_tree/node/action/attack_melee
	)

/datum/behavior_tree/node/sequence/attack_sequence_direbear
	my_nodes = list(
		/datum/behavior_tree/node/action/target_in_range,
		/datum/behavior_tree/node/selector/attack_choice_direbear
	)

/datum/behavior_tree/node/selector/engage_target_direbear
	my_nodes = list(
		/datum/behavior_tree/node/sequence/attack_sequence_direbear,
		/datum/behavior_tree/node/action/move_to_target
	)

/datum/behavior_tree/node/sequence/combat_direbear
	my_nodes = list(
		/datum/behavior_tree/node/selector/acquire_target,
		/datum/behavior_tree/node/selector/engage_target_direbear
	)

/datum/behavior_tree/node/selector/engage_target_ranged
	my_nodes = list(
		/datum/behavior_tree/node/action/attack_ranged,
		/datum/behavior_tree/node/sequence/attack_sequence, // Fallback to melee
		/datum/behavior_tree/node/action/move_to_target
	)

/datum/behavior_tree/node/sequence/combat_ranged
	my_nodes = list(
		/datum/behavior_tree/node/selector/acquire_target,
		/datum/behavior_tree/node/selector/engage_target_ranged
	)

/datum/behavior_tree/node/sequence/attack_sequence_spacing
	my_nodes = list(
		/datum/behavior_tree/node/action/maintain_distance,
		/datum/behavior_tree/node/action/target_in_range,
		/datum/behavior_tree/node/action/attack_melee
	)

/datum/behavior_tree/node/selector/engage_target_skeleton
	my_nodes = list(
		/datum/behavior_tree/node/sequence/attack_sequence_spacing, // Use spacing logic
		/datum/behavior_tree/node/action/move_to_target
	)

/datum/behavior_tree/node/sequence/combat_skeleton
	my_nodes = list(
		/datum/behavior_tree/node/selector/acquire_target,
		/datum/behavior_tree/node/selector/engage_target_skeleton
	)

/datum/behavior_tree/node/selector/engage_target_orc
	my_nodes = list(
		/datum/behavior_tree/node/sequence/attack_sequence_spacing,
		/datum/behavior_tree/node/action/move_to_target
	)

/datum/behavior_tree/node/sequence/combat_orc
	my_nodes = list(
		/datum/behavior_tree/node/selector/acquire_target,
		/datum/behavior_tree/node/action/call_reinforcements, // Try to call help
		/datum/behavior_tree/node/selector/engage_target_orc
	)

/datum/behavior_tree/node/sequence/combat_volf
	my_nodes = list(
		/datum/behavior_tree/node/selector/acquire_target,
		/datum/behavior_tree/node/action/call_reinforcements,
		/datum/behavior_tree/node/selector/engage_target
	)

/datum/behavior_tree/node/selector/engage_target_dreamfiend
	my_nodes = list(
		/datum/behavior_tree/node/action/dreamfiend_blink,
		/datum/behavior_tree/node/sequence/attack_sequence,
		/datum/behavior_tree/node/action/move_to_target
	)

/datum/behavior_tree/node/sequence/combat_dreamfiend
	my_nodes = list(
		/datum/behavior_tree/node/selector/acquire_target,
		/datum/behavior_tree/node/selector/engage_target_dreamfiend
	)

// ------------------------------------------------------------------------------
// SUMMON SEQUENCES/SELECTORS
// ------------------------------------------------------------------------------

/datum/behavior_tree/node/selector/engage_target_colossus
	my_nodes = list(
		/datum/behavior_tree/node/action/colossus_stomp,
		/datum/behavior_tree/node/sequence/attack_sequence,
		/datum/behavior_tree/node/action/move_to_target
	)

/datum/behavior_tree/node/sequence/combat_colossus
	my_nodes = list(
		/datum/behavior_tree/node/selector/acquire_target,
		/datum/behavior_tree/node/selector/engage_target_colossus
	)

/datum/behavior_tree/node/selector/engage_target_behemoth
	my_nodes = list(
		/datum/behavior_tree/node/action/behemoth_quake,
		/datum/behavior_tree/node/sequence/attack_sequence,
		/datum/behavior_tree/node/action/move_to_target
	)

/datum/behavior_tree/node/sequence/combat_behemoth
	my_nodes = list(
		/datum/behavior_tree/node/selector/acquire_target,
		/datum/behavior_tree/node/selector/engage_target_behemoth
	)

/datum/behavior_tree/node/selector/engage_target_leyline
	my_nodes = list(
		/datum/behavior_tree/node/action/leyline_teleport,
		/datum/behavior_tree/node/sequence/attack_sequence,
		/datum/behavior_tree/node/action/move_to_target
	)

/datum/behavior_tree/node/sequence/combat_leyline
	my_nodes = list(
		/datum/behavior_tree/node/selector/acquire_target,
		/datum/behavior_tree/node/selector/engage_target_leyline
	)

/datum/behavior_tree/node/selector/engage_target_obelisk
	my_nodes = list(
		/datum/behavior_tree/node/action/obelisk_activate,
		/datum/behavior_tree/node/action/move_to_target
	)

/datum/behavior_tree/node/sequence/combat_obelisk
	my_nodes = list(
		/datum/behavior_tree/node/selector/acquire_target,
		/datum/behavior_tree/node/selector/engage_target_obelisk
	)

/datum/behavior_tree/node/selector/engage_target_dryad
	my_nodes = list(
		/datum/behavior_tree/node/action/dryad_vine,
		/datum/behavior_tree/node/sequence/attack_sequence,
		/datum/behavior_tree/node/action/move_to_target
	)

/datum/behavior_tree/node/sequence/combat_dryad
	my_nodes = list(
		/datum/behavior_tree/node/selector/acquire_target,
		/datum/behavior_tree/node/selector/engage_target_dryad
	)

// ------------------------------------------------------------------------------
// CHICKEN SEQUENCES/SELECTORS
// ------------------------------------------------------------------------------

/datum/behavior_tree/node/sequence/chicken_lay_on_nest
	my_nodes = list(
		/datum/behavior_tree/node/action/chicken_lay_egg
	)

/datum/behavior_tree/node/sequence/chicken_build_nest
	my_nodes = list(
		/datum/behavior_tree/node/action/chicken_check_material,
		/datum/behavior_tree/node/action/chicken_build_nest
	)

/datum/behavior_tree/node/sequence/chicken_find_nest
	my_nodes = list(
		/datum/behavior_tree/node/action/chicken_find_nest,
		/datum/behavior_tree/node/action/move_to_dest
	)

/datum/behavior_tree/node/sequence/chicken_find_material
	my_nodes = list(
		/datum/behavior_tree/node/action/chicken_find_material,
		/datum/behavior_tree/node/action/move_to_dest
	)

/datum/behavior_tree/node/selector/chicken_nesting_logic
	my_nodes = list(
		/datum/behavior_tree/node/sequence/chicken_lay_on_nest,
		/datum/behavior_tree/node/sequence/chicken_build_nest,
		/datum/behavior_tree/node/sequence/chicken_find_nest,
		/datum/behavior_tree/node/sequence/chicken_find_material
	)

/datum/behavior_tree/node/sequence/chicken_egg_laying
	my_nodes = list(
		/datum/behavior_tree/node/action/chicken_check_ready,
		/datum/behavior_tree/node/selector/chicken_nesting_logic
	)

// ------------------------------------------------------------------------------
// TREES (ROOTS)
// ------------------------------------------------------------------------------

/datum/behavior_tree/node/selector/generic_hostile_tree
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/idle
	)

/datum/behavior_tree/node/selector/generic_hungry_hostile_tree
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/scavenge,
		/datum/behavior_tree/node/sequence/idle
	)

/datum/behavior_tree/node/selector/generic_friendly_tree
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/scavenge,
		/datum/behavior_tree/node/sequence/idle
	)

/datum/behavior_tree/node/selector/direbear_tree
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat_direbear,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/scavenge,
		/datum/behavior_tree/node/sequence/idle
	)

/datum/behavior_tree/node/selector/deepone_melee_tree
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/idle
	)

/datum/behavior_tree/node/selector/deepone_ranged_tree
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat_ranged,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/idle
	)

/datum/behavior_tree/node/selector/haunt_tree
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/idle
	)

/datum/behavior_tree/node/selector/mimic_tree
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat_mimic,
		/datum/behavior_tree/node/sequence/scavenge,
		/datum/behavior_tree/node/sequence/idle_mimic
	)

/datum/behavior_tree/node/selector/dreamfiend_tree
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat_dreamfiend,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/idle
	)

/datum/behavior_tree/node/selector/skeleton_tree
	my_nodes = list(
		/datum/behavior_tree/node/action/minion_follow,
		/datum/behavior_tree/node/sequence/combat_skeleton,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/idle
	)

/datum/behavior_tree/node/selector/orc_tree
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat_orc,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/idle
	)

/datum/behavior_tree/node/selector/volf_tree
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat_volf,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/idle
	)

/datum/behavior_tree/node/selector/mirespider_tree
	my_nodes = list(
		/datum/behavior_tree/node/action/minion_follow,
		/datum/behavior_tree/node/sequence/combat,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/idle
	)

/datum/behavior_tree/node/selector/mossback_tree
	my_nodes = list(
		/datum/behavior_tree/node/action/minion_follow,
		/datum/behavior_tree/node/sequence/combat,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/idle
	)

/datum/behavior_tree/node/selector/wolf_undead_tree
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat,
		/datum/behavior_tree/node/action/deadite_migrate,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/idle
	)

/datum/behavior_tree/node/selector/colossus_tree
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat_colossus,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/idle
	)

/datum/behavior_tree/node/selector/behemoth_tree
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat_behemoth,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/idle
	)

/datum/behavior_tree/node/selector/leyline_tree
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat_leyline,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/idle
	)

/datum/behavior_tree/node/selector/obelisk_tree
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat_obelisk,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/idle
	)

/datum/behavior_tree/node/selector/dryad_tree
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat_dryad,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/idle
	)

/datum/behavior_tree/node/selector/insane_clown_tree
	my_nodes = list(
		/datum/behavior_tree/node/selector/acquire_target,
		/datum/behavior_tree/node/sequence/idle
	)

/datum/behavior_tree/node/selector/chicken_tree
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/chicken_egg_laying,
		/datum/behavior_tree/node/sequence/idle
	)

// ------------------------------------------------------------------------------
// SIMPLE_ANIMAL ACTION NODE WRAPPERS
// ------------------------------------------------------------------------------

/datum/behavior_tree/node/action/simple_animal_check_aggressors_action
	my_action = /bt_action/simple_animal_check_aggressors

/datum/behavior_tree/node/action/simple_animal_pursue_last_known_action
	my_action = /bt_action/simple_animal_pursue_last_known

/datum/behavior_tree/node/action/simple_animal_search_area_action
	my_action = /bt_action/simple_animal_search_area
