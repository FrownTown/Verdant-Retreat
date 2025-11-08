/obj/item/organ/lungs
	var/failed = FALSE
	var/operated = FALSE	//whether we can still have our damages fixed through surgery
	name = "lungs"
	icon_state = "lungs"
	zone = BODY_ZONE_CHEST
	slot = ORGAN_SLOT_LUNGS
	gender = PLURAL
	w_class = WEIGHT_CLASS_SMALL

	healing_factor = STANDARD_ORGAN_HEALING
	decay_factor = STANDARD_ORGAN_DECAY

	high_threshold_passed = "<span class='warning'>I feel some sort of constriction around my chest as my breathing becomes shallow and rapid.</span>"
	now_fixed = "<span class='warning'>My lungs seem to once again be able to hold air.</span>"
	high_threshold_cleared = "<span class='info'>The constriction around my chest loosens as my breathing calms down.</span>"

	sellprice = 20

/obj/item/organ/lungs/on_life()
	..()
	var/mob/living/carbon/C = owner
	if(!istype(C))
		return

	if(damage > 0)
		var/damage_ratio = damage / maxHealth
		if(damage < low_threshold)
			C.adjustOxyLoss(damage_ratio * 0.5)
			if(prob(3))
				C.emote("cough")
		else if(damage < high_threshold)
			C.adjustOxyLoss(damage_ratio * 1.5)
			if(prob(5))
				C.emote("cough")
			if(prob(2) && !C.stat)
				to_chat(C, span_warning("My chest hurts."))
		else if(damage < maxHealth)
			C.adjustOxyLoss(damage_ratio * 3)
			if(prob(8))
				C.emote("cough")
			if(prob(5) && !C.stat)
				to_chat(C, span_warning("I can barely breathe!"))

	if((!failed) && ((organ_flags & ORGAN_FAILING)))
		if(C.stat == CONSCIOUS)
			C.visible_message(span_danger("[C] clutches [C.p_their()] throat, gasping!"), \
								span_userdanger("I CAN'T BREATHE!"))
		failed = TRUE
		C.adjustOxyLoss(4)
	else if(!(organ_flags & ORGAN_FAILING))
		failed = FALSE
	return

/obj/item/organ/lungs/prepare_eat()
	var/obj/S = ..()
	return S

/obj/item/organ/lungs/plasmaman
	name = "plasma filter"
	desc = ""
	icon_state = "lungs-plasma"


/obj/item/organ/lungs/slime
	name = "vacuole"
	desc = ""

/obj/item/organ/lungs/golem
	name = "golem aersource"
	desc = "A complex hollow crystal, which courses with air through unknowable means. Steam wisps around it in a vortex."
	icon_state = "lungs-con"
	
/obj/item/organ/lungs/t1
	name = "completed lungs"
	icon_state = "lungs"
	desc = "The perfect art, it feels... Completed."
	sellprice = 100

/obj/item/organ/lungs/t2
	name = "blessed lungs"
	icon_state = "lungs"
	desc = "They accepted this heresy to defeat a greater heresy. They call it a blessing, but we all know it’s not…"
	sellprice = 200

/obj/item/organ/lungs/t3
	name = "corrupted lungs"
	icon_state = "lungs"
	desc = "A cursed, perverted artifact. It can serve you well—what sacrifice are you willing to offer to survive?"
	maxHealth = 2 * STANDARD_ORGAN_THRESHOLD
	sellprice = 300

/datum/status_effect/buff/t1lungs
	id = "t1lungs"
	alert_type = /atom/movable/screen/alert/status_effect/buff/t1lungs

/atom/movable/screen/alert/status_effect/buff/t1lungs
	name = "Completed lungs"
	desc = "I have better version of lungs now "

/obj/item/organ/lungs/t1/Insert(mob/living/carbon/M)
	..()
	if(M)
		M.apply_status_effect(/datum/status_effect/buff/t1lungs)
		ADD_TRAIT(M, TRAIT_WATERBREATHING, TRAIT_GENERIC)

/obj/item/organ/lungs/t1/Remove(mob/living/carbon/M, special = 0)
	..()
	if(M.has_status_effect(/datum/status_effect/buff/t1lungs))
		M.remove_status_effect(/datum/status_effect/buff/t1lungs)
		REMOVE_TRAIT(M, TRAIT_WATERBREATHING , TRAIT_GENERIC)

/datum/status_effect/buff/t2lungs
	id = "t2lungs"
	alert_type = /atom/movable/screen/alert/status_effect/buff/t2lungs

/atom/movable/screen/alert/status_effect/buff/t2lungs //your helper against mages but not black king bar
	name = "Blessed lungs"
	desc = "A blessed lungs... Maybe"

/obj/item/organ/lungs/t2/Insert(mob/living/carbon/M)
	..()
	if(M)
		M.apply_status_effect(/datum/status_effect/buff/t2lungs)
		ADD_TRAIT(M, TRAIT_BREADY, TRAIT_GENERIC)
		ADD_TRAIT(M, TRAIT_ZJUMP, TRAIT_GENERIC)
		ADD_TRAIT(M, TRAIT_WATERBREATHING, TRAIT_GENERIC)


/obj/item/organ/lungs/t2/Remove(mob/living/carbon/M, special = 0)
	..()
	if(M.has_status_effect(/datum/status_effect/buff/t2lungs))
		M.remove_status_effect(/datum/status_effect/buff/t2lungs)
		REMOVE_TRAIT(M, TRAIT_BREADY , TRAIT_GENERIC)
		REMOVE_TRAIT(M, TRAIT_ZJUMP , TRAIT_GENERIC)
		REMOVE_TRAIT(M, TRAIT_WATERBREATHING , TRAIT_GENERIC)


/datum/status_effect/buff/t3lungs
    id = "t3lungs"
    alert_type = /atom/movable/screen/alert/status_effect/buff/t3lungs

/atom/movable/screen/alert/status_effect/buff/t3lungs
	name = "Corrupted lungs"
	desc = "The cursed thing is inside me now."


/obj/item/organ/lungs/t3/Insert(mob/living/carbon/M)
	..()
	if(M)
		M.apply_status_effect(/datum/status_effect/buff/t3lungs)
		ADD_TRAIT(M, TRAIT_BREADY, TRAIT_GENERIC)
		ADD_TRAIT(M, TRAIT_LEAPER, TRAIT_GENERIC)
		ADD_TRAIT(M, TRAIT_ZJUMP, TRAIT_GENERIC)
		ADD_TRAIT(M, TRAIT_NOBREATH, TRAIT_GENERIC)
		ADD_TRAIT(M, TRAIT_LONGSTRIDER, TRAIT_GENERIC)


/obj/item/organ/lungs/t3/Remove(mob/living/carbon/M, special = 0)
	..()
	if(M.has_status_effect(/datum/status_effect/buff/t3lungs))
		M.remove_status_effect(/datum/status_effect/buff/t3lungs)
		REMOVE_TRAIT(M, TRAIT_BREADY, TRAIT_GENERIC)
		REMOVE_TRAIT(M, TRAIT_LEAPER, TRAIT_GENERIC)
		REMOVE_TRAIT(M, TRAIT_ZJUMP, TRAIT_GENERIC)
		REMOVE_TRAIT(M, TRAIT_NOBREATH, TRAIT_GENERIC)
		REMOVE_TRAIT(M, TRAIT_LONGSTRIDER, TRAIT_GENERIC)	
