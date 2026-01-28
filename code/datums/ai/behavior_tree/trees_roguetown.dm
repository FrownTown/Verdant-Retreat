// ==============================================================================
// ROGUETOWN BEHAVIOR TREES (REFACTORED)
// ==============================================================================

// ------------------------------------------------------------------------------
// NODE WRAPPERS FOR ATOMIZED ACTIONS
// ------------------------------------------------------------------------------

/datum/behavior_tree/node/action/pick_best_target
	my_action = /bt_action/pick_best_target

/datum/behavior_tree/node/action/switch_to_aggressor
	my_action = /bt_action/switch_to_aggressor

/datum/behavior_tree/node/action/set_movement_target
	my_action = /bt_action/set_movement_target

/datum/behavior_tree/node/action/check_path_progress
	my_action = /bt_action/check_path_progress

/datum/behavior_tree/node/action/face_target
	my_action = /bt_action/face_target

/datum/behavior_tree/node/action/do_melee_attack
	my_action = /bt_action/do_melee_attack

/datum/behavior_tree/node/action/do_ranged_attack
	my_action = /bt_action/do_ranged_attack

/datum/behavior_tree/node/action/clear_target
	my_action = /bt_action/clear_target

/datum/behavior_tree/node/action/has_valid_target
	my_action = /bt_action/has_valid_target

// Legacy Wrappers (Retained/remapped for compatibility)
/datum/behavior_tree/node/action/has_target_check
	my_action = /bt_action/has_valid_target // Remapped to new valid check

/datum/behavior_tree/node/action/find_target
	my_action = /bt_action/pick_best_target // Remapped

/datum/behavior_tree/node/action/maintain_distance
	my_action = /bt_action/maintain_distance

/datum/behavior_tree/node/action/flee_target
	my_action = /bt_action/flee_target

/datum/behavior_tree/node/action/target_in_range
	my_action = /bt_action/target_in_range

/datum/behavior_tree/node/action/idle_wander
	my_action = /bt_action/idle_wander

/datum/behavior_tree/node/action/attack_melee
	my_action = /bt_action/do_melee_attack // Remapped

/datum/behavior_tree/node/action/attack_ranged
	my_action = /bt_action/do_ranged_attack // Remapped

/datum/behavior_tree/node/action/move_to_target
	my_action = /bt_action/move_to_target

/datum/behavior_tree/node/action/move_to_dest
	my_action = /bt_action/move_to_destination

/datum/behavior_tree/node/action/find_food
	my_action = /bt_action/find_food

/datum/behavior_tree/node/action/eat_food
	my_action = /bt_action/eat_food

/datum/behavior_tree/node/action/check_hunger
	my_action = /bt_action/check_hunger

// ------------------------------------------------------------------------------
// SERVICE & OBSERVER WRAPPERS
// ------------------------------------------------------------------------------

/datum/behavior_tree/node/decorator/service/target_scanner/hostile
	search_objects = FALSE
	scan_range = 7

/datum/behavior_tree/node/decorator/service/target_scanner/hungry
	search_objects = TRUE
	scan_range = 7

/datum/behavior_tree/node/decorator/service/aggressor_manager/standard

/datum/behavior_tree/node/decorator/observer/aggressor_reaction/standard

/datum/behavior_tree/node/decorator/observer/pain_crit/standard

// ------------------------------------------------------------------------------
// REFACTORED SUB-TREES (SEQUENCES & SELECTORS)
// ------------------------------------------------------------------------------

// TARGET ACQUISITION
/datum/behavior_tree/node/selector/acquire_target
	my_nodes = list(
		/datum/behavior_tree/node/decorator/progress_validator/target_persistence/simple_has_target_wrapped,
		/datum/behavior_tree/node/action/switch_to_aggressor,
		/datum/behavior_tree/node/action/pick_best_target
	)

/datum/behavior_tree/node/decorator/progress_validator/target_persistence/simple_has_target_wrapped
	child = /datum/behavior_tree/node/action/has_valid_target
	persistence_time = 4 SECONDS

// ATTACK SEQUENCE
/datum/behavior_tree/node/sequence/attack_sequence
	my_nodes = list(
		/datum/behavior_tree/node/action/face_target,
		/datum/behavior_tree/node/action/target_in_range,
		/datum/behavior_tree/node/action/do_melee_attack
	)

// ENGAGE TARGET
/datum/behavior_tree/node/selector/engage_target
	my_nodes = list(
		/datum/behavior_tree/node/sequence/attack_sequence,
		/datum/behavior_tree/node/action/move_to_target,
		/datum/behavior_tree/node/sequence/simple_pursue_search
	)

// Pursue/Search Sequence
/datum/behavior_tree/node/sequence/simple_pursue_search
	my_nodes = list(
		/datum/behavior_tree/node/decorator/timeout/simple_pursue_last_known,
		/datum/behavior_tree/node/decorator/timeout/simple_search_area_wrapped
	)

// Wrappers for legacy/complex actions still used in pursue/search
/datum/behavior_tree/node/action/simple_animal_pursue_last_known_action
	my_action = /bt_action/simple_animal_pursue_last_known

/datum/behavior_tree/node/action/simple_animal_search_area_action
	my_action = /bt_action/simple_animal_search_area

/datum/behavior_tree/node/decorator/timeout/simple_pursue_last_known
	child = /datum/behavior_tree/node/action/simple_animal_pursue_last_known_action
	limit = 10 SECONDS

/datum/behavior_tree/node/decorator/timeout/simple_search_area_wrapped
	child = /datum/behavior_tree/node/action/simple_animal_search_area_action
	limit = 10 SECONDS

// COMBAT LOOP
/datum/behavior_tree/node/sequence/combat
	my_nodes = list(
		/datum/behavior_tree/node/selector/acquire_target,
		/datum/behavior_tree/node/selector/engage_target
	)

// IDLE LOOP
/datum/behavior_tree/node/sequence/idle
	my_nodes = list(
		/datum/behavior_tree/node/action/idle_wander
	)

// SCAVENGE LOOP
/datum/behavior_tree/node/sequence/scavenge
	my_nodes = list(
		/datum/behavior_tree/node/action/check_hunger,
		/datum/behavior_tree/node/action/find_food,
		/datum/behavior_tree/node/action/eat_food
	)

// ------------------------------------------------------------------------------
// SPECIALIZED SEQUENCES
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
		/datum/behavior_tree/node/sequence/attack_sequence, // Fallback
		/datum/behavior_tree/node/action/move_to_target
	)

/datum/behavior_tree/node/sequence/combat_ranged
	my_nodes = list(
		/datum/behavior_tree/node/selector/acquire_target,
		/datum/behavior_tree/node/selector/engage_target_ranged
	)

/datum/behavior_tree/node/sequence/idle_mimic
	my_nodes = list(
		/datum/behavior_tree/node/action/mimic_disguise,
		/datum/behavior_tree/node/action/find_target
	)

/datum/behavior_tree/node/sequence/combat_mimic
	my_nodes = list(
		/datum/behavior_tree/node/selector/acquire_target,
		/datum/behavior_tree/node/action/mimic_undisguise,
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

/datum/behavior_tree/node/sequence/attack_sequence_spacing
	my_nodes = list(
		/datum/behavior_tree/node/action/maintain_distance,
		/datum/behavior_tree/node/action/target_in_range,
		/datum/behavior_tree/node/action/attack_melee
	)

/datum/behavior_tree/node/selector/engage_target_skeleton
	my_nodes = list(
		/datum/behavior_tree/node/sequence/attack_sequence_spacing,
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
		/datum/behavior_tree/node/action/call_reinforcements,
		/datum/behavior_tree/node/selector/engage_target_orc
	)

/datum/behavior_tree/node/sequence/combat_volf
	my_nodes = list(
		/datum/behavior_tree/node/selector/acquire_target,
		/datum/behavior_tree/node/action/call_reinforcements,
		/datum/behavior_tree/node/selector/engage_target
	)

// ------------------------------------------------------------------------------
// HOSTILE TREE WRAPPERS (SERVICES APPLIED)
// ------------------------------------------------------------------------------

// GENERIC HOSTILE
/datum/behavior_tree/node/selector/generic_hostile_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hostile
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/standard/hostile_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/standard/hostile_wrapper
	child = /datum/behavior_tree/node/selector/generic_hostile_tree_logic

/datum/behavior_tree/node/selector/generic_hostile_tree_logic
	my_nodes = list(
		/datum/behavior_tree/node/decorator/observer/aggressor_reaction/standard/reaction_wrapper,
		/datum/behavior_tree/node/decorator/observer/pain_crit/standard/flee_wrapper, // Add Pain Fleeing
		/datum/behavior_tree/node/sequence/combat,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/idle
	)

// Dummy Wrappers for Observers (Interrupts logic flow if triggered)
/datum/behavior_tree/node/decorator/observer/aggressor_reaction/standard/reaction_wrapper
	child = /datum/behavior_tree/node/action/clear_target // Force re-eval

/datum/behavior_tree/node/decorator/observer/pain_crit/standard/flee_wrapper
	child = /datum/behavior_tree/node/action/flee_target // Run away!

// GENERIC HUNGRY HOSTILE
/datum/behavior_tree/node/selector/generic_hungry_hostile_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hungry
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/standard/hungry_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/standard/hungry_wrapper
	child = /datum/behavior_tree/node/selector/generic_hungry_logic

/datum/behavior_tree/node/selector/generic_hungry_logic
	my_nodes = list(
		/datum/behavior_tree/node/decorator/observer/aggressor_reaction/standard/reaction_wrapper,
		/datum/behavior_tree/node/sequence/combat,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/scavenge,
		/datum/behavior_tree/node/sequence/idle
	)

// GENERIC FRIENDLY (Just needs aggressor manager maybe? Or minimal scanner)
// Friendly usually means "defends owner" or "flees" or "wanders"
/datum/behavior_tree/node/selector/generic_friendly_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hostile // Scan for threats
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/standard/friendly_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/standard/friendly_wrapper
	child = /datum/behavior_tree/node/selector/generic_friendly_logic

/datum/behavior_tree/node/selector/generic_friendly_logic
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/scavenge,
		/datum/behavior_tree/node/sequence/idle
	)

// ------------------------------------------------------------------------------
// SPECIALIZED TREES (WRAPPED)
// ------------------------------------------------------------------------------

// DIREBEAR
/datum/behavior_tree/node/selector/direbear_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hungry
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/standard/direbear_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/standard/direbear_wrapper
	child = /datum/behavior_tree/node/selector/direbear_logic

/datum/behavior_tree/node/selector/direbear_logic
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat_direbear,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/scavenge,
		/datum/behavior_tree/node/sequence/idle
	)

// DEEPONE MELEE
/datum/behavior_tree/node/selector/deepone_melee_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hostile
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/standard/deepone_melee_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/standard/deepone_melee_wrapper
	child = /datum/behavior_tree/node/selector/deepone_melee_logic

/datum/behavior_tree/node/selector/deepone_melee_logic
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/idle
	)

// DEEPONE RANGED
/datum/behavior_tree/node/selector/deepone_ranged_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hostile
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/standard/deepone_ranged_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/standard/deepone_ranged_wrapper
	child = /datum/behavior_tree/node/selector/deepone_ranged_logic

/datum/behavior_tree/node/selector/deepone_ranged_logic
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat_ranged,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/idle
	)

// HAUNT
/datum/behavior_tree/node/selector/haunt_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hostile
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/standard/haunt_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/standard/haunt_wrapper
	child = /datum/behavior_tree/node/selector/haunt_logic

/datum/behavior_tree/node/selector/haunt_logic
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/idle
	)

// MIMIC
/datum/behavior_tree/node/selector/mimic_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hungry
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/standard/mimic_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/standard/mimic_wrapper
	child = /datum/behavior_tree/node/selector/mimic_logic

/datum/behavior_tree/node/selector/mimic_logic
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat_mimic,
		/datum/behavior_tree/node/sequence/scavenge,
		/datum/behavior_tree/node/sequence/idle_mimic
	)

// DREAMFIEND
/datum/behavior_tree/node/selector/dreamfiend_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hostile
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/standard/dreamfiend_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/standard/dreamfiend_wrapper
	child = /datum/behavior_tree/node/selector/dreamfiend_logic

/datum/behavior_tree/node/selector/dreamfiend_logic
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat_dreamfiend,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/idle
	)

// SKELETON
/datum/behavior_tree/node/selector/skeleton_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hostile
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/standard/skeleton_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/standard/skeleton_wrapper
	child = /datum/behavior_tree/node/selector/skeleton_logic

/datum/behavior_tree/node/selector/skeleton_logic
	my_nodes = list(
		/datum/behavior_tree/node/action/minion_follow,
		/datum/behavior_tree/node/sequence/combat_skeleton,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/idle
	)

// ORC
/datum/behavior_tree/node/selector/orc_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hostile
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/standard/orc_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/standard/orc_wrapper
	child = /datum/behavior_tree/node/selector/orc_logic

/datum/behavior_tree/node/selector/orc_logic
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat_orc,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/idle
	)

// VOLF
/datum/behavior_tree/node/selector/volf_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hungry
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/standard/volf_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/standard/volf_wrapper
	child = /datum/behavior_tree/node/selector/volf_logic

/datum/behavior_tree/node/selector/volf_logic
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat_volf,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/idle
	)

// SUMMONS (Colossus, Behemoth, etc)
// Assuming they use target scanner too (to find stuff to smash/kill)

/datum/behavior_tree/node/selector/colossus_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hostile
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/standard/colossus_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/standard/colossus_wrapper
	child = /datum/behavior_tree/node/selector/colossus_logic

/datum/behavior_tree/node/selector/colossus_logic
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat_colossus,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/idle
	)

/datum/behavior_tree/node/selector/behemoth_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hostile
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/standard/behemoth_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/standard/behemoth_wrapper
	child = /datum/behavior_tree/node/selector/behemoth_logic

/datum/behavior_tree/node/selector/behemoth_logic
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat_behemoth,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/idle
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

/datum/behavior_tree/node/selector/leyline_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hostile
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/standard/leyline_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/standard/leyline_wrapper
	child = /datum/behavior_tree/node/selector/leyline_logic

/datum/behavior_tree/node/selector/leyline_logic
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat_leyline,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/idle
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

/datum/behavior_tree/node/selector/obelisk_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hostile
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/standard/obelisk_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/standard/obelisk_wrapper
	child = /datum/behavior_tree/node/selector/obelisk_logic

/datum/behavior_tree/node/selector/obelisk_logic
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat_obelisk,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/idle
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

/datum/behavior_tree/node/selector/dryad_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hostile
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/standard/dryad_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/standard/dryad_wrapper
	child = /datum/behavior_tree/node/selector/dryad_logic

/datum/behavior_tree/node/selector/dryad_logic
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat_dryad,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/idle
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

// CHICKEN
/datum/behavior_tree/node/selector/chicken_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hungry
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/standard/chicken_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/standard/chicken_wrapper
	child = /datum/behavior_tree/node/selector/chicken_logic

/datum/behavior_tree/node/selector/chicken_logic
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/chicken_egg_laying,
		/datum/behavior_tree/node/sequence/idle
	)

// MIRESPIDER
/datum/behavior_tree/node/selector/mirespider_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hungry
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/standard/mirespider_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/standard/mirespider_wrapper
	child = /datum/behavior_tree/node/selector/mirespider_logic

/datum/behavior_tree/node/selector/mirespider_logic
	my_nodes = list(
		/datum/behavior_tree/node/action/minion_follow,
		/datum/behavior_tree/node/sequence/combat,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/idle
	)

// MOSSBACK
/datum/behavior_tree/node/selector/mossback_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hungry
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/standard/mossback_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/standard/mossback_wrapper
	child = /datum/behavior_tree/node/selector/mossback_logic

/datum/behavior_tree/node/selector/mossback_logic
	my_nodes = list(
		/datum/behavior_tree/node/action/minion_follow,
		/datum/behavior_tree/node/sequence/combat,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/idle
	)

// WOLF UNDEAD (Uses deadite_migrate)
/datum/behavior_tree/node/selector/wolf_undead_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hostile
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/standard/wolf_undead_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/standard/wolf_undead_wrapper
	child = /datum/behavior_tree/node/selector/wolf_undead_logic

/datum/behavior_tree/node/selector/wolf_undead_logic
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat,
		/datum/behavior_tree/node/action/deadite_migrate,
		/datum/behavior_tree/node/action/move_to_dest,
		/datum/behavior_tree/node/sequence/idle
	)

// INSANE CLOWN (Just acquire target, rest handled by mob?)
/datum/behavior_tree/node/selector/insane_clown_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hostile
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/standard/clown_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/standard/clown_wrapper
	child = /datum/behavior_tree/node/selector/insane_clown_logic

/datum/behavior_tree/node/selector/insane_clown_logic
	my_nodes = list(
		/datum/behavior_tree/node/selector/acquire_target,
		/datum/behavior_tree/node/sequence/idle
	)

// ------------------------------------------------------------------------------
// LEFTOVER WRAPPERS / HELPER NODES
// ------------------------------------------------------------------------------

/datum/behavior_tree/node/action/simple_animal_check_aggressors_action
	my_action = /bt_action/simple_animal_check_aggressors

/datum/behavior_tree/node/action/simple_animal_pursue_last_known_action
	my_action = /bt_action/simple_animal_pursue_last_known

/datum/behavior_tree/node/action/simple_animal_search_area_action
	my_action = /bt_action/simple_animal_search_area

/datum/behavior_tree/node/action/minion_follow
	my_action = /bt_action/minion_follow

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

/datum/behavior_tree/node/action/mimic_disguise
	my_action = /bt_action/mimic_disguise

/datum/behavior_tree/node/action/mimic_undisguise
	my_action = /bt_action/mimic_undisguise

/datum/behavior_tree/node/action/dreamfiend_blink
	my_action = /bt_action/dreamfiend_blink

/datum/behavior_tree/node/action/use_ability
	my_action = /bt_action/use_ability

/datum/behavior_tree/node/action/call_reinforcements
	my_action = /bt_action/call_reinforcements