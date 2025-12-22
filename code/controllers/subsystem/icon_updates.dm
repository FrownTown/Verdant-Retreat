PROCESSING_SUBSYSTEM_DEF(iconupdates)
	name = "icon_updates"
	wait = 1
	flags = SS_NO_INIT
	priority = FIRE_PRIORITY_MOBS
	processing_flag = PROCESSING_ICON_UPDATES

	var/list/image_removal_schedule = list()

/datum/controller/subsystem/processing/iconupdates/fire(resumed = 0)
	if(!resumed)
		process_image_cleanup()

	if (!resumed || !src.currentrun.len)
		src.currentrun = processing.Copy()


	var/list/currentrun = src.currentrun

	while(length(currentrun))
		var/mob/living/carbon/thing = currentrun[length(currentrun)]
		currentrun.len--
		if (!thing || QDELETED(thing))
			processing -= thing
			if(MC_TICK_CHECK)
				return
			continue
		
		if(thing.pending_icon_updates)
			thing.process_pending_icon_updates()
		
		if(!thing.pending_icon_updates)
			STOP_PROCESSING(SSiconupdates, thing)
		
		if(MC_TICK_CHECK)
			return

/datum/controller/subsystem/processing/iconupdates/proc/process_image_cleanup()
	if(!length(image_removal_schedule))
		return

	var/current_time = world.time
	var/list/images_to_remove = list()

	for(var/image/I as anything in image_removal_schedule)
		if(!I || QDELETED(I))
			var/list/client_schedule = image_removal_schedule[I]
			if(client_schedule && I)
				for(var/client/C as anything in client_schedule)
					if(C && !QDELETED(C))
						C.images -= I
			images_to_remove += I
			continue

		var/list/client_schedule = image_removal_schedule[I]
		if(!client_schedule || !length(client_schedule))
			images_to_remove += I
			continue

		var/list/clients_to_remove = list()

		for(var/client/C as anything in client_schedule)
			if(!C || QDELETED(C))
				clients_to_remove += C
				continue

			var/expire_time = client_schedule[C]
			if(current_time >= expire_time)
				C.images -= I
				clients_to_remove += C

		for(var/client/C as anything in clients_to_remove)
			client_schedule -= C

		if(!length(client_schedule))
			images_to_remove += I

	for(var/image/I as anything in images_to_remove)
		image_removal_schedule -= I
