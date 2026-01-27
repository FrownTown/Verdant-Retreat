/datum/wound/dynamic/burn
	name = "burn"
	whp = 10
	bleed_rate = 0
	clotting_rate = 0
	clotting_threshold = null
	sewn_clotting_threshold = 0
	woundpain = 8
	passive_healing = 0.3
	sew_threshold = 10
	can_sew = TRUE
	can_cauterize = FALSE
	sewn_bleed_rate = 0
	mob_overlay = ""
	severity_names = list(
		"minor" = 15,
		"moderate" = 30,
		"severe" = 50,
		"critical" = 70,
	)

#define BURN_UPG_WHPRATE 0.8
#define BURN_UPG_PAINRATE 0.5
#define BURN_UPG_HEALDECAY 0.01

/datum/wound/dynamic/burn/can_stack_with(datum/wound/other)
	// Don't stack with other dynamic burns - upgrade instead
	if(istype(other, /datum/wound/dynamic/burn))
		return FALSE
	return TRUE

// Burns use WHP for severity checks instead of bleed rate
/datum/wound/dynamic/burn/can_worsen(damage)
	if(amount > 1)
		return FALSE // Merged wounds don't get worsened, they stay separate
	if(is_maxed)
		return FALSE // Already at max severity
	if(whp >= max_absorbable_damage)
		return FALSE // Wound is too severe to absorb more damage

	// Check if incoming damage would result in similar severity based on WHP
	var/hypothetical_new_whp = whp + (damage * BURN_UPG_WHPRATE)
	var/whp_ratio = max(whp, hypothetical_new_whp) / max(min(whp, hypothetical_new_whp), 1)
	if(whp_ratio > 3)
		return FALSE // Incoming damage would make wound severity too different

	return TRUE

// Burns merge based on WHP similarity, not bleed rate
/datum/wound/dynamic/burn/can_merge(datum/wound/other)
	if(!other || QDELETED(other))
		return FALSE
	if(other.type != src.type)
		return FALSE
	// Don't merge burns of vastly different severities (based on WHP)
	var/whp_ratio = max(whp, other.whp) / max(min(whp, other.whp), 1)
	if(whp_ratio > 3)
		return FALSE
	// Don't merge sewn and unsewn wounds
	if(is_sewn() != other.is_sewn())
		return FALSE
	return TRUE

/datum/wound/dynamic/burn/sew_wound()
	return standard_sewing_procedure()

/datum/wound/dynamic/burn/update_name(show_message = FALSE)
	var/newname
	if(length(severity_names))
		for(var/sevname in severity_names)
			if(severity_names[sevname] <= whp)
				newname = sevname

	name = "[newname ? "[newname] " : ""][initial(name)]"
	// Burns appear and upgrade silently - no messages

/datum/wound/dynamic/burn/upgrade(dam, armor)
	whp += (dam * BURN_UPG_WHPRATE)
	woundpain += (dam * BURN_UPG_PAINRATE)
	passive_healing = max(0.1, passive_healing - BURN_UPG_HEALDECAY)

	// Only critical burns cause bleeding
	if(!is_sewn())
		if(whp >= 70)
			set_bleed_rate(0.4)
			// Critical burns have extremely high infection risk
			// This is handled by calculate_infection_chance() in bodypart_wounds.dm
			bodypart_owner.check_wound_infection(src, null, null)
		else
			set_bleed_rate(0)

	update_name()
	..()

#undef BURN_UPG_WHPRATE
#undef BURN_UPG_PAINRATE
#undef BURN_UPG_HEALDECAY

/datum/wound/burn/can_stack_with(datum/wound/other)
	if(other.type == type)
		var/datum/wound/burn/existing = other
		if(whp > existing.whp)
			existing.worsen_wound(whp - existing.whp)
		return FALSE
	return TRUE

/datum/wound/burn/proc/worsen_wound(amount)
	return // Stub

/datum/wound/burn/frostbite
	name = "severe frostbite"
	check_name = span_frostbite("<B>FROSTBITE</B>")
	severity = WOUND_SEVERITY_SEVERE
	whp = 40
	woundpain = 20
	bleed_rate = 0.15
	clotting_rate = 0
	clotting_threshold = null
	sewn_clotting_threshold = 0
	sew_threshold = 10
	passive_healing = 0.1
	mob_overlay = ""
	can_cauterize = FALSE
	can_sew = TRUE
	disabling = TRUE
	critical = TRUE
	crit_message = list(
		"%VICTIM's %BODYPART freezes solid!",
		"%VICTIM's %BODYPART is frozen to the bone!",
		"Ice crystals form in %VICTIM's %BODYPART!",
	)
	sound_effect = 'sound/combat/crit.ogg'

	// Frostbite progression
	var/time_until_falloff = 0  // World time when limb falls off
	var/next_disable_check = 0  // World time for next random disable attempt
	var/next_organ_damage = 0  // For head/chest: next organ damage tick



/datum/wound/burn/frostbite/on_mob_gain(mob/living/affected, damage)
	. = ..()
	affected.emote("paincrit", TRUE)
	if(damage)
		whp += damage * 0.8
		woundpain += damage * 0.4

	// Initialize frostbite timer (20-40 minutes)
	time_until_falloff = world.time + rand(20 MINUTES, 40 MINUTES)
	next_disable_check = world.time + rand(30 SECONDS, 2 MINUTES)
	next_organ_damage = world.time + rand(5 MINUTES, 10 MINUTES)

/datum/wound/burn/frostbite/on_life()
	. = ..()
	if(!owner || !bodypart_owner)
		return

	var/body_zone = bodypart_owner.body_zone
	var/is_vital = (body_zone == BODY_ZONE_HEAD || body_zone == BODY_ZONE_CHEST)

	// Random limb disable (non-vital parts only)
	if(!is_vital && world.time >= next_disable_check)
		next_disable_check = world.time + rand(30 SECONDS, 2 MINUTES)
		if(prob(15))  // 15% chance per check (every 30sec-2min)
			to_chat(owner, span_userdanger("My [bodypart_owner.name] seizes up from the cold!"))
			bodypart_owner.set_disabled(TRUE)
			addtimer(CALLBACK(src, PROC_REF(remove_disable)), rand(3 SECONDS, 10 SECONDS))

	// Limb fall-off check (non-vital parts only)
	if(!is_vital && world.time >= time_until_falloff)
		owner.visible_message(span_danger("[owner]'s frostbitten [bodypart_owner.name] falls off!"), \
							span_userdanger("My frostbitten [bodypart_owner.name] falls off!"))
		bodypart_owner.dismember(BURN, BCLASS_FROST)
		return

	// Organ damage for vital parts (head/chest)
	if(is_vital && world.time >= next_organ_damage)
		next_organ_damage = world.time + rand(5 MINUTES, 10 MINUTES)
		apply_organ_damage()

/datum/wound/burn/frostbite/proc/remove_disable()
	if(bodypart_owner)
		bodypart_owner.set_disabled(FALSE)
		to_chat(owner, span_notice("Feeling returns to my [bodypart_owner.name]."))

/datum/wound/burn/frostbite/proc/apply_organ_damage()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	var/body_zone = bodypart_owner.body_zone

	// Deal damage to organs in the affected zone
	if(body_zone == BODY_ZONE_HEAD)
		// Damage brain
		var/obj/item/organ/brain/B = H.getorganslot(ORGAN_SLOT_BRAIN)
		if(B)
			B.applyOrganDamage(5)
			to_chat(H, span_userdanger("My head throbs with icy pain..."))
	else if(body_zone == BODY_ZONE_CHEST)
		// Damage heart and lungs
		var/obj/item/organ/heart/heart = H.getorganslot(ORGAN_SLOT_HEART)
		var/obj/item/organ/lungs/lungs = H.getorganslot(ORGAN_SLOT_LUNGS)
		if(heart)
			heart.applyOrganDamage(3)
		if(lungs)
			lungs.applyOrganDamage(3)
		to_chat(H, span_userdanger("My chest feels frozen from the inside..."))

/datum/wound/burn/frostbite/worsen_wound(amount)
	owner.emote("paincrit", TRUE)
	if(amount)
		whp += amount * 0.8
		woundpain += amount * 0.4

/datum/wound/burn/electrical
	name = "deep electrical burn"
	check_name = span_electrical("<B>ELECTRICAL BURN</B>")
	severity = WOUND_SEVERITY_SEVERE
	whp = 45
	woundpain = 25
	bleed_rate = 0.18
	clotting_rate = 0
	clotting_threshold = null
	sewn_clotting_threshold = 0
	sew_threshold = 10
	passive_healing = 0.15
	mob_overlay = ""
	can_cauterize = FALSE
	can_sew = TRUE
	disabling = FALSE
	critical = TRUE
	crit_message = list(
		"%VICTIM's %BODYPART is charred by electricity!",
		"Electricity arcs through %VICTIM's %BODYPART!",
		"%VICTIM's %BODYPART smokes from the electrical current!",
	)
	sound_effect = 'sound/combat/crit.ogg'

/datum/wound/burn/electrical/on_mob_gain(mob/living/affected, damage)
	. = ..()
	var/stun_duration = clamp(woundpain * 0.3, 5, 15)
	affected.Stun(stun_duration)
	affected.emote("painscream", TRUE)
	if(damage)
		whp += damage * 0.9
		woundpain += damage * 0.5

/datum/wound/burn/electrical/worsen_wound(amount)
	if(amount)
		whp += amount * 0.9
		woundpain += amount * 0.5

/datum/wound/burn/acid
	name = "severe acid burn"
	check_name = span_acid("<B>ACID BURN</B>")
	severity = WOUND_SEVERITY_SEVERE
	whp = 50
	woundpain = 30
	bleed_rate = 0.35
	clotting_rate = 0.01
	clotting_threshold = 0.3
	sewn_clotting_threshold = null
	sew_threshold = 50
	passive_healing = 0.1
	mob_overlay = ""
	can_cauterize = FALSE
	can_sew = FALSE
	disabling = FALSE
	critical = TRUE
	crit_message = list(
		"%VICTIM's %BODYPART is eaten away by acid!",
		"Acid eats through %VICTIM's %BODYPART!",
		"%VICTIM's %BODYPART begins sloughing off!",
	)
	sound_effect = 'sound/combat/crit.ogg'

/datum/wound/burn/acid/on_mob_gain(mob/living/affected, damage)
	. = ..()
	if(damage)
		whp += damage
		woundpain += damage * 0.6
		bleed_rate = min(0.35 + (damage * 0.015), 0.8)
		// More damage = slower clotting
		clotting_rate = max(0.01 - (damage * 0.0002), 0.005)
	affected.emote("painscream", TRUE)

/datum/wound/burn/acid/worsen_wound(amount)
	if(amount)
		whp += amount
		woundpain += amount * 0.6
		bleed_rate = min(0.35 + (bleed_rate + amount * 0.015), 0.8)
		clotting_rate = max(0.01 - (clotting_rate + amount * 0.0002), 0.005)
	owner.emote("painscream", TRUE)

/datum/wound/burn/acid/on_life()
	. = ..()
	if(!iscarbon(owner))
		return
	var/mob/living/carbon/carbon_owner = owner
	if(!carbon_owner.stat && prob(5))
		to_chat(carbon_owner, span_warning("The acid burn continues to sting!"))
		worsen_wound(1)

/datum/wound/burn/charred
	name = "charred tissue"
	check_name = span_charred("<B>CHARRED</B>")
	severity = WOUND_SEVERITY_FATAL
	crit_message = list(
		"%VICTIM's %BODYPART is charred to the bone!",
		"%VICTIM's %BODYPART burns to cinders!",
		"Flames consume %VICTIM's %BODYPART!",
		"%VICTIM's %BODYPART is turned to char!",
	)
	sound_effect = 'sound/combat/crit.ogg'
	whp = 60
	woundpain = 35
	bleed_rate = 0.6
	clotting_rate = 0
	clotting_threshold = null
	sewn_clotting_threshold = 0
	sew_threshold = 10
	can_sew = TRUE
	can_cauterize = FALSE
	disabling = TRUE
	critical = TRUE
	mortal = FALSE
	passive_healing = 0
	sleep_healing = 0.5
	mob_overlay = "charred"


/datum/wound/burn/charred/on_mob_gain(mob/living/affected, damage)
	. = ..()
	affected.emote("paincrit", TRUE)
	var/slowdown_amount = clamp(woundpain * 0.5, 10, 20)
	affected.Slowdown(slowdown_amount)
	shake_camera(affected, 3, 3)
	// Scale the wound based on damage dealt - charred is the most severe
	if(damage)
		whp += damage * 1.2
		woundpain += damage * 0.7
		bleed_rate = min(0.6 + (damage * 0.02), 1.2)
		// Higher damage can potentially disable the limb
		if(damage > 40)
			disabling = TRUE

/datum/wound/burn/charred/worsen_wound(amount)
	owner.emote("paincrit", TRUE)
	var/slowdown_amount = clamp(woundpain * 0.5, 10, 20)
	owner.Slowdown(slowdown_amount)
	shake_camera(owner, 3, 3)
	if(amount)
		whp += amount * 1.2
		woundpain += amount * 0.7
		bleed_rate = min(0.6 + (bleed_rate + amount * 0.02), 1.2)
		// Higher damage can potentially disable the limb
		if(whp > 40)
			disabling = TRUE
