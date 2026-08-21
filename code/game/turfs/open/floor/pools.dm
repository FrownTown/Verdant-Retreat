/turf/open/floor/rogue/pool
	var/pool_liquid_type
	var/pool_source_rate = 0

/turf/open/floor/rogue/pool/Initialize()
	. = ..()
	if(!cell)
		cell = new /cell(src)
		cell.InitLiquids()
	var/datum/liquid/fluid = cell.get_fluid_datum(pool_liquid_type)
	if(fluid)
		cell.fluid_volume[fluid] = MAX_FLUID_VOLUME
	cell.set_contain_max(MAX_FLUID_VOLUME)
	if(pool_source_rate)
		cell.make_liquid_source(pool_source_rate, pool_liquid_type)
	SSliquid.update_fluidsum(src)
	SSliquid.cell_index[src] = TRUE
	ensure_liquid_overlay()

/turf/open/floor/rogue/pool/lava
	name = "molten pool"
	icon = 'icons/turf/roguefloor.dmi'
	icon_state = "lava"
	light_outer_range = 4
	light_power = 0.75
	light_color = LIGHT_COLOR_LAVA
	pool_liquid_type = /datum/liquid/lava
	pool_source_rate = 10

/turf/open/floor/rogue/pool/acid
	name = "acid pool"
	icon = 'icons/turf/roguefloor.dmi'
	icon_state = "acid"
	light_outer_range = 4
	light_power = 1
	light_color = "#56ff0d"
	pool_liquid_type = /datum/liquid/acid
	pool_source_rate = 10

/turf/open/floor/rogue/pool/blood
	name = "pool of blood"
	icon = 'icons/turf/roguefloor.dmi'
	icon_state = "dirtW2"
	pool_liquid_type = /datum/liquid/blood

/turf/open/floor/rogue/pool/murk
	name = "murky pool"
	icon = 'icons/turf/roguefloor.dmi'
	icon_state = "dirtW2"
	pool_liquid_type = /datum/liquid/murk
	pool_source_rate = 10
