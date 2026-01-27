// ==============================================================================
// CARBON/HUMAN BEHAVIOR TREES (REFACTORED)
// ==============================================================================

// ------------------------------------------------------------------------------
// NODE WRAPPERS FOR ATOMIZED ACTIONS
// ------------------------------------------------------------------------------

/datum/behavior_tree/node/action/ensure_blunt_weapon
	my_action = /bt_action/ensure_blunt_weapon

/datum/behavior_tree/node/action/knockdown_target
	my_action = /bt_action/knockdown_target

/datum/behavior_tree/node/action/grapple_target
	my_action = /bt_action/grapple_target

/datum/behavior_tree/node/action/upgrade_grapple
	my_action = /bt_action/upgrade_grapple

/datum/behavior_tree/node/action/pin_target
	my_action = /bt_action/pin_target

/datum/behavior_tree/node/action/cuff_target
	my_action = /bt_action/cuff_target

/datum/behavior_tree/node/action/strip_victim
	my_action = /bt_action/strip_victim

/datum/behavior_tree/node/action/position_for_sex
	my_action = /bt_action/position_for_sex

/datum/behavior_tree/node/action/start_sex
	my_action = /bt_action/start_sex

/datum/behavior_tree/node/action/continue_sex
	my_action = /bt_action/continue_sex

// ------------------------------------------------------------------------------
// SUBDUE & VIOLATE SEQUENCES
// ------------------------------------------------------------------------------

// Subdue Logic (Inverse Priority: Goal -> Prereqs)
/datum/behavior_tree/node/sequence/subdue_logic
	my_nodes = list(
		/datum/behavior_tree/node/action/ensure_blunt_weapon,
		/datum/behavior_tree/node/selector/subdue_steps
	)

/datum/behavior_tree/node/selector/subdue_steps
	my_nodes = list(
		/datum/behavior_tree/node/action/cuff_target,      // Goal: Restrained
		/datum/behavior_tree/node/action/pin_target,       // Prereq: Pinned
		/datum/behavior_tree/node/action/upgrade_grapple,  // Prereq: Aggressive Grab
		/datum/behavior_tree/node/action/grapple_target,   // Prereq: Grabbed
		/datum/behavior_tree/node/action/knockdown_target, // Prereq: Downed
		/datum/behavior_tree/node/action/carbon_move_to_target // Prereq: Adjacent
	)

// Violate Logic
/datum/behavior_tree/node/sequence/violate_logic
	my_nodes = list(
		/datum/behavior_tree/node/action/position_for_sex,
		/datum/behavior_tree/node/action/strip_victim,
		/datum/behavior_tree/node/action/start_sex,
		/datum/behavior_tree/node/action/continue_sex
	)

// ------------------------------------------------------------------------------
// HOSTILE HUMANOID TREE (for bandits, guards, etc.)
// ------------------------------------------------------------------------------

/datum/behavior_tree/node/decorator/service/target_scanner/hostile/hostile_humanoid_tree
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/standard/hostile_humanoid_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/standard/hostile_humanoid_wrapper
	child = /datum/behavior_tree/node/selector/hostile_humanoid_logic

/datum/behavior_tree/node/selector/hostile_humanoid_tree
	// Legacy type mapping for init_ai_root
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hostile/hostile_humanoid_tree

/datum/behavior_tree/node/selector/hostile_humanoid_logic
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
		/datum/behavior_tree/node/action/switch_to_aggressor, // Use atomized switch action
		/datum/behavior_tree/node/decorator/retry/find_target_wrapped
	)

// Wrap has_target in target_persistence decorator
/datum/behavior_tree/node/decorator/progress_validator/target_persistence/has_target_wrapped
	child = /datum/behavior_tree/node/action/carbon_has_target
	persistence_time = 4 SECONDS

// Wrap find_target in retry decorator
/datum/behavior_tree/node/decorator/retry/find_target_wrapped
	child = /datum/behavior_tree/node/action/pick_best_target // Use atomized pick action (uses scanner service)
	cooldown = 2 SECONDS
	max_failures = 1

/datum/behavior_tree/node/selector/humanoid_handle_combat
	my_nodes = list(
		/datum/behavior_tree/node/sequence/humanoid_flee_sequence,
		/datum/behavior_tree/node/sequence/humanoid_attack_sequence,
		/datum/behavior_tree/node/action/carbon_move_to_target,
		/datum/behavior_tree/node/sequence/humanoid_pursue_search
	)

// Pursue and search sequence
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

/datum/behavior_tree/node/decorator/service/target_scanner/hostile/goblin_tree
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/standard/goblin_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/standard/goblin_wrapper
	child = /datum/behavior_tree/node/selector/goblin_logic

/datum/behavior_tree/node/selector/goblin_tree
	// Legacy type mapping
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hostile/goblin_tree

/datum/behavior_tree/node/selector/goblin_logic
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

// Squad tactics sequence
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

// Restrainer pins the target first
/datum/behavior_tree/node/sequence/goblin_restrainer_actions
	my_nodes = list(
		/datum/behavior_tree/node/action/goblin_is_restrainer,
		/datum/behavior_tree/node/selector/goblin_restrain_sequence, // Use new selector
		/datum/behavior_tree/node/action/goblin_squad_violate_action
	)

// Goblin Restrain Logic (Selector: Maintain -> Pin -> Tackle -> Upgrade -> Grab)
/datum/behavior_tree/node/selector/goblin_restrain_sequence
	my_nodes = list(
		/datum/behavior_tree/node/action/goblin_maintain_pin_action,
		/datum/behavior_tree/node/action/goblin_pin_target_action,
		/datum/behavior_tree/node/action/goblin_tackle_target_action,
		/datum/behavior_tree/node/action/goblin_upgrade_grab_action,
		/datum/behavior_tree/node/action/goblin_grab_target_action
	)

// Stripper removes equipment or assists with restraint
/datum/behavior_tree/node/sequence/goblin_stripper_actions
	my_nodes = list(
		/datum/behavior_tree/node/action/goblin_is_stripper,
		/datum/behavior_tree/node/selector/goblin_stripper_selector
	)

/datum/behavior_tree/node/selector/goblin_stripper_selector
	my_nodes = list(
		/datum/behavior_tree/node/action/goblin_assist_restrain_action, // Help restrain MONSTER_BAIT first
		/datum/behavior_tree/node/action/goblin_strip_armor_action, // For normal enemies
		/datum/behavior_tree/node/action/goblin_disarm // For MONSTER_BAIT (weapons)
	)

// Violator handles violation or assists with restraint
/datum/behavior_tree/node/sequence/goblin_violator_actions
	my_nodes = list(
		/datum/behavior_tree/node/action/goblin_is_violator,
		/datum/behavior_tree/node/selector/goblin_violator_selector
	)

/datum/behavior_tree/node/selector/goblin_violator_selector
	my_nodes = list(
		/datum/behavior_tree/node/action/goblin_assist_restrain_action, // Help restrain MONSTER_BAIT first
		/datum/behavior_tree/node/action/goblin_squad_violate_action
	)

// Attacker handles combat or assists with restraint
/datum/behavior_tree/node/sequence/goblin_attacker_actions
	my_nodes = list(
		/datum/behavior_tree/node/action/goblin_is_attacker,
		/datum/behavior_tree/node/selector/goblin_attacker_selector
	)

// Attacker selector: try to assist with MONSTER_BAIT restraint, otherwise attack
/datum/behavior_tree/node/selector/goblin_attacker_selector
	my_nodes = list(
		/datum/behavior_tree/node/action/goblin_assist_restrain_action,
		/datum/behavior_tree/node/action/goblin_attack_vitals_action
	)

// subdue sequence for solo goblins (UPDATED with Atomized Logic)
/datum/behavior_tree/node/sequence/goblin_subdue_sequence
	my_nodes = list(
		/datum/behavior_tree/node/action/carbon_check_monster_bait,
		/datum/behavior_tree/node/sequence/subdue_logic, // Use new atomized subdue
		/datum/behavior_tree/node/action/goblin_disarm,
		/datum/behavior_tree/node/action/goblin_drag_away,
		/datum/behavior_tree/node/sequence/violate_logic, // Use new atomized violate
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
		/datum/behavior_tree/node/sequence/subdue_logic, // Use new atomized subdue
		/datum/behavior_tree/node/sequence/violate_logic  // Use new atomized violate
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

/datum/behavior_tree/node/action/goblin_assist_restrain_action
	my_action = /bt_action/goblin_assist_restrain

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

/datum/behavior_tree/node/action/goblin_maintain_pin_action
	my_action = /bt_action/goblin_maintain_pin

/datum/behavior_tree/node/action/goblin_pin_target_action
	my_action = /bt_action/goblin_pin_target

/datum/behavior_tree/node/action/goblin_tackle_target_action
	my_action = /bt_action/goblin_tackle_target

/datum/behavior_tree/node/action/goblin_upgrade_grab_action
	my_action = /bt_action/goblin_upgrade_grab

/datum/behavior_tree/node/action/goblin_grab_target_action
	my_action = /bt_action/goblin_grab_target

/datum/behavior_tree/node/action/goblin_strip_armor_action
	my_action = /bt_action/goblin_strip_armor

/datum/behavior_tree/node/action/goblin_attack_vitals_action
	my_action = /bt_action/goblin_attack_vitals

/datum/behavior_tree/node/action/goblin_squad_violate_action
	my_action = /bt_action/goblin_squad_violate

/datum/behavior_tree/node/action/goblin_cleanup_squad_state
	my_action = /bt_action/goblin_cleanup_squad_state