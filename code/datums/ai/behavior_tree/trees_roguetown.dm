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
		/datum/behavior_tree/node/action/has_target_check,
		/datum/behavior_tree/node/action/find_target
	)

/datum/behavior_tree/node/selector/engage_target
	my_nodes = list(
		/datum/behavior_tree/node/sequence/attack_sequence,
		/datum/behavior_tree/node/action/move_to_target
	)

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
