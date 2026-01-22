// ==============================================================================
// CARBON/HUMAN BEHAVIOR TREES
// ==============================================================================

// ------------------------------------------------------------------------------
// HOSTILE HUMANOID TREE (for bandits, guards, etc.)
// ------------------------------------------------------------------------------

/datum/behavior_tree/node/selector/hostile_humanoid_tree
	my_nodes = list(
		/datum/behavior_tree/node/sequence/humanoid_combat,
		/datum/behavior_tree/node/sequence/humanoid_idle
	)

/datum/behavior_tree/node/sequence/humanoid_combat
	my_nodes = list(
		/datum/behavior_tree/node/selector/humanoid_acquire_target,
		/datum/behavior_tree/node/selector/humanoid_handle_combat
	)

/datum/behavior_tree/node/selector/humanoid_acquire_target
	my_nodes = list(
		/datum/behavior_tree/node/action/carbon_has_target,
		/datum/behavior_tree/node/action/carbon_find_target
	)

/datum/behavior_tree/node/selector/humanoid_handle_combat
	my_nodes = list(
		/datum/behavior_tree/node/sequence/humanoid_flee_sequence,
		/datum/behavior_tree/node/sequence/humanoid_attack_sequence,
		/datum/behavior_tree/node/action/carbon_move_to_target
	)

// ------------------------------------------------------------------------------
// GOBLIN TREE
// ------------------------------------------------------------------------------

/datum/behavior_tree/node/selector/goblin_tree
	my_nodes = list(
		/datum/behavior_tree/node/sequence/goblin_combat,
		/datum/behavior_tree/node/sequence/humanoid_idle
	)

/datum/behavior_tree/node/sequence/goblin_combat
	my_nodes = list(
		/datum/behavior_tree/node/action/goblin_squad_coordination,
		/datum/behavior_tree/node/selector/humanoid_acquire_target,
		/datum/behavior_tree/node/selector/goblin_handle_combat
	)

/datum/behavior_tree/node/selector/goblin_handle_combat
	my_nodes = list(
		/datum/behavior_tree/node/sequence/humanoid_flee_sequence,
		/datum/behavior_tree/node/sequence/goblin_subdue_sequence,
		/datum/behavior_tree/node/action/goblin_attack_check{invert = TRUE},
		/datum/behavior_tree/node/sequence/humanoid_attack_sequence,
		/datum/behavior_tree/node/action/carbon_move_to_target
	)

/datum/behavior_tree/node/sequence/goblin_subdue_sequence
	my_nodes = list(
		/datum/behavior_tree/node/action/carbon_check_monster_bait,
		/datum/behavior_tree/node/action/carbon_subdue_target,
		/datum/behavior_tree/node/action/goblin_disarm,
		/datum/behavior_tree/node/action/goblin_drag_away,
		/datum/behavior_tree/node/action/carbon_violate_target,
		/datum/behavior_tree/node/action/goblin_post_violate
	)

/datum/behavior_tree/node/sequence/humanoid_flee_sequence
	my_nodes = list(
		/datum/behavior_tree/node/action/carbon_should_flee,
		/datum/behavior_tree/node/action/carbon_flee
	)

/datum/behavior_tree/node/sequence/humanoid_subdue_sequence
	my_nodes = list(
		/datum/behavior_tree/node/action/carbon_check_monster_bait,
		/datum/behavior_tree/node/action/carbon_subdue_target,
		/datum/behavior_tree/node/action/carbon_violate_target
	)

/datum/behavior_tree/node/sequence/humanoid_attack_sequence
	my_nodes = list(
		/datum/behavior_tree/node/action/carbon_target_in_range,
		/datum/behavior_tree/node/action/carbon_equip_weapon,
		/datum/behavior_tree/node/action/carbon_attack_melee
	)

/datum/behavior_tree/node/sequence/humanoid_idle
	my_nodes = list(
		/datum/behavior_tree/node/action/carbon_idle_wander
	)

// ------------------------------------------------------------------------------
// NODE WRAPPERS FOR CARBON ACTIONS
// ------------------------------------------------------------------------------

/datum/behavior_tree/node/action/carbon_has_target
	my_action = /bt_action/carbon_has_target

/datum/behavior_tree/node/action/carbon_find_target
	my_action = /bt_action/carbon_find_target

/datum/behavior_tree/node/action/carbon_move_to_target
	my_action = /bt_action/carbon_move_to_target

/datum/behavior_tree/node/action/carbon_idle_wander
	my_action = /bt_action/carbon_idle_wander

/datum/behavior_tree/node/action/carbon_attack_melee
	my_action = /bt_action/carbon_attack_melee

/datum/behavior_tree/node/action/carbon_target_in_range
	my_action = /bt_action/carbon_target_in_range

/datum/behavior_tree/node/action/carbon_target_in_range/New()
	. = ..()
	var/bt_action/target_in_range/action = my_action
	if(istype(action))
		action.range = 1

/datum/behavior_tree/node/action/carbon_equip_weapon
	my_action = /bt_action/carbon_equip_weapon

/datum/behavior_tree/node/action/carbon_should_flee
	my_action = /bt_action/carbon_should_flee

/datum/behavior_tree/node/action/carbon_flee
	my_action = /bt_action/carbon_flee

/datum/behavior_tree/node/action/carbon_check_monster_bait
	my_action = /bt_action/carbon_check_monster_bait

/datum/behavior_tree/node/action/carbon_subdue_target
	my_action = /bt_action/carbon_subdue_target

/datum/behavior_tree/node/action/carbon_violate_target
	my_action = /bt_action/carbon_violate_target

/datum/behavior_tree/node/action/goblin_attack_check
	my_action = /bt_action/goblin_attack_check

/datum/behavior_tree/node/action/goblin_squad_coordination
	my_action = /bt_action/goblin_squad_coordination

/datum/behavior_tree/node/action/goblin_drag_away
	my_action = /bt_action/goblin_drag_away

/datum/behavior_tree/node/action/goblin_post_violate
	my_action = /bt_action/goblin_post_violate

/datum/behavior_tree/node/action/goblin_disarm
	my_action = /bt_action/goblin_disarm
