// ==============================================================================
// SQUAD TACTICS FRAMEWORK
// ==============================================================================
// Tactics are modular behaviors that can be applied to squads to control
// their combat behavior. They can be swapped at runtime.

/squad_tactic
	parent_type = /datum
	var/name = "basic tactics"
	var/description = "Basic squad behavior"
	var/ai_squad/squad // Reference to the squad using this tactic
	var/target_switch_delay = 2 SECONDS // Delay before switching targets to prevent loops

/squad_tactic/proc/assign_to_squad(ai_squad/S)
	if(!S) return
	squad = S
	squad.current_tactic = src

/squad_tactic/proc/remove_from_squad()
	if(squad)
		squad.current_tactic = null
	squad = null

// Called every squad AI tick to apply tactical logic
/squad_tactic/proc/apply_tactics()
	if(!squad || !length(squad.members))
		return

	select_targets()
	coordinate_positions()

// Override this to implement target selection strategy
/squad_tactic/proc/select_targets()
	return

// Override this to implement positioning strategy
/squad_tactic/proc/coordinate_positions()
	return


// ==============================================================================
// FOCUS FIRE TACTIC - All squad members target the same enemy
// ==============================================================================
/squad_tactic/focus_fire
	name = "focus fire"
	description = "All squad members converge on a single target"
	var/current_focus_target = null

/squad_tactic/focus_fire/select_targets()
	if(!squad) return

	// Find best focus target (priority: personal attacker > leader's target > closest aggressor)
	var/mob/living/new_focus = null

	// Check if any member is being personally attacked
	for(var/mob/living/M as anything in squad.members)
		if(!M.ai_root) continue
		var/list/aggressors = M.ai_root.blackboard[AIBLK_AGGRESSORS]
		if(!aggressors || !length(aggressors)) continue

		// Find visible aggressors attacking this member
		for(var/mob/living/A as anything in aggressors)
			if(!A || A.stat == DEAD) continue
			if(get_dist(M, A) <= 7 && !los_blocked(M, A, TRUE))
				// Prioritize attackers of members who aren't currently targeting anyone
				if(!M.ai_root.target)
					new_focus = A
					break
		if(new_focus)
			break

	// Fallback: Use leader's target
	if(!new_focus && squad.leader && squad.leader.ai_root)
		new_focus = squad.leader.ai_root.target

	// Fallback: Find closest aggressor to squad center
	if(!new_focus)
		squad.update_center_of_mass()
		if(squad.center_of_mass)
			var/closest_dist = INFINITY
			for(var/mob/living/M as anything in squad.members)
				if(!M.ai_root) continue
				var/list/aggressors = M.ai_root.blackboard[AIBLK_AGGRESSORS]
				if(!aggressors) continue

				for(var/mob/living/A as anything in aggressors)
					if(!A || A.stat == DEAD) continue
					var/dist = get_dist(squad.center_of_mass, A)
					if(dist < closest_dist)
						new_focus = A
						closest_dist = dist

	// Apply focus target to all members (respecting switch delay)
	if(new_focus && new_focus != current_focus_target)
		current_focus_target = new_focus

	if(current_focus_target)
		for(var/mob/living/M as anything in squad.members)
			if(!M.ai_root) continue

			// Only switch if we can (respects delay)
			if(M.can_switch_target(current_focus_target, target_switch_delay))
				M.ai_root.target = current_focus_target
				M.record_target_switch()

// ==============================================================================
// SPREAD OUT TACTIC - Squad members target different enemies
// ==============================================================================
/squad_tactic/spread_out
	name = "spread out"
	description = "Squad members engage different enemies to divide attention"
	var/list/assigned_targets = list() // member -> target mapping

/squad_tactic/spread_out/select_targets()
	if(!squad) return

	// Collect all available enemy targets
	var/list/available_enemies = list()
	for(var/mob/living/M as anything in squad.members)
		if(!M.ai_root) continue
		var/list/aggressors = M.ai_root.blackboard[AIBLK_AGGRESSORS]
		if(aggressors)
			available_enemies |= aggressors

	// Clean up dead/invalid enemies
	for(var/mob/living/E as anything in available_enemies)
		if(!E || E.stat == DEAD)
			available_enemies -= E

	if(!length(available_enemies))
		return

	// Assign each member a different target if possible
	var/list/used_targets = list()

	for(var/mob/living/M as anything in squad.members)
		if(!M.ai_root) continue

		// If being personally attacked, prioritize that attacker
		var/mob/living/personal_attacker = null
		var/list/aggressors = M.ai_root.blackboard[AIBLK_AGGRESSORS]
		if(aggressors)
			for(var/mob/living/A as anything in aggressors)
				if(!A || A.stat == DEAD) continue
				if(get_dist(M, A) <= 7 && !los_blocked(M, A, TRUE))
					personal_attacker = A
					break

		var/mob/living/new_target = null

		if(personal_attacker)
			new_target = personal_attacker
		else
			// Find an enemy that's not already being targeted
			for(var/mob/living/E as anything in available_enemies)
				if(!(E in used_targets))
					new_target = E
					break

			// If all enemies are assigned, just pick the closest one
			if(!new_target && length(available_enemies))
				var/closest_dist = INFINITY
				for(var/mob/living/E as anything in available_enemies)
					var/dist = get_dist(M, E)
					if(dist < closest_dist)
						new_target = E
						closest_dist = dist

		// Assign target (respecting switch delay)
		if(new_target && M.can_switch_target(new_target, target_switch_delay))
			M.ai_root.target = new_target
			assigned_targets[M] = new_target
			used_targets += new_target
			M.record_target_switch()
