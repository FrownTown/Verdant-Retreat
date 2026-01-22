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
	 * 4. Hands (if free).
	 *
	 * @param I The item to store.
	 * @return TRUE if the item was successfully stored/equipped/held, FALSE otherwise.
	 */
/mob/living/carbon/proc/place_in_inventory(obj/item/I)
	if(!I)
		return FALSE
	
	// 1. Try to equip to its primary slot
	if(equip_to_slot_if_possible(I, I.slot_flags, disable_warning = TRUE))
		return TRUE

	// 2. Try to put in pockets (Human specific logic)
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
	if(put_in_hands(I))
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
