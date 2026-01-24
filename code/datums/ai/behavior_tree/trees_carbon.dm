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
		/datum/behavior_tree/node/decorator/progress_validator/target_persistence/has_target_wrapped,
		/datum/behavior_tree/node/action/carbon_check_aggressors,
		/datum/behavior_tree/node/decorator/retry/find_target_wrapped
	)

// Wrap has_target in target_persistence decorator
// This gives the NPC 4 seconds to "remember" a target after losing sight
/datum/behavior_tree/node/decorator/progress_validator/target_persistence/has_target_wrapped
	child = /datum/behavior_tree/node/action/carbon_has_target
	persistence_time = 4 SECONDS

// Wrap find_target in retry decorator
// This prevents spamming target searches every tick
/datum/behavior_tree/node/decorator/retry/find_target_wrapped
	child = /datum/behavior_tree/node/action/carbon_find_target
	cooldown = 2 SECONDS
	max_failures = 1

/datum/behavior_tree/node/selector/humanoid_handle_combat
	my_nodes = list(
		/datum/behavior_tree/node/sequence/humanoid_flee_sequence,
		/datum/behavior_tree/node/sequence/humanoid_attack_sequence,
		/datum/behavior_tree/node/action/carbon_move_to_target,
		/datum/behavior_tree/node/sequence/humanoid_pursue_search
	)

// Pursue and search sequence - runs when we've lost the target
/datum/behavior_tree/node/sequence/humanoid_pursue_search
	my_nodes = list(
		/datum/behavior_tree/node/decorator/timeout/pursue_last_known,
		/datum/behavior_tree/node/decorator/timeout/search_area_wrapped
	)

// Pursue to last known location with 10 second timeout
/datum/behavior_tree/node/decorator/timeout/pursue_last_known
	child = /datum/behavior_tree/node/action/carbon_pursue_last_known
	limit = 10 SECONDS

// Search area with 10 second timeout
/datum/behavior_tree/node/decorator/timeout/search_area_wrapped
	child = /datum/behavior_tree/node/action/carbon_search_area
	limit = 10 SECONDS

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
		/datum/behavior_tree/node/decorator/cooldown/goblin_cleanup_wrapper{cooldown_time = 2 SECONDS},
		/datum/behavior_tree/node/action/goblin_squad_coordination,
		/datum/behavior_tree/node/selector/humanoid_acquire_target,
		/datum/behavior_tree/node/selector/goblin_handle_combat
	)

// Wrapper to run cleanup on cooldown (every 2 seconds)
/datum/behavior_tree/node/decorator/cooldown/goblin_cleanup_wrapper
	child = /datum/behavior_tree/node/action/goblin_cleanup_squad_state

/datum/behavior_tree/node/selector/goblin_handle_combat
	my_nodes = list(
		/datum/behavior_tree/node/sequence/humanoid_flee_sequence,
		/datum/behavior_tree/node/sequence/goblin_squad_tactics,
		/datum/behavior_tree/node/sequence/goblin_subdue_sequence, // Fallback for solo goblins
		/datum/behavior_tree/node/action/goblin_attack_check{invert = TRUE},
		/datum/behavior_tree/node/sequence/humanoid_attack_sequence,
		/datum/behavior_tree/node/action/carbon_move_to_target
	)

// Squad tactics sequence - used when goblin has a squad role
/datum/behavior_tree/node/sequence/goblin_squad_tactics
	my_nodes = list(
		/datum/behavior_tree/node/action/goblin_has_squad_role, // Check if we have a role
		/datum/behavior_tree/node/action/goblin_surround_target_action,
		/datum/behavior_tree/node/selector/goblin_role_actions
	)

// Role-based action selector
/datum/behavior_tree/node/selector/goblin_role_actions
	my_nodes = list(
		/datum/behavior_tree/node/sequence/goblin_restrainer_actions,
		/datum/behavior_tree/node/sequence/goblin_stripper_actions,
		/datum/behavior_tree/node/sequence/goblin_violator_actions,
		/datum/behavior_tree/node/sequence/goblin_attacker_actions
	)

// Restrainer pins the target
/datum/behavior_tree/node/sequence/goblin_restrainer_actions
	my_nodes = list(
		/datum/behavior_tree/node/action/goblin_is_restrainer,
		/datum/behavior_tree/node/action/goblin_restrain_target_action
	)

// Stripper removes equipment
/datum/behavior_tree/node/sequence/goblin_stripper_actions
	my_nodes = list(
		/datum/behavior_tree/node/action/goblin_is_stripper,
		/datum/behavior_tree/node/selector/goblin_strip_selector
	)

/datum/behavior_tree/node/selector/goblin_strip_selector
	my_nodes = list(
		/datum/behavior_tree/node/action/goblin_strip_armor_action, // For normal enemies
		/datum/behavior_tree/node/action/goblin_disarm // For MONSTER_BAIT (weapons)
	)

// Violator handles violation
/datum/behavior_tree/node/sequence/goblin_violator_actions
	my_nodes = list(
		/datum/behavior_tree/node/action/goblin_is_violator,
		/datum/behavior_tree/node/action/goblin_squad_violate_action
	)

// Attacker handles combat
/datum/behavior_tree/node/sequence/goblin_attacker_actions
	my_nodes = list(
		/datum/behavior_tree/node/action/goblin_is_attacker,
		/datum/behavior_tree/node/action/goblin_attack_vitals_action
	)

// subdue sequence for solo goblins
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

/datum/behavior_tree/node/action/carbon_check_aggressors
	my_action = /bt_action/carbon_check_aggressors

/datum/behavior_tree/node/action/carbon_pursue_last_known
	my_action = /bt_action/carbon_pursue_last_known

/datum/behavior_tree/node/action/carbon_search_area
	my_action = /bt_action/carbon_search_area

// ------------------------------------------------------------------------------
// GOBLIN SQUAD TACTICS NODE WRAPPERS
// ------------------------------------------------------------------------------

/datum/behavior_tree/node/action/goblin_has_squad_role
	my_action = /bt_action/goblin_has_squad_role

/datum/behavior_tree/node/action/goblin_is_restrainer
	my_action = /bt_action/goblin_is_restrainer

/datum/behavior_tree/node/action/goblin_is_stripper
	my_action = /bt_action/goblin_is_stripper

/datum/behavior_tree/node/action/goblin_is_violator
	my_action = /bt_action/goblin_is_violator

/datum/behavior_tree/node/action/goblin_is_attacker
	my_action = /bt_action/goblin_is_attacker

/datum/behavior_tree/node/action/goblin_surround_target_action
	my_action = /bt_action/goblin_surround_target

/datum/behavior_tree/node/action/goblin_restrain_target_action
	my_action = /bt_action/goblin_restrain_target

/datum/behavior_tree/node/action/goblin_strip_armor_action
	my_action = /bt_action/goblin_strip_armor

/datum/behavior_tree/node/action/goblin_attack_vitals_action
	my_action = /bt_action/goblin_attack_vitals

/datum/behavior_tree/node/action/goblin_squad_violate_action
	my_action = /bt_action/goblin_squad_violate

/datum/behavior_tree/node/action/goblin_cleanup_squad_state
	my_action = /bt_action/goblin_cleanup_squad_state
