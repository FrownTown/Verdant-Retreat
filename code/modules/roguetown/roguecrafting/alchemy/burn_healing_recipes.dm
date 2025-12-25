// CRAFTING RECIPES FOR BURN HEALING ITEMS

// BURN SALVE - Use for healing normal and electrical burns

/datum/crafting_recipe/roguetown/alchemy/burn_salve
	name = "burn salve"
	result = /obj/item/natural/burn_salve
	reqs = list(
		/obj/item/alch/berrypowder = 2,
		/obj/item/reagent_containers/food/snacks/fat = 1,
	)
	craftdiff = 0
	subtype_reqs = TRUE

// Alternative recipe using swampweed
/datum/crafting_recipe/roguetown/alchemy/burn_salve_swampweed
	name = "burn salve (swampweed)"
	result = /obj/item/natural/burn_salve
	reqs = list(
		/obj/item/alch/swampdust = 2,
		/obj/item/reagent_containers/food/snacks/fat = 1,
	)
	craftdiff = 0
	subtype_reqs = TRUE

// WARMING POULTICE - Made with salt and cloth, heat then apply to heal frostbite

/datum/crafting_recipe/roguetown/alchemy/warming_poultice
	name = "warming poultice"
	result = /obj/item/natural/warming_poultice
	reqs = list(
		/obj/item/natural/cloth = 1,
		/obj/item/reagent_containers/powder/salt = 1,
		/obj/item/reagent_containers/food/snacks/grown/berries/rogue = 1,
	)
	craftdiff = 1
	subtype_reqs = TRUE

// NEUTRALIZING POWDER - Heals acid burns

/datum/crafting_recipe/roguetown/alchemy/neutralizing_powder
	name = "neutralizing powder"
	result = /obj/item/natural/neutralizing_powder
	reqs = list(
		/obj/item/ash = 2,
		/obj/item/reagent_containers/powder/salt = 1,
	)
	craftdiff = 0
	subtype_reqs = TRUE

// Alternative with bones (calcium carbonate)
/datum/crafting_recipe/roguetown/alchemy/neutralizing_powder_bone
	name = "neutralizing powder (bone)"
	result = /obj/item/natural/neutralizing_powder
	reqs = list(
		/obj/item/alch/bonemeal = 1,
		/obj/item/ash = 1,
	)
	
	craftdiff = 1
	subtype_reqs = TRUE

// MEDICATED BANDAGES - Cloth soaked in healing herbs

/datum/crafting_recipe/roguetown/alchemy/burn_bandage
	name = "burn-cleansing bandage"
	result = /obj/item/natural/cloth/burn_bandage
	reqs = list(
		/obj/item/natural/cloth = 1,
		/obj/item/alch/berrypowder = 1,
	)
	craftdiff = 0
	subtype_reqs = TRUE

// Swampweed style
/datum/crafting_recipe/roguetown/alchemy/burn_bandage_swampweed
	name = "burn-cleansing bandage (swampweed)"
	result = /obj/item/natural/cloth/burn_bandage
	reqs = list(
		/obj/item/natural/cloth = 1,
		/obj/item/alch/swampdust = 1,
	)
	craftdiff = 0
	subtype_reqs = TRUE
