// BURN HEALING ITEMS - Physical items that can be applied to treat burns

//==============================================================================
// BURN SALVE - General burn treatment
//==============================================================================

/obj/item/natural/burn_salve
	name = "burn salve"
	desc = "A waxy ointment made from healing herbs. Soothes burns and promotes healing."
	icon = 'icons/roguetown/items/produce.dmi'
	icon_state = "salt" // Using salt sprite as base, will color it
	color = "#f5deb3" // Wheat/tan color for salve
	w_class = WEIGHT_CLASS_TINY
	throwforce = 0
	throw_range = 3
	var/uses = 5
	var/heal_amount = 15 // How much it heals burn wounds
	var/burn_damage_heal = 10 // How much raw burn damage it heals

/obj/item/natural/burn_salve/examine(mob/user)
	. = ..()
	. += span_info("It has [uses] use\s remaining.")

/obj/item/natural/burn_salve/attack(mob/living/M, mob/living/user)
	if(!iscarbon(M))
		to_chat(user, span_warning("I can't treat [M] with this!"))
		return

	if(uses <= 0)
		to_chat(user, span_warning("[src] is all used up!"))
		return

	var/mob/living/carbon/C = M
	var/obj/item/bodypart/affecting = C.get_bodypart(check_zone(user.zone_selected))

	if(!affecting)
		to_chat(user, span_warning("I can't find that bodypart!"))
		return

	// Check if there are any burns to heal
	var/has_burns = FALSE
	var/has_burn_damage = affecting.burn_dam > 0

	for(var/datum/wound/W in affecting.wounds)
		if(istype(W, /datum/wound/burn) || istype(W, /datum/wound/dynamic/burn))
			has_burns = TRUE
			break

	if(!has_burns && !has_burn_damage)
		to_chat(user, span_warning("[M]'s [affecting.name] has no burns to treat!"))
		return

	// Apply the salve
	user.visible_message(
		span_notice("[user] applies [src] to [M]'s [affecting.name]."),
		span_notice("I apply [src] to [M]'s [affecting.name].")
	)

	playsound(user, 'sound/foley/bandage.ogg', 100, FALSE)

	// Heal burn wounds
	var/healed_wounds = 0
	for(var/datum/wound/W in affecting.wounds)
		if(istype(W, /datum/wound/burn) || istype(W, /datum/wound/dynamic/burn))
			W.heal_wound(heal_amount)
			healed_wounds++

	// Heal raw burn damage
	affecting.heal_damage(0, burn_damage_heal)

	if(healed_wounds > 0)
		to_chat(M, span_nicegreen("The salve soothes my burns."))

	uses--
	if(uses <= 0)
		to_chat(user, span_warning("[src] is used up."))
		qdel(src)

	return TRUE

//==============================================================================
// WARMING POULTICE - Frostbite treatment
//==============================================================================

/obj/item/natural/warming_poultice
	name = "warming poultice"
	desc = "A heated compress infused with spices. Restores circulation to frostbitten flesh."
	icon = 'icons/roguetown/items/natural.dmi'
	icon_state = "cloth" // Using cloth sprite as base for poultice
	color = "#ff8c00" // Dark orange for warming effect
	w_class = WEIGHT_CLASS_TINY
	throwforce = 0
	throw_range = 3
	var/uses = 3
	var/heal_amount = 20 // Very effective against frostbite
	var/burn_damage_heal = 12

/obj/item/natural/warming_poultice/examine(mob/user)
	. = ..()
	. += span_info("It has [uses] use\s remaining.")
	. += span_info("Especially effective against frostbite.")

/obj/item/natural/warming_poultice/attack(mob/living/M, mob/living/user)
	if(!iscarbon(M))
		to_chat(user, span_warning("I can't treat [M] with this!"))
		return

	if(uses <= 0)
		to_chat(user, span_warning("[src] is all used up!"))
		return

	var/mob/living/carbon/C = M
	var/obj/item/bodypart/affecting = C.get_bodypart(check_zone(user.zone_selected))

	if(!affecting)
		to_chat(user, span_warning("I can't find that bodypart!"))
		return

	// Check if there are any frostbite wounds
	var/has_frostbite = FALSE
	var/has_burns = FALSE

	for(var/datum/wound/W in affecting.wounds)
		if(istype(W, /datum/wound/burn/frostbite))
			has_frostbite = TRUE
		else if(istype(W, /datum/wound/burn) || istype(W, /datum/wound/dynamic/burn))
			has_burns = TRUE

	if(!has_frostbite && !has_burns && affecting.burn_dam <= 0)
		to_chat(user, span_warning("[M]'s [affecting.name] has no burns or frostbite to treat!"))
		return

	// Apply the poultice
	user.visible_message(
		span_notice("[user] applies the warming poultice to [M]'s [affecting.name]."),
		span_notice("I apply the warming poultice to [M]'s [affecting.name].")
	)

	playsound(user, 'sound/foley/bandage.ogg', 100, FALSE)

	// Heal frostbite very effectively, other burns less so
	for(var/datum/wound/W in affecting.wounds)
		if(istype(W, /datum/wound/burn/frostbite))
			W.heal_wound(heal_amount) // Very effective
			to_chat(M, span_nicegreen("Warmth returns to my frozen flesh!"))
		else if(istype(W, /datum/wound/burn) || istype(W, /datum/wound/dynamic/burn))
			W.heal_wound(heal_amount * 0.5) // Half as effective on normal burns

	// Heal raw burn damage
	affecting.heal_damage(0, burn_damage_heal)

	uses--
	if(uses <= 0)
		to_chat(user, span_warning("[src] is used up."))
		qdel(src)

	return TRUE

//==============================================================================
// NEUTRALIZING POWDER - Acid burn treatment
//==============================================================================

/obj/item/natural/neutralizing_powder
	name = "neutralizing powder"
	desc = "A fine alkaline powder. Neutralizes acids and soothes chemical burns."
	icon = 'icons/roguetown/items/produce.dmi'
	icon_state = "salt" // Using salt sprite as base for powder
	color = "#e0e0e0" // Light gray/white for alkaline powder
	w_class = WEIGHT_CLASS_TINY
	throwforce = 0
	throw_range = 3
	var/uses = 4
	var/heal_amount = 18
	var/burn_damage_heal = 10
	var/pain_reduction = 5 // Reduces ongoing acid pain

/obj/item/natural/neutralizing_powder/examine(mob/user)
	. = ..()
	. += span_info("It has [uses] use\s remaining.")
	. += span_info("Especially effective against acid burns.")

/obj/item/natural/neutralizing_powder/attack(mob/living/M, mob/living/user)
	if(!iscarbon(M))
		to_chat(user, span_warning("I can't treat [M] with this!"))
		return

	if(uses <= 0)
		to_chat(user, span_warning("[src] is all used up!"))
		return

	var/mob/living/carbon/C = M
	var/obj/item/bodypart/affecting = C.get_bodypart(check_zone(user.zone_selected))

	if(!affecting)
		to_chat(user, span_warning("I can't find that bodypart!"))
		return

	// Check if there are any acid burns
	var/has_acid_burns = FALSE
	var/has_burns = FALSE

	for(var/datum/wound/W in affecting.wounds)
		if(istype(W, /datum/wound/burn/acid))
			has_acid_burns = TRUE
		else if(istype(W, /datum/wound/burn) || istype(W, /datum/wound/dynamic/burn))
			has_burns = TRUE

	if(!has_acid_burns && !has_burns && affecting.burn_dam <= 0)
		to_chat(user, span_warning("[M]'s [affecting.name] has no burns to treat!"))
		return

	// Apply the powder
	user.visible_message(
		span_notice("[user] sprinkles neutralizing powder on [M]'s [affecting.name]."),
		span_notice("I sprinkle neutralizing powder on [M]'s [affecting.name].")
	)

	playsound(user, 'sound/items/seedextract.ogg', 100, FALSE)

	// Heal acid burns very effectively, reduce pain
	for(var/datum/wound/W in affecting.wounds)
		if(istype(W, /datum/wound/burn/acid))
			W.heal_wound(heal_amount) // Very effective
			W.woundpain = max(W.woundpain - pain_reduction, 5) // Reduce pain
			to_chat(M, span_nicegreen("The acid burn stops stinging!"))
		else if(istype(W, /datum/wound/burn) || istype(W, /datum/wound/dynamic/burn))
			W.heal_wound(heal_amount * 0.6) // Less effective on normal burns

	// Heal raw burn damage
	affecting.heal_damage(0, burn_damage_heal)

	uses--
	if(uses <= 0)
		to_chat(user, span_warning("[src] is used up."))
		qdel(src)

	return TRUE

//==============================================================================
// MEDICATED BANDAGES - Burn-soothing bandages
//==============================================================================

/obj/item/natural/cloth/burn_bandage
	name = "medicated bandage"
	desc = "A cloth treated with soothing aloe. Effective on burns but less so on bleeding wounds."
	bandage_effectiveness = 0.6 // Less effective against bleeding than normal cloth
	color = "#c8dcc8"
	var/burn_heal_bonus = 8

/obj/item/natural/cloth/burn_bandage/examine(mob/user)
	. = ..()
	. += span_info("Especially effective against burns.")

// This should integrate with existing cloth bandaging system
// We just need to add extra burn healing when applied
