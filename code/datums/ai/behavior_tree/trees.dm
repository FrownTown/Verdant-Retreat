// ==============================================================================
// BEHAVIOR TREES AND ACTION NODES
// ==============================================================================

// == // Actions Nodes // == //
//=============================
// Please keep alphabetical
// ACTION NODES //

// remember these are the nodes that go into the actual trees not the /actions types
// S declares action itself, no S for the trees. 

// aggro tick
/datum/behavior_tree/node/action/aggro_tick
	my_action = /datum/actions/aggro_tick

// attack target
/datum/behavior_tree/node/action/attack_target
	my_action = /datum/actions/attack_target

// break turf
/datum/behavior_tree/node/action/break_turf
	my_action = /datum/actions/break_turf

// break turf
/datum/behavior_tree/node/action/break_structures
	my_action = /datum/actions/break_structures


// call update sprite
/datum/behavior_tree/node/action/call_update_sprite
	my_action = /datum/actions/call_update_sprite

// check active
/datum/behavior_tree/node/action/check_active
	my_action = /datum/actions/check_active

// check burrowing
/datum/behavior_tree/node/action/check_burrowing
	my_action = /datum/actions/check_burrowing

// check has path
/datum/behavior_tree/node/action/check_has_path
	my_action = /datum/actions/check_has_path

// check inactive
/datum/behavior_tree/node/action/check_inactive
	my_action = /datum/actions/check_inactive

// check aggro
/datum/behavior_tree/node/action/check_aggro
	my_action = /datum/actions/check_aggro

// check approach
/datum/behavior_tree/node/action/check_approach
	my_action = /datum/actions/check_approach

// check dead
/datum/behavior_tree/node/action/check_dead
	my_action = /datum/actions/check_dead

// burrow
/datum/behavior_tree/node/action/burrow
	my_action = /datum/actions/burrow

// escape holder
/datum/behavior_tree/node/action/try_escape_holder
	my_action = /datum/actions/try_escape_holder

// check has attacked
/datum/behavior_tree/node/action/check_has_attacked
	my_action = /datum/actions/check_has_attacked

// check has current target
/datum/behavior_tree/node/action/check_has_current_target
	my_action = /datum/actions/check_has_current_target

// check held
/datum/behavior_tree/node/action/check_held
	my_action = /datum/actions/check_held

// check ideal range
/datum/behavior_tree/node/action/check_ideal_range
	my_action = /datum/actions/check_ideal_range

// check if mob
/datum/behavior_tree/node/action/check_if_mob
	my_action = /datum/actions/check_if_mob

// check melee distance
/datum/behavior_tree/node/action/check_melee_distance
	my_action = /datum/actions/check_melee_distance

// check on turf
/datum/behavior_tree/node/action/check_on_turf
	my_action = /datum/actions/check_on_turf

// check retreat
/datum/behavior_tree/node/action/check_retreat
	my_action = /datum/actions/check_retreat

// == CHARGING == //

// check charge rate
/datum/behavior_tree/node/action/check_charge_rate
	my_action = /datum/actions/check_charge_rate

// charge
/datum/behavior_tree/node/action/charge
	my_action = /datum/actions/charge

// reset charge
/datum/behavior_tree/node/action/reset_charge
	my_action = /datum/actions/reset_charge

// check turf blocked 
/datum/behavior_tree/node/action/check_turf_block
	my_action = /datum/actions/check_turf_block

// check structure blocked 
/datum/behavior_tree/node/action/check_structure_block
	my_action = /datum/actions/check_structure_block

// check target disarm intent
/datum/behavior_tree/node/action/check_target_disarm_intent
	my_action = /datum/actions/check_target_disarm_intent

// check target help intent
/datum/behavior_tree/node/action/check_target_help_intent
	my_action = /datum/actions/check_target_help_intent

// check tile luminosity
/datum/behavior_tree/node/action/check_tile_luminosity
	my_action = /datum/actions/check_tile_luminosity

// check time wait
/datum/behavior_tree/node/action/check_time_wait
	my_action = /datum/actions/check_time_wait

// deactivate
/datum/behavior_tree/node/action/deactivate
	my_action = /datum/actions/deactivate
// dodge
/datum/behavior_tree/node/action/dodge
	my_action = /datum/actions/dodge

/datum/behavior_tree/node/action/do_nothing
    my_action = /datum/actions/do_nothing

// find human
/datum/behavior_tree/node/action/find_any_human
	my_action = /datum/actions/find_any_human

// find human
/datum/behavior_tree/node/action/find_human
	my_action = /datum/actions/find_human

// find path
/datum/behavior_tree/node/action/find_path
	my_action = /datum/actions/find_path

// find top aggro
/datum/behavior_tree/node/action/find_top_aggro
	my_action = /datum/actions/find_top_aggro

// follow path
/datum/behavior_tree/node/action/follow_path
	my_action = /datum/actions/follow_path

// make sound
/datum/behavior_tree/node/action/make_sound
	my_action = /datum/actions/make_sound

// meander
/datum/behavior_tree/node/action/meander
	my_action = /datum/actions/meander

// move from target
/datum/behavior_tree/node/action/move_from_target
	my_action = /datum/actions/move_from_target

// move to target
/datum/behavior_tree/node/action/move_to_target
	my_action = /datum/actions/move_to_target


// remove dead targets
/datum/behavior_tree/node/action/remove_dead_targets
	my_action = /datum/actions/remove_dead_targets

// remove path
/datum/behavior_tree/node/action/remove_path
	my_action = /datum/actions/remove_path

// threaten target
/datum/behavior_tree/node/action/threaten_target
	my_action = /datum/actions/threaten_target

// unburrow
/datum/behavior_tree/node/action/unburrow
	my_action = /datum/actions/unburrow

// unset has attacked
/datum/behavior_tree/node/action/unset_has_attacked
	my_action = /datum/actions/unset_has_attacked

/datum/behavior_tree/node/action/check_same_z
	my_action = /datum/actions/check_same_Z

// BULLET HIT
//standard mob hit
/datum/behavior_tree/node/action/bullet_hit
	my_action = /datum/actions/bullet_hit

/datum/behavior_tree/node/action/handle_weapon_attack
	my_action = /datum/actions/handle_weapon_attack

/datum/behavior_tree/node/action/handle_human_touch
	my_action = /datum/actions/handle_human_touch

/datum/behavior_tree/node/action/update_overlay
	my_action = /datum/actions/update_overlay

/datum/behavior_tree/node/action/do_harvest
	my_action = /datum/actions/do_harvest

//Decision logic for critter.dm types but compatible with anything using nodes
//These actions make a lot of use of blackboard so you'll need that (see critter.dm to understand)
/* IMPORTANT NOTE!!!!
	- 	Critter blackboard lists use WEAKREF references to objects.
		use resolve() to get the actual object to asess its vars in the procs!!!
*/

// == // Selectors and Sequences // == //
//=======================================

// AGGRO TICK AND MEANDER //
//mobs currently only lose aggro when idling
/datum/behavior_tree/node/sequence/aggro_tick_meander
	my_nodes = list(
				/datum/behavior_tree/node/action/check_on_turf,
				/datum/behavior_tree/node/action/aggro_tick,
				/datum/behavior_tree/node/action/meander)

// APPROACH TARGET //
/datum/behavior_tree/node/sequence/approach_target
	my_nodes = list(
				/datum/behavior_tree/node/action/check_aggro,
				/datum/behavior_tree/node/action/check_approach )
// ATTACK //
/datum/behavior_tree/node/sequence/attack
	my_nodes = list(
				/datum/behavior_tree/node/action/check_has_attacked,
				/datum/behavior_tree/node/action/attack_target)

// ATTACK TARGET //
/datum/behavior_tree/node/sequence/attack_target
	my_nodes = list(
				/datum/behavior_tree/node/action/check_same_z, // can't attack something off the z level (for basic attacks)
				/datum/behavior_tree/node/action/check_ideal_range,
				/datum/behavior_tree/node/action/check_aggro,
				/datum/behavior_tree/node/action/check_has_attacked,
				/datum/behavior_tree/node/action/remove_path,
				/datum/behavior_tree/node/action/attack_target)

// SIMPLE ATTACK //
/datum/behavior_tree/node/sequence/simple_attack
	my_nodes = list(
				/datum/behavior_tree/node/action/check_ideal_range,
				/datum/behavior_tree/node/action/attack_target,
				/datum/behavior_tree/node/action/unset_has_attacked)

// AVOID TARGET //
/datum/behavior_tree/node/sequence/avoid_target
	my_nodes = list(
					/datum/behavior_tree/node/action/check_retreat,
					/datum/behavior_tree/node/action/check_on_turf,
					/datum/behavior_tree/node/action/unset_has_attacked,
					/datum/behavior_tree/node/action/move_from_target )

// BURROWING
/datum/behavior_tree/node/sequence/burrow
	my_nodes = list(
					/datum/behavior_tree/node/action/check_burrowing{invert = TRUE},
					/datum/behavior_tree/node/action/check_tile_luminosity,
					/datum/behavior_tree/node/action/burrow )
// UNBURROWING
/datum/behavior_tree/node/sequence/unburrow
	my_nodes = list(
					/datum/behavior_tree/node/action/check_burrowing,
					/datum/behavior_tree/node/action/check_tile_luminosity{invert = TRUE},  // remember: this returns opposite results (succes is failure)
					/datum/behavior_tree/node/action/unburrow)

// CHARGE TARGET
/datum/behavior_tree/node/sequence/charge_target
	my_nodes = list(
					/datum/behavior_tree/node/action/check_charge_rate,
					/datum/behavior_tree/node/action/charge,
					/datum/behavior_tree/node/action/reset_charge)

// DODGE SEQUENCE //
/datum/behavior_tree/node/sequence/dodge
	my_nodes = list(
					/datum/behavior_tree/node/action/check_aggro,
					/datum/behavior_tree/node/action/unset_has_attacked,
					/datum/behavior_tree/node/action/remove_path, // removing path to see if it fixes issue.
					/datum/behavior_tree/node/action/check_same_z, // no dodging if your opponent is gone
					/datum/behavior_tree/node/action/dodge )

// FIND ANY THREAT //
/datum/behavior_tree/node/sequence/find_any_threat
	my_nodes = list(
					/datum/behavior_tree/node/action/check_time_wait,
					/datum/behavior_tree/node/action/find_any_human )

// FIND PATH TO TARGET
/datum/behavior_tree/node/sequence/find_path_to_target
	my_nodes = list(
					/datum/behavior_tree/node/action/check_same_z, // right now we don't path if they're off our z. Eventually changed I hope.
					/datum/behavior_tree/node/action/check_aggro,
					/datum/behavior_tree/node/action/check_approach,
					/datum/behavior_tree/node/action/check_has_path{invert = TRUE},
					/datum/behavior_tree/node/action/unset_has_attacked, // if you had to path then dodge failed.
					/datum/behavior_tree/node/action/find_path )

// HANDLE HOLDING //
// For mobs that are held
/datum/behavior_tree/node/sequence/handle_holding
	my_nodes = list(
					/datum/behavior_tree/node/action/check_held,
					/datum/behavior_tree/node/action/try_escape_holder )

// MEANDER SEQUNCE //
/datum/behavior_tree/node/sequence/meander_sequence
	my_nodes = list(
					/datum/behavior_tree/node/action/check_on_turf,
					/datum/behavior_tree/node/action/check_burrowing{invert = TRUE},
					/datum/behavior_tree/node/action/meander )

// PATH TO TARGET //
/datum/behavior_tree/node/sequence/path_to_target
	my_nodes = list(
					/datum/behavior_tree/node/action/check_has_path,
					/datum/behavior_tree/node/action/check_same_z,
					///datum/behavior_tree/node/action/check_approach{invert = TRUE},
					/datum/behavior_tree/node/action/follow_path )

// PROCESS THREATS //
/datum/behavior_tree/node/sequence/process_threats
	my_nodes = list(
					/datum/behavior_tree/node/action/aggro_tick,
					/datum/behavior_tree/node/action/find_human,
					/datum/behavior_tree/node/action/remove_dead_targets,
					/datum/behavior_tree/node/action/find_top_aggro,
					/datum/behavior_tree/node/action/threaten_target )

// Special threat process //
/datum/behavior_tree/node/sequence/special_process_threats
	my_nodes = list(
					/datum/behavior_tree/node/action/remove_dead_targets,
					/datum/behavior_tree/node/action/check_has_current_target{invert = TRUE},
					/datum/behavior_tree/node/action/find_top_aggro )

/datum/behavior_tree/node/sequence/attack_first_human
	my_nodes = list(
					/datum/behavior_tree/node/action/remove_dead_targets,
					/datum/behavior_tree/node/action/check_has_current_target{invert = TRUE},
					/datum/behavior_tree/node/action/find_any_human)

// DAMAGE HANDLE
//tries to deal with all damage incomming to the user
// First tries to check for a weapon
// Then a hand
// Then it will check 'things' that damage (like fire?) I dunno
/datum/behavior_tree/node/selector/standard_damage_handle
	my_nodes = list(
				/datum/behavior_tree/node/sequence/harvest,
				/datum/behavior_tree/node/action/bullet_hit,
				/datum/behavior_tree/node/action/handle_weapon_attack,
				/datum/behavior_tree/node/action/handle_human_touch
				)


// DAMAGE AND OVERLAY
// For a mob that has a damage overlay when health < half max health
/datum/behavior_tree/node/sequence/damage_and_overlay
	my_nodes = list(
				/datum/behavior_tree/node/selector/standard_damage_handle,
				/datum/behavior_tree/node/action/update_overlay
				)
//(to do)
// DAMAGE AND PAINSOUNDS
// For mobs that would make sounds upon being hurt


// HARVEST
/datum/behavior_tree/node/sequence/harvest
	my_nodes = list(
				/datum/behavior_tree/node/action/check_dead,
				/datum/behavior_tree/node/action/check_if_mob,
				/datum/behavior_tree/node/action/check_target_help_intent,
				/datum/behavior_tree/node/action/do_harvest
				)

// == // Tree Roots // == //
//=============================
//This is the top level node for an AI type please give it a useful name

// AGGRESSIVE MELEE ANIMAL //
// This animal will charge you and also try to juke
// This is your 'basic' hostile simple_mob equivalent (for now)
/datum/behavior_tree/node/selector/aggressive_melee_animal
	my_nodes = list(
				/datum/behavior_tree/node/sequence/process_threats,
				/datum/behavior_tree/node/sequence/attack_target,
				/datum/behavior_tree/node/sequence/find_path_to_target,
				/datum/behavior_tree/node/sequence/path_to_target,
				/datum/behavior_tree/node/sequence/dodge,
				/datum/behavior_tree/node/action/make_sound,
				/datum/behavior_tree/node/sequence/aggro_tick_meander )

// IDIOT ANIMAL //
// Meanders aimlessly
/datum/behavior_tree/node/selector/idiot_animal
	my_nodes = list(
				/datum/behavior_tree/node/action/make_sound,
				/datum/behavior_tree/node/sequence/meander_sequence,
				/datum/behavior_tree/node/action/do_nothing )

// IDIOT ANIMAL GRABBABLE //
// I think crabs use this
/datum/behavior_tree/node/selector/idiot_animal_grabbable
	my_nodes = list(
				/datum/behavior_tree/node/sequence/handle_holding,
				/datum/behavior_tree/node/action/make_sound,
				/datum/behavior_tree/node/sequence/meander_sequence,
				/datum/actions/do_nothing )

/datum/behavior_tree/node/selector/idiot_animal_grabbable_nomove
	my_nodes = list(
				/datum/behavior_tree/node/sequence/handle_holding,
				/datum/behavior_tree/node/action/make_sound,
				/datum/actions/do_nothing )

/datum/behavior_tree/node/sequence/tick_check_deactivate
	my_nodes = list(
					/datum/behavior_tree/node/action/find_any_human{invert = TRUE},
					/datum/behavior_tree/node/action/check_charge_rate,
					/datum/behavior_tree/node/action/deactivate )


// IDLE ATTACKER RESPONSIVE //
// This animal never moves it will only attack
// This animal only activates once attacked (put it in attack codes)
/datum/behavior_tree/node/selector/idle_attacker_responsive
	my_nodes = list(
					/datum/behavior_tree/node/sequence/tick_check_deactivate,
					/datum/behavior_tree/node/sequence/attack,
					/datum/behavior_tree/node/action/unset_has_attacked,
					/datum/behavior_tree/node/action/do_nothing )

// ATTACKER ACTIVE //
// This animal never moves it will only attack
/datum/behavior_tree/node/selector/attacker_active //is always active
	my_nodes = list(
				/datum/behavior_tree/node/sequence/process_threats,
				/datum/behavior_tree/node/sequence/attack_target )
/*
// AGGRESSIVE MELEE ANIMAL //
// This animal will charge you and also try to juke
// This is your 'basic' hostile simple_mob equivalent (for now)
/datum/behavior_tree/node/selector/aggressive_melee_animal
	my_nodes = list(
				/datum/behavior_tree/node/sequence/process_threats,
				/datum/behavior_tree/node/sequence/approach_target,
				/datum/behavior_tree/node/sequence/attack_target,
				/datum/behavior_tree/node/sequence/dodge,
				/datum/behavior_tree/node/action/make_sound,
				/datum/behavior_tree/node/sequence/aggro_tick_meander )
*/
// Burrowing idiot //
// has a burrow check but also acts like idiot mobs.
// uses that list as part of its tree, hopefully
/datum/behavior_tree/node/selector/burrowing_idiot
	my_nodes = list(
					/datum/behavior_tree/node/sequence/burrow,
					/datum/behavior_tree/node/sequence/unburrow,
					/datum/behavior_tree/node/selector/idiot_animal)

// SKITTISH ANIMAL //
// This animal will attack any human it sees
/datum/behavior_tree/node/selector/skittish_animal
	my_nodes = list(
				/datum/behavior_tree/node/sequence/process_threats,
				/datum/behavior_tree/node/sequence/attack_target,
				/datum/behavior_tree/node/sequence/avoid_target,
				/datum/behavior_tree/node/action/make_sound,
				/datum/behavior_tree/node/sequence/aggro_tick_meander )

// Scrungus
// Find target
// Move to target
// Punch
// charges
//

// break obstacles move to target
/datum/behavior_tree/node/selector/break_turf_move_to_target
	my_nodes = list(
					/datum/behavior_tree/node/sequence/break_turf,
					/datum/behavior_tree/node/sequence/break_structures,
					//				/datum/behavior_tree/node/action/unset_has_attacked,
					/datum/behavior_tree/node/action/move_to_target )

/datum/behavior_tree/node/sequence/move_to_target
	my_nodes = list(
					/datum/behavior_tree/node/action/unset_has_attacked,
					/datum/behavior_tree/node/action/move_to_target )

// break obstacles
/datum/behavior_tree/node/sequence/break_turf
	my_nodes = list(
					/datum/behavior_tree/node/action/check_turf_block,
					/datum/behavior_tree/node/action/break_turf)

/datum/behavior_tree/node/sequence/break_structures
	my_nodes = list(
					/datum/behavior_tree/node/action/check_structure_block,
					/datum/behavior_tree/node/action/break_structures)


/datum/behavior_tree/node/selector/scrungus
	my_nodes = list(
					/datum/behavior_tree/node/sequence/attack_first_human,
					// /datum/behavior_tree/node/sequence/special_process_threats,
					// /datum/behavior_tree/node/sequence/charge_target,
					/datum/behavior_tree/node/sequence/simple_attack,
					/datum/behavior_tree/node/selector/break_turf_move_to_target,
					/datum/behavior_tree/node/action/meander ) // last thing in here for debugging
