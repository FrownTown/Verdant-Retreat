/datum/wound/infection
	name = "infected wound"
	check_name = span_infection("<B>INFECTED</B>")
	severity = WOUND_SEVERITY_CRITICAL
	crit_message = ""
	sound_effect = null
	whp = 200  // Very high, doesn't heal naturally
	woundpain = 0  // Stage 1 has no pain
	bleed_rate = null  // Doesn't bleed
	can_sew = FALSE
	can_cauterize = FALSE
	disabling = FALSE  // Only disables at stage 4
	critical = TRUE
	sleep_healing = 0
	passive_healing = 0
	healable_by_miracles = FALSE  // Only specific treatments work
	bypass_bloody_wound_check = TRUE  // Can apply to any limb

	// Stage tracking
	var/infection_stage = 1
	var/time_to_next_stage = 0  // World time when stage advances
	var/progression_multiplier = 1.0  // 2.0 for infections from necrotic spread
	var/next_spread_attempt = 0  // World time for next spread attempt
	var/last_stage_duration = 0  // Track duration of last stage for calculations

	// Stage timing bases (in deciseconds)
	var/stage_2_base_time = 15 MINUTES  // 10-20 min randomized
	var/stage_3_base_time = 30 MINUTES  // 20-40 min randomized
	var/stage_4_time = 60 MINUTES  // Fixed at 60 min total

	// Visual tracking
	var/necrotic_overlay_applied = FALSE

/datum/wound/infection/can_stack_with(datum/wound/other)
	// Only one infection per bodypart
	if(istype(other, /datum/wound/infection))
		return FALSE
	return TRUE

/datum/wound/infection/on_bodypart_gain(obj/item/bodypart/affected)
	. = ..()
	initialize_stage_timers()

/datum/wound/infection/proc/initialize_stage_timers()
	if(!owner || !bodypart_owner)
		return

	// Calculate CON modifier
	var/con_modifier = 1.0
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		// Each point of CON above 10 adds 5% to timer, below 10 reduces by 5%
		con_modifier = 1.0 + ((H.STACON - 10) * 0.05)
		con_modifier = clamp(con_modifier, 0.5, 2.0)  // Min 50%, max 200%

	// Stage 1 -> 2: Randomize between 10-20 minutes, apply CON and progression multiplier
	var/stage_2_variance = rand(10 MINUTES, 20 MINUTES)
	var/adjusted_stage_2 = (stage_2_variance * con_modifier) / progression_multiplier
	time_to_next_stage = world.time + adjusted_stage_2

/datum/wound/infection/on_life()
	. = ..()
	if(!owner || !bodypart_owner)
		return

	// Check for stage progression
	if(world.time >= time_to_next_stage)
		advance_stage()

	// Apply stage-specific effects
	apply_stage_effects()

/datum/wound/infection/proc/advance_stage()
	if(!owner || !bodypart_owner)
		return

	infection_stage++

	switch(infection_stage)
		if(2)
			// Stage 2: Festering
			name = "festering wound"
			check_name = span_infection_purple("<B>FESTERING</B>")
			woundpain = 80
			to_chat(owner, span_userdanger("The wound on my [bodypart_owner.name] begins to fester!"))

			// Set timer for stage 3 (20-40 minutes from now)
			var/con_modifier = 1.0
			if(ishuman(owner))
				var/mob/living/carbon/human/H = owner
				con_modifier = 1.0 + ((H.STACON - 10) * 0.05)
				con_modifier = clamp(con_modifier, 0.5, 2.0)

			var/stage_3_variance = rand(20 MINUTES, 40 MINUTES)
			last_stage_duration = (stage_3_variance * con_modifier) / progression_multiplier
			time_to_next_stage = world.time + last_stage_duration

		if(3)
			// Stage 3: Necrotic
			name = "necrotic wound"
			check_name = span_infection_purple("<B>ROTTEN</B>")
			woundpain = 150
			to_chat(owner, span_userdanger("The wound on my [bodypart_owner.name] turns necrotic!"))
			owner.visible_message(span_danger("[owner]'s [bodypart_owner.name] begins to rot!"))

			// Set timer for stage 4 (time remaining to reach 60 min total)
			// Calculate total time elapsed so far
			var/time_since_infection = world.time - (time_to_next_stage - last_stage_duration)
			var/time_until_skeletal = stage_4_time - time_since_infection
			time_until_skeletal = max(time_until_skeletal, 5 MINUTES)  // At least 5 min
			time_to_next_stage = world.time + time_until_skeletal

			// Initialize spread timer
			next_spread_attempt = world.time + 1 MINUTES

		if(4)
			// Stage 4: Skeletal transformation
			name = "skeletal limb"
			check_name = span_bone_grey("<B>BONE</B>")
			disabling = TRUE

			to_chat(owner, span_userdanger("The flesh on my [bodypart_owner.name] has completely rotted away!"))
			owner.visible_message(span_danger("[owner]'s [bodypart_owner.name] turns to bare bone!"))

			// Check if vital limb
			var/is_vital = (bodypart_owner.body_zone in GLOB.vital_body_zones)

			// Use existing skeletonize proc
			bodypart_owner.skeletonize(lethal = is_vital)

/datum/wound/infection/proc/apply_stage_effects()
	if(!owner || !bodypart_owner)
		return

	switch(infection_stage)
		if(2)
			// Stage 2: Festering - emit decay smell
			var/turf/T = get_turf(owner)
			if(T && prob(10))  // 10% chance per life tick to emit smell
				T.pollute_turf(/datum/pollutant/rot, 2)

		if(3)
			// Stage 3: Necrotic - multiple effects
			apply_necrotic_effects()

/datum/wound/infection/proc/apply_necrotic_effects()
	if(!owner || !bodypart_owner)
		return

	// Apply visual overlay
	if(!necrotic_overlay_applied)
		apply_necrotic_overlay()

	// Random temporary disabling
	if(prob(3))  // 3% chance per life tick
		bodypart_owner.set_disabled(BODYPART_DISABLED_ROT)
		owner.visible_message(span_warning("[owner]'s [bodypart_owner.name] seizes up from the rot!"))
		// Re-enable after 5-15 seconds
		addtimer(CALLBACK(src, PROC_REF(reenable_bodypart)), rand(5 SECONDS, 15 SECONDS))

	// Spread to adjacent bodyparts
	if(world.time >= next_spread_attempt)
		attempt_spread()
		next_spread_attempt = world.time + rand(1, 3) MINUTES

	// Toxin damage for head/torso
	if(bodypart_owner.body_zone in GLOB.vital_body_zones)
		if(!HAS_TRAIT(owner, TRAIT_TOXIMMUNE))
			owner.adjustToxLoss(2)  // 2 toxin damage per life tick

/datum/wound/infection/proc/reenable_bodypart()
	if(!bodypart_owner)
		return
	bodypart_owner.set_disabled(BODYPART_NOT_DISABLED)
	if(owner)
		owner.visible_message(span_notice("[owner]'s [bodypart_owner.name] relaxes slightly."))

/datum/wound/infection/proc/apply_necrotic_overlay()
	if(!bodypart_owner || necrotic_overlay_applied)
		return

	// Mark the limb as rotted
	bodypart_owner.rotted = TRUE
	bodypart_owner.invalidate_limb_cache()
	if(iscarbon(owner))
		var/mob/living/carbon/C = owner
		C.update_body_parts()

	necrotic_overlay_applied = TRUE

/datum/wound/infection/proc/attempt_spread()
	if(!bodypart_owner || !owner)
		return

	var/list/adjacent = get_adjacent_bodyparts()
	for(var/obj/item/bodypart/BP in adjacent)
		if(!BP || BP.has_wound(/datum/wound/infection))
			continue

		if(prob(30))  // 30% chance per adjacent bodypart per minute
			var/datum/wound/infection/spread_infection = new /datum/wound/infection()
			spread_infection.progression_multiplier = 2.0  // 2x faster progression
			BP.add_wound(spread_infection)
			owner.visible_message(span_danger("The infection spreads from [owner]'s [bodypart_owner.name] to [owner.p_their()] [BP.name]!"))

/datum/wound/infection/proc/get_adjacent_bodyparts()
	if(!bodypart_owner || !owner)
		return list()

	var/list/adjacent = list()

	switch(bodypart_owner.body_zone)
		if(BODY_ZONE_HEAD)
			var/obj/item/bodypart/chest = owner.get_bodypart(BODY_ZONE_CHEST)
			if(chest)
				adjacent += chest
		if(BODY_ZONE_CHEST)
			var/obj/item/bodypart/head = owner.get_bodypart(BODY_ZONE_HEAD)
			if(head)
				adjacent += head
			var/obj/item/bodypart/r_arm = owner.get_bodypart(BODY_ZONE_R_ARM)
			if(r_arm)
				adjacent += r_arm
			var/obj/item/bodypart/l_arm = owner.get_bodypart(BODY_ZONE_L_ARM)
			if(l_arm)
				adjacent += l_arm
			var/obj/item/bodypart/r_leg = owner.get_bodypart(BODY_ZONE_R_LEG)
			if(r_leg)
				adjacent += r_leg
			var/obj/item/bodypart/l_leg = owner.get_bodypart(BODY_ZONE_L_LEG)
			if(l_leg)
				adjacent += l_leg
		if(BODY_ZONE_R_ARM, BODY_ZONE_L_ARM, BODY_ZONE_R_LEG, BODY_ZONE_L_LEG)
			var/obj/item/bodypart/chest = owner.get_bodypart(BODY_ZONE_CHEST)
			if(chest)
				adjacent += chest

	return adjacent

// Override heal_wound to prevent normal healing (miracles, potions, etc)
/datum/wound/infection/heal_wound(heal_amount, special_treatment = FALSE)
	// Only allow healing if this is a special infection treatment
	if(!special_treatment)
		return 0
	// Special treatments can cure the infection
	return ..()

// Try to treat infection with alcohol (only works on stage 1)
/datum/wound/infection/proc/try_alcohol_treatment()
	if(infection_stage > 1)
		return FALSE  // Too advanced

	if(prob(70))  // 70% chance to cure with alcohol
		to_chat(owner, span_notice("The alcohol burns away the infection in my [bodypart_owner.name]!"))
		owner.visible_message(span_notice("[owner] treats the infection on [owner.p_their()] [bodypart_owner.name] with alcohol."))
		qdel(src)
		return TRUE
	else
		to_chat(owner, span_warning("The alcohol stings, but the infection persists..."))
		return FALSE

// Try to cauterize infection (works differently based on stage)
/datum/wound/infection/proc/try_cauterize_treatment(surgical = FALSE)
	if(surgical)
		// Surgical cautery can burn out any stage
		to_chat(owner, span_notice("The surgical cautery burns away the infected tissue!"))
		owner.visible_message(span_danger("[owner] cauterizes the infected tissue on [owner.p_their()] [bodypart_owner.name]!"))
		owner.emote("painscream", TRUE)
		qdel(src)
		return TRUE
	else
		// Simple torch cautery only works on stage 1
		if(infection_stage > 1)
			to_chat(owner, span_warning("The infection is too deep to burn out with a torch!"))
			return FALSE

		to_chat(owner, span_notice("The flame sears away the infected tissue!"))
		owner.visible_message(span_danger("[owner] cauterizes the infection on [owner.p_their()] [bodypart_owner.name]!"))
		owner.emote("paincrit", TRUE)
		qdel(src)
		return TRUE
