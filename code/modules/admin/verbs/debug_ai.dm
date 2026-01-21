/client/var/debug_ai_tree_active = FALSE
/client/var/list/ai_debug_images

/client/proc/debug_ai_tree()
	set name = "Debug AI Tree"
	set category = "Debug"

	debug_ai_tree_active = !debug_ai_tree_active
	to_chat(src, "<span class='notice'>AI Tree Debug: [debug_ai_tree_active ? "ON" : "OFF"]</span>")

	if(debug_ai_tree_active)
		start_ai_debug_loop()
	else
		clear_ai_debug_images()

/client/proc/clear_ai_debug_images()
	for(var/i in ai_debug_images)
		var/image/I = ai_debug_images[i]
		qdel(I)
	QDEL_NULL(ai_debug_images)

/client/proc/start_ai_debug_loop()
	set waitfor = FALSE
	ai_debug_images = list()
	while(debug_ai_tree_active)
		update_ai_debug_images()
		sleep(5)

/client/proc/update_ai_debug_images()
	var/list/current_mobs = list()
	
	for(var/mob/living/M in GLOB.npc_list)
		if(M.z != mob.z) continue
		if(!M.ai_root) continue
		
		current_mobs[M] = TRUE
		
		var/image/I = ai_debug_images[M]
		if(!I)
			I = image(loc = M)
			I.pixel_y = 32
			I.plane = HUD_PLANE
			I.layer = ABOVE_ALL_MOB_LAYER
			I.maptext_width = 128
			I.maptext_x = -32
			I.maptext_y = 4
			ai_debug_images[M] = I
			src << I
			
		var/txt = M.ai_root.active_node_text || "Idle"
		// Display the currently running node
		I.maptext = "<div style='text-align: center; color: #55ff55; font-size: 6pt; -dm-text-outline: 1px black;'>[txt]</div>"

	// Cleanup images for mobs that are no longer valid or relevant
	for(var/m in ai_debug_images)
		if(!current_mobs[m])
			var/image/I = ai_debug_images[m]
			qdel(I)
			ai_debug_images -= m
