/obj/item/reagent_containers/lux
	name = "lux"
	desc = "The stuff of life and souls, retrieved from within a hopefully-willing donor. It's a bit clammy and squishy, like a half-fried egg."
	icon = 'icons/roguetown/items/produce.dmi'
	icon_state = "lux"
	item_state = "lux"
	possible_transfer_amounts = list()
	volume = 15
	list_reagents = list(/datum/reagent/vitae = 5)
	grind_results = list(/datum/reagent/vitae = 5)
	sellprice = 90

/obj/item/reagent_containers/lux/attack(mob/living/M, mob/user)
	if(!user.cmode && ishuman(M))//golem revival by just slopping lux into their body, they can't be cut open for surgery
		var/mob/living/carbon/human/H = M
		if(H.construct)
			var/obj/item/organ/heart/heart = H.getorganslot(ORGAN_SLOT_HEART)
			if(!heart)
				to_chat(user, "[H] is missing their heart!")
				return FALSE
			if(!H.mind)
				to_chat(user, "[H]'s heart is inert.")
				return FALSE
			if(HAS_TRAIT(H, TRAIT_NECRAS_VOW))
				to_chat(user, "[H] has pledged a vow to Necra. This will not work.")
				return FALSE
			user.visible_message(span_danger("[user] presses [src] against [H]."), span_userdanger("I press [src] against [H]'s body. Will [H.p_they()] wake up?"))
			if(do_mob(user, H, 100))//10 seconds, same as lux infusion surgery
				var/mob/dead/observer/spirit = H.get_spirit()
				if(spirit)
					var/mob/dead/observer/ghost = spirit.ghostize()
					qdel(spirit)
					ghost.mind.transfer_to(H, TRUE)
				H.grab_ghost(force = FALSE)
				if(!H.mind.active)
					user.visible_message(span_notice("[user] presses [src] against [H], but nothing happens."), span_danger("I press [src] against [H]'s body, but nothing happens."))
					return
				if(!H.revive(full_heal = FALSE))
					to_chat(user,span_notice("[src] refuses to meld with [H]'s body- [H.p_their()] damage must be too severe still."))
					return
				H.Jitter(100)
				GLOB.scarlet_round_stats[STATS_LUX_REVIVALS]++
				H.update_body()
				H.visible_message(span_notice("[H]'s body becomes animate once more."), span_green("I awake from the void."))
				if(H.mind)
					var/revive_pq = PQ_GAIN_REVIVE
					if(revive_pq && !HAS_TRAIT(H, TRAIT_IWASREVIVED) && user?.ckey)
						adjust_playerquality(revive_pq, user.ckey)
						ADD_TRAIT(H, TRAIT_IWASREVIVED, "[type]")
				qdel(src)
		else
			. = ..()
	else
		. = ..() //normal hit

/datum/reagent/vitae
	name = "Vitae"
	description = "The extracted and processed essence of life."
	color = "#7d8e98" // rgb: 96, 165, 132
	overdose_threshold = 10
	metabolization_rate = 0.1

/datum/reagent/vitae/overdose_process(mob/living/M)
	M.adjustOrganLoss(ORGAN_SLOT_HEART, 0.25*REM)
	M.adjustFireLoss(0.25*REM, 0)
	..()
	. = 1

/datum/reagent/vitae/on_mob_life(mob/living/carbon/M)
	if(M.has_flaw(/datum/charflaw/addiction/junkie))
		M.sate_addiction()
	M.apply_status_effect(/datum/status_effect/buff/vitae)
	..()
