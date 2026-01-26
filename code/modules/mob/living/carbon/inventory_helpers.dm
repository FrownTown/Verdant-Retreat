/**
 * Inventory helper procs for Carbon mobs.
 *
 * These procs facilitate managing NPC inventory, including finding items,
 * storing items, and manipulating held items.
 */

	/**
	 * Recursively searches the mob's inventory for an item of the given type.
	 * Checks held items, equipped slots, and storage items within those slots.
	 *
	 * @param typepath The type of item to search for.
	 * @return The first found instance of the item, or null if not found.
	 */
/mob/living/carbon/proc/find_item_in_inventory(typepath)
	// 1. Check held items
	for(var/obj/item/I in held_items)
		if(!I)
			continue
		if(istype(I, typepath))
			return I
		// Check storage in hand
		var/datum/component/storage/S = I.GetComponent(/datum/component/storage)
		if(S)
			for(var/obj/item/stored_item in S.return_inv(TRUE))
				if(istype(stored_item, typepath))
					return stored_item

	// 2. Check equipped items (including pockets for humans)
	for(var/obj/item/I in get_equipped_items(include_pockets = TRUE))
		if(istype(I, typepath))
			return I
		
		// Check contents of equipped storage
		var/datum/component/storage/S = I.GetComponent(/datum/component/storage)
		if(S)
			for(var/obj/item/stored_item in S.return_inv(TRUE))
				if(istype(stored_item, typepath))
					return stored_item
	return null

	/**
	 * Attempts to place an item into the mob's inventory.
	 *
	 * Priority of placement:
	 * 1. Native equipment slot (if item flags allow).
	 * 2. Pockets (if human and fits).
	 * 3. Equipped storage containers (backpack, belt, etc.).
	 * 4. Hands (if free and allowed).
	 *
	 * @param I The item to store.
	 * @param allow_hands Whether to allow storing in hands.
	 * @return TRUE if the item was successfully stored/equipped/held, FALSE otherwise.
	 */
/mob/living/carbon/proc/place_in_inventory(obj/item/I, allow_hands = TRUE)
	if(!I)
		return FALSE
	
	// 1. Try to equip to its primary slot
	if(equip_to_slot_if_possible(I, I.slot_flags, disable_warning = TRUE))
		return TRUE

	// 2. Try to put in pockets
	if(ishuman(src))
		var/mob/living/carbon/human/H = src
		if(H.equip_to_slot_if_possible(I, SLOT_L_STORE, disable_warning = TRUE))
			return TRUE
		if(H.equip_to_slot_if_possible(I, SLOT_R_STORE, disable_warning = TRUE))
			return TRUE

	// 3. Try to insert into any equipped storage item
	for(var/obj/item/equipped in get_equipped_items(include_pockets = TRUE))
		// Attempt to insert into storage component
		if(SEND_SIGNAL(equipped, COMSIG_TRY_STORAGE_INSERT, I, src, TRUE))
			return TRUE

	// 4. Finally, try to put in hands if it didn't fit anywhere else
	if(allow_hands && put_in_hands(I))
		return TRUE
		
	return FALSE

	/**
	 * Ensures the specified item is in the mob's active hand.
	 *
	 * - If held in active hand: Do nothing.
	 * - If held in inactive hand: Switch active hand to that hand.
	 * - If in inventory: Unequip/Remove and put in active hand.
	 * - If active hand is full: Tries to store the current active item first.
	 *
	 * @param I The item to hold.
	 * @return TRUE if successful, FALSE otherwise.
	 */
/mob/living/carbon/proc/ensure_in_active_hand(obj/item/I)
	if(!I)
		return FALSE
	
	// Case 1: Already in active hand
	if(get_active_held_item() == I)
		return TRUE
		
	// Case 2: Held in another hand
	var/held_index = get_held_index_of_item(I)
	if(held_index)
		activate_hand(held_index)
		return TRUE
		
	// Case 3: In inventory (equipped or in storage)
	// We need to extract it.
	
	// If inside a container (backpack, etc.)
	if(I.loc != src)
		var/atom/container = I.loc
		var/datum/component/storage/S = container.GetComponent(/datum/component/storage)
		if(S)
			S.remove_from_storage(I, src) // Move to src contents
	
	// If equipped (worn)
	if(I in get_equipped_items(include_pockets = TRUE))
		temporarilyRemoveItemFromInventory(I, force=TRUE) // Unequip but keep in contents

	// Now attempt to put in active hand
	if(put_in_active_hand(I))
		return TRUE
		
	// Case 4: Active hand is full, try to swap
	var/obj/item/current_item = get_active_held_item()
	if(current_item)
		// Try to stash the current item away
		if(place_in_inventory(current_item) || dropItemToGround(current_item)) // Attempt to stow first, drop as last resort
			// Now hand should be empty
			if(put_in_active_hand(I))
				return TRUE

	return FALSE

/**
 * Selects and equips the best weapon for a specific damage type from the mob's inventory.
 *
 * Searches through equipped and held items to find the weapon with the highest damage
 * intent matching the specified blade class (damage type). For example, requesting BCLASS_BLUNT
 * will find the weapon with the highest-damage blunt attack, which could be a pommel strike
 * on a sword or a dedicated club.
 *
 * @param damage_type The blade_class to search for (e.g., BCLASS_BLUNT, BCLASS_CUT, BCLASS_STAB)
 * @return TRUE if a suitable weapon was found and equipped, FALSE otherwise
 */
/mob/living/carbon/proc/equip_best_weapon_for_damage_type(damage_type)
	if(!damage_type)
		return FALSE

	var/obj/item/best_weapon = null
	var/best_damage = 0

	// Search through all equipped items and hands
	var/list/items_to_check = get_equipped_items(include_pockets = TRUE) + held_items

	for(var/obj/item/I in items_to_check)
		if(!I || !I.possible_item_intents)
			continue

		// Check each intent on this item
		for(var/intent_path in I.possible_item_intents)
			var/datum/intent/test_intent = new intent_path(src, I)

			if(test_intent.blade_class == damage_type)
				// Calculate the effective damage for this intent
				var/effective_damage = I.force * test_intent.damfactor

				if(effective_damage > best_damage)
					best_damage = effective_damage
					best_weapon = I

			qdel(test_intent)

	// If we found a suitable weapon, ensure it's in our active hand
	if(best_weapon)
		return ensure_in_active_hand(best_weapon)

	return FALSE

/**
 * Manages the wield state of the currently held item.
 *
 * Ensures that an item is wielded (two-handed) or unwielded based on the desired state.
 * Only changes the state if it differs from the current state.
 *
 * @param should_wield TRUE to wield the item, FALSE to unwield it
 * @return TRUE if the desired state is achieved, FALSE otherwise
 */
/mob/living/carbon/proc/set_wield_state(should_wield = TRUE)
	var/obj/item/held = get_active_held_item()

	if(!held)
		return FALSE

	// Already in the desired state
	if(held.wielded == should_wield)
		return TRUE

	// Change the state
	if(should_wield)
		held.wield(src, show_message = FALSE)
		return held.wielded
	else
		held.ungrip(src, show_message = FALSE)
		return !held.wielded

/**
 * Selects a specific intent with inventory management.
 *
 * Wraps intent selection to ensure that if items need to be stowed to select an unarmed
 * intent, they are properly stored. Uses inventory helpers to manage items and then
 * executes the attack action.
 *
 * @param intent_name The intent to select (e.g., INTENT_HELP, INTENT_GRAB)
 * @param target The target to attack after selecting the intent
 * @return TRUE if the intent was selected and attack executed, FALSE otherwise
 */
/mob/living/carbon/proc/select_intent_and_attack(intent_name, atom/target)
	if(!intent_name || !target)
		return FALSE
	var/static/list/unarmed_intents = list(INTENT_HELP, INTENT_DISARM, INTENT_GRAB, INTENT_HARM)
	// Check if this is an unarmed intent
	var/is_unarmed_intent = (intent_name in unarmed_intents)

	// If we need to be unarmed and we're holding something
	if(is_unarmed_intent)
		var/obj/item/held = get_active_held_item()
		if(held)
			// Try to stow it
			if(!place_in_inventory(held, allow_hands = FALSE))
				// If we can't stow it, drop it
				dropItemToGround(held, force = TRUE)
		
		switch(intent_name)
			if(INTENT_HELP)
				rog_intent_change(1)
			if(INTENT_DISARM)
				rog_intent_change(2)
			if(INTENT_GRAB)
				rog_intent_change(3)
			if(INTENT_HARM)
				rog_intent_change(4)

		// Execute the attack
		npc_click_on(src, target)
		return TRUE

	else

		// Find the intent index in our available intents
		var/intent_index = 0
		for(var/i = 1 to length(possible_a_intents))
			var/datum/intent/check_intent = possible_a_intents[i]
			if(check_intent.name == intent_name || check_intent.intent_type == intent_name)
				intent_index = i
				break

		if(intent_index > 0)
			// Check if we're already using this intent
			if(used_intent != possible_a_intents[intent_index])
				a_intent_change(intent_index)

			npc_click_on(src, target)
			return TRUE

	return FALSE

/**
 * Picks up the item that is set as the ai_root's target.
 *
 * Attempts to pick up an item from the ground or other location and place it
 * in the NPC's inventory.
 *
 * @return TRUE if the item was successfully picked up, FALSE otherwise
 */
/mob/living/carbon/proc/pickup_target_item(priority = FALSE)
	if(!ai_root || !ai_root.target)
		return FALSE

	var/atom/target = ai_root.target

	// Make sure it's an item we can pick up
	if(!isitem(target))
		return FALSE

	var/obj/item/I = target

	// Try to pick it up
	if((Adjacent(I) || get_turf(I) == get_turf(src)) && CanReach(I))
		// Put it in our active hand or inventory
		if(put_in_active_hand(I) || place_in_inventory(I))
			return TRUE

	return FALSE

/**
 * Selects a specific RMB (right mouse button) intent.
 *
 * Changes the mob's rmb_intent to the specified type.
 *
 * @param rmb_intent_path The path to the RMB intent datum to select
 * @return TRUE if the intent was selected, FALSE otherwise
 */
/mob/living/carbon/proc/select_rmb_intent(rmb_intent_path)
	if(!rmb_intent_path)
		return FALSE

	var/index = 0
	for(var/i in 1 to length(possible_rmb_intents))
		var/datum/intent/check_intent = possible_rmb_intents[i]
		if(check_intent.type == rmb_intent_path)
			index = i
			break
	
	if(index == 0)
		return FALSE

	swap_rmb_intent(num = index)
	return TRUE

/**
 * Executes the current RMB action on a target.
 *
 * Performs the right mouse button action on the specified target using the
 * currently selected rmb_intent.
 *
 * @param target The target atom to perform the RMB action on
 * @return TRUE if the action was executed, FALSE otherwise
 */
/mob/living/carbon/proc/execute_rmb_action(atom/target)
	if(!target || !rmb_intent)
		return FALSE

	// Face the target
	face_atom(target)

	// Execute the RMB action by calling ClickOn with right-click parameters
	// This simulates a right-click on the target
	var/obj/item/held = get_active_held_item()
	if(held)
		RightClickOn(target, "right=TRUE")

	return TRUE

/**
 * Selects a specific MMB (middle mouse button) intent and executes it on a target.
 *
 * Changes the mob's mmb_intent to the specified type and immediately executes
 * the action on the target.
 *
 * @param mmb_intent_name The name of the MMB intent to select (e.g., INTENT_KICK, INTENT_BITE)
 * @param target The target atom to perform the MMB action on
 * @return TRUE if the intent was selected and executed, FALSE otherwise
 */
/mob/living/carbon/proc/select_and_execute_mmb_intent(mmb_intent_type, atom/target)
	if(!mmb_intent_type || !target)
		return FALSE

	mmb_intent_change(mmb_intent_type)

	face_atom(target)

	MiddleClickOn(target)

	return TRUE

/**
 * Selects an atom as the obj_target and attacks it.
 *
 * Sets the ai_root's obj_target to the specified atom (for objects/structures
 * that need to be broken, not living targets) and attacks it.
 *
 * @param target The atom to set as obj_target and attack
 * @return TRUE if the target was set and attacked, FALSE otherwise
 */
/mob/living/carbon/proc/attack_obj_target(atom/target)
	if(!target || !ai_root)
		return FALSE

	// Set as our obj_target
	ai_root.obj_target = target

	// Make sure we have a weapon or fists ready
	var/obj/item/held = get_active_held_item()

	// Face and attack the target
	if(Adjacent(target))
		face_atom(target)

		if(held)
			npc_click_on(src, target)
		else
			// Unarmed attacks can't be executed on objects
			return FALSE

		return TRUE

	return FALSE

/**
 * Uses a grab intent (upgrade or shove) on the grabbed target.
 *
 * Checks if the specified grab intent is already selected before changing it,
 * then executes the grab's attack method to perform the upgrade/shove action.
 *
 * @param grab The grabbing object to use
 * @param intent_type The type of grab intent to use (/datum/intent/grab/upgrade or /datum/intent/grab/shove)
 * @param target The target being grabbed
 * @return TRUE if the intent was executed, FALSE if the intent wasn't found
 */
/mob/living/carbon/proc/use_grab_intent(obj/item/grabbing/grab, intent_type, atom/target)
	if(!grab || !intent_type || !target)
		return FALSE

	// Find the intent in our available intents
	for(var/i = 1 to length(possible_a_intents))
		var/datum/intent/check_intent = possible_a_intents[i]
		if(istype(check_intent, intent_type))
			// Only change intent if not already using it
			if(used_intent != check_intent)
				a_intent_change(i)
			// Execute the grab action
			grab.attack(target, src)
			return TRUE

	return FALSE

/**
 * Resets the NPC to a default combat-ready state.
 *
 * This comprehensive helper:
 * 1. Finds and equips the best weapon available
 * 2. Wields it if it has better two-handed force, or equips a shield if not
 * 3. Selects the most effective intent for dealing damage
 *
 * @return TRUE if the reset was successful, FALSE otherwise
 */
/mob/living/carbon/proc/reset_to_combat_state()
	// First, find the best weapon overall (highest force)
	var/obj/item/best_weapon = null
	var/best_force = 0

	var/list/items_to_check = get_equipped_items(include_pockets = TRUE) + held_items

	for(var/obj/item/I in items_to_check)
		if(!I)
			continue

		var/check_force = max(I.force, I.force_wielded)

		if(check_force > best_force)
			best_force = check_force
			best_weapon = I

	// Equip the best weapon
	if(best_weapon)
		if(!ensure_in_active_hand(best_weapon))
			return FALSE

		// Decide whether to wield or use a shield
		if(best_weapon.force_wielded > best_weapon.force && (best_weapon.gripped_intents || best_weapon.wielded))
			// Wield it for better damage
			set_wield_state(TRUE)
		else
			// Try to find and equip a shield in the off-hand
			var/obj/item/shield = find_item_in_inventory(/obj/item/rogueweapon/shield)

			if(shield)
				// Unwield main weapon if wielded
				set_wield_state(FALSE)

				// Switch to inactive hand
				var/inactive_index = get_inactive_hand_index()
				if(inactive_index)
					activate_hand(inactive_index)
					ensure_in_active_hand(shield)
					// Switch back to weapon hand
					activate_hand(get_inactive_hand_index())

	// Now select the best intent for damage
	// Go through all available intents and find the one with highest damage
	update_a_intents()

	var/best_intent_index = 1
	var/best_intent_damage = 0

	for(var/i = 1 to length(possible_a_intents))
		var/datum/intent/check_intent = possible_a_intents[i]
		if(!check_intent)
			continue

		var/effective_damage = 0
		if(best_weapon)
			effective_damage = best_weapon.force_dynamic * check_intent.damfactor
		else
			// Unarmed damage calculation would go here
			effective_damage = check_intent.damfactor * 5 // Rough estimate

		if(effective_damage > best_intent_damage)
			best_intent_damage = effective_damage
			best_intent_index = i

	// Select the best intent
	a_intent_change(best_intent_index)

	return TRUE
