/datum/liquid
	// Liquid variables
	var/name // Name of the type of liquid as a string

	var/color // Color of the liquid if we want to override it, uses the color of the reagent by default
	var/reagent // Reagent associated with this fluid, if any. Null by default. Should be a typepath, not an instance.
	var/fluid_flags = 0
	var/flow_permille = 1000

/datum/liquid/water
	name = "Water"
	reagent = /datum/reagent/water
	fluid_flags = FLUID_CONDUCTIVE | FLUID_PERMEATING

/datum/liquid/fuel
	name = "Fuel"
	reagent = /datum/reagent/fuel
	fluid_flags = FLUID_FLAMMABLE

/datum/liquid/lava
	name = "Lava"
	color = "#e25822"
	flow_permille = 250

/datum/liquid/acid
	name = "Acid"
	color = "#56ff0d"
	fluid_flags = FLUID_CORROSIVE

/datum/liquid/blood
	name = "Blood"
	reagent = /datum/reagent/blood
	fluid_flags = FLUID_PERMEATING

/datum/liquid/murk
	name = "Murk"
	color = "#705a43"
	reagent = /datum/reagent/water/gross
	fluid_flags = FLUID_PERMEATING