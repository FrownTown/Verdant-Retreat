/datum/charflaw/monsterbait
	name = "Monster Pheromones"
	desc = "Creatures of the dark seem strangely drawn to me."

/datum/charflaw/monsterbait/on_mob_creation(mob/user)
	ADD_TRAIT(user, TRAIT_MONSTERBAIT, TRAIT_GENERIC)
