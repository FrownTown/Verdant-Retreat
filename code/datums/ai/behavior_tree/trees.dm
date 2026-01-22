// ==============================================================================
// BEHAVIOR TREES AND ACTION NODES
// ==============================================================================

// == // Actions Nodes // == //
//=============================
// Please keep alphabetical
// ACTION NODES //

// movement actions
/datum/behavior_tree/node/action/check_move_valid
	my_action = /bt_action/check_move_valid

/datum/behavior_tree/node/action/check_has_path
	my_action = /bt_action/check_has_path

/datum/behavior_tree/node/action/process_movement
	my_action = /bt_action/process_movement

// STUCK SENSOR FOR MOVEMENT
/datum/behavior_tree/node/decorator/progress_validator/stuck_sensor/movement
	child = /datum/behavior_tree/node/action/process_movement
	stuck_limit = 5 SECONDS

// RETRY WRAPPER FOR MOVEMENT
/datum/behavior_tree/node/decorator/retry/movement
	child = /datum/behavior_tree/node/decorator/progress_validator/stuck_sensor/movement
	cooldown = 5 SECONDS
	max_failures = 3

/datum/behavior_tree/node/sequence/movement_tree
	my_nodes = list(
		/datum/behavior_tree/node/action/check_move_valid,
		/datum/behavior_tree/node/action/check_has_path,
		/datum/behavior_tree/node/decorator/retry/movement
	)

/datum/behavior_tree/node/parallel/root // parallel node wrapper for the main + movement sequences

/datum/behavior_tree/node/parallel/root/New(typepath, mob/owner)

	main_node = new /datum/behavior_tree/node/sequence/main(typepath)
	move_node = new /datum/behavior_tree/node/sequence/movement_tree()
	my_nodes = list(main_node, move_node)

// Main sequence wrapper for the main AI tree, used so we can separately check for think and move cooldowns
/datum/behavior_tree/node/sequence/main
	my_nodes = list(/datum/behavior_tree/node/action/check_think_valid)

/datum/behavior_tree/node/sequence/main/New(typepath)
	my_nodes += typepath
	..()

/datum/behavior_tree/node/action/check_think_valid
	my_action = /bt_action/check_think_valid
