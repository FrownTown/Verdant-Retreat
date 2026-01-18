/*
 ██▓     ██▓  █████   █    ██  ██▓▓█████▄   ██████
▓██▒    ▓██▒▒██▓  ██▒ ██  ▓██▒▓██▒▒██▀ ██▌▒██    ▒
▒██░    ▒██▒▒██▒  ██░▓██  ▒██░▒██▒░██   █▌░ ▓██▄
▒██░    ░██░░██  █▀ ░▓▓█  ░██░░██░░▓█▄   ▌  ▒   ██▒
░██████▒░██░░▒███▒█▄ ▒▒█████▓ ░██░░▒████▓ ▒██████▒▒
░ ▒░▓  ░░▓  ░░ ▒▒░ ▒ ░▒▓▒ ▒ ▒ ░▓   ▒▒▓  ▒ ▒ ▒▓▒ ▒ ░
░ ░ ▒  ░ ▒ ░ ░ ▒░  ░ ░░▒░ ░ ░  ▒ ░ ░ ▒  ▒ ░ ░▒  ░ ░
  ░ ░    ▒ ░   ░   ░  ░░░ ░ ░  ▒ ░ ░ ░  ░ ░  ░  ░
	░  ░ ░      ░       ░      ░     ░          ░
								   ░
									- By Plasmatik

PORTABLE STANDALONE VERSION - Liquid Simulation Subsystem
==========================================================

This is a self-contained, portable version of the liquid subsystem originally
created for IS12 Reborn. It can be integrated into any BYOND codebase with
appropriate adaptations.

ORIGINAL HEADER:
================
This subsystem is used to simulate simple fluid dynamics using cellular automata in a manner similar to Dwarf Fortress.
Unlike DF, this system operates using float values and represents discrete fluid levels as continuous ranges instead of integers.
This is because I suck at coding and could not figure out a way to prevent rounding errors when trying to use discrete values, knock on wood.
So instead, rounding errors just build up in a buffer and get redistributed over time.

Many variables are kept on turf.cell because it is faster than using some abstract datastructure. It also makes it easy to check those variables on turfs to make cell do things.
Fluid types are checked in sequence based on the fluid_volume and new_volume associative lists on turfs' liquid datums. There is a global list of fluid types in _defines/liquid.dm  for turf initialization to refer to,
So that turf/Initialize() doesn't need to be altered when / if new fluid types get added.

I wrote all of this myself from scratch, and would prefer if this particular system remained outside of open source codebases. Please do not publicly host this code without asking me.


DEPENDENCIES
============
This system requires the following to be implemented in your codebase:
- Cell datums attached to turfs (turf.cell)
- Liquid datum types with volume tracking
- Pool manager system (GLOB.pool_manager)
- Liquid registry system (GLOB.liquid_registry)
- Liquid debug manager (null
- Liquid manager (GLOB.liquid_manager)
- Vector datum for flow calculations
- Standard BYOND subsystem architecture (master controller)

FEATURES
========
- Dwarf Fortress-style fluid simulation with cellular automata
- Pressure flow system (hydraulic teleportation)
- Flow interaction with objects and mobs
- Pool-based fluid optimization
- Efficient pressure job pooling for performance
- Multi-phase processing with state validation
- Open space (multi-z) fluid dynamics
- Flow vector modification support for rivers/currents

ORIGINAL AUTHOR: Plasmatik
LICENSE: Restricted - Do not publicly host without permission
PORTED: 2026-01-17
*/

PROCESSING_SUBSYSTEM_DEF(liquid)
	name = "liquid"
	priority = SS_PRIORITY_LIQUID
	init_order = INIT_ORDER_LIQUID
	wait = 1 // Needs to run every tick to avoid synchronization issues with the disjointed set implementation, but shouldn't hurt performance with all the optimizations
	runlevels = RUNLEVELS_DEFAULT
	flags = SS_NO_FIRE//SS_KEEP_TIMING
	var/list/liquid_sources
	var/list/liquid_sinks
	var/remove_cells_timer = 0
	var/list/cell_index
	var/list/sleeping_cells
	var/list/dirty

	var/list/process_queue
	var/list/reset_queue

	var/phase = 1
	var/prcs_idx = 1
	can_fire = FALSE

	// State validation tracking
	var/list/cells_in_processing
	// Note: cells_pending_sync removed as volume synchronization is now direct
	// Kept references in pool manager and debug systems are legacy and safe to ignore

	// Enhanced pressure job pool management with lifecycle tracking
	var/list/pressure_job_pool  // Recycled pressure_job datums
	var/pressure_job_pool_size = 0  // Current pool size for monitoring
	var/pressure_job_pool_max = 25  // Increased from 10 for larger maps
	var/pressure_job_pool_hits = 0   // Pool reuse statistics
	var/pressure_job_pool_misses = 0 // Pool allocation statistics
	var/pressure_job_lifecycle_timer = 0 // Timer for pool cleanup

	// Resource management
	var/max_cells_per_tick = 200 // Maximum cells to process per tick before splitting

	// Vector objects for performance optimization (moved from static globals)
	var/vector/flow_vector_buffer
	var/vector/neighbor_vector_buffer

/datum/controller/subsystem/processing/liquid/Initialize()
	. = ..()
	NEW_SS_GLOBAL(SSliquid)

	liquid_sources = new
	liquid_sinks = new
	cell_index = new
	sleeping_cells = new
	process_queue = new
	reset_queue = new
	pressure_job_pool = new
	dirty = new
	cells_in_processing = new
	// cells_pending_sync initialization removed - no longer used with direct volume sync

	// Initialize vector buffers
	flow_vector_buffer = vector(0, 0)
	neighbor_vector_buffer = vector(0, 0)


	GLOB.liquid_registry.refresh_registry()

	for(var/turf/T in world) // You can't stop me from doing this. No one can stop me from doing this. Mwahahaha
		if(!T.cell)
			T.cell = new /cell(T)
			T.cell.InitLiquids()

/datum/controller/subsystem/processing/liquid/fire(resumed = 0, no_mc_tick = FALSE)
	MC_SPLIT_TICK_INIT(3)

	// Phase 1: Populate process_queue and reset_queue
	if(phase == 1)
		// Clear processing state tracking from previous cycle
		cells_in_processing.len = 0

		for(var/i = prcs_idx, i <= length(cell_index), i++)
			var/turf/T = get_key_by_index(cell_index, i)
			if(!T) continue

			dirty += T

			// Handle sleeping cells with proper state validation
			if(sleeping_cells[T])
				sleeping_cells -= T

			if((T.cell.fluid_flags & FLUID_MOVED) == 0)
				process_queue += T
			else
				reset_queue += T

			prcs_idx++

			if(no_mc_tick)
				CHECK_TICK
			else if(MC_TICK_CHECK)
				return

		if(prcs_idx > length(cell_index))
			prcs_idx = 1
			phase = 2

		if(!no_mc_tick)
			MC_SPLIT_TICK

	// Phase 2: Process cells in the queue
	if(phase == 2)
		while(length(process_queue))
			var/turf/cell = pick_n_take(process_queue)

			// Process the cell
			cells_in_processing += cell
			update_cell(cell)

			for(var/datum/liquid/fluid in cell.cell.fluid_volume)
				cell.cell.fluid_volume[fluid] += cell.cell.new_volume[fluid]
				cell.cell.new_volume[fluid] = 0
			cell.cell.new_fluidsum = 0

			cell.cell.fluid_flags &= ~FLUID_MOVED
			update_fluidsum(cell, FALSE)

			// Remove from processing tracking
			cells_in_processing -= cell

			prcs_idx++

			if(no_mc_tick)
				CHECK_TICK
			else if(MC_TICK_CHECK)
				return

		if(prcs_idx > length(process_queue))
			prcs_idx = 1
			phase = 3

		if(!no_mc_tick)
			MC_SPLIT_TICK

	// Phase 3: Process pressure flow (DF-style teleportation!)
	if(phase == 3)
		process_pressure_flow()

		if(!no_mc_tick)
			MC_SPLIT_TICK

		phase = 4

	// Phase 4: Reset fluid flags and finalize updates
	if(phase == 4)
		update_pools()

		// Process continuous liquid behaviors for mobs standing in liquid pools
		GLOB.pool_manager.process_continuous_behaviors()

		// Process floor chemical reactions if dynamic liquids are enabled
		GLOB.pool_manager.process_floor_reactions()

		// Simple reset queue processing
		for(var/turf/T as anything in reset_queue)
			T.cell.fluid_flags &= ~FLUID_MOVED
		reset_queue.len = 0

		for(var/turf/T as anything in cell_index)
			update_cell_image(T)

		remove_cells_timer++
		if(remove_cells_timer >= 50)
			remove_unwanted_cells()
			// Clean up empty pools less frequently to allow pools to persist
			GLOB.pool_manager.cleanup_empty_pools()
			remove_cells_timer = 0

		// Update processing time for debug manager

		phase = 1
		if(!no_mc_tick)
			MC_SPLIT_TICK

/datum/controller/subsystem/processing/liquid/proc/update_pools()
	var/list/dirty = list()
	for (var/turf/T as anything in cell_index)
		// Include turfs that moved OR have significant liquid (for static pools)
		if (T.cell.fluid_flags & FLUID_MOVED || T.cell.fluidsum >= MIN_FLUID_VOLUME)
			dirty |= T

	// Add sleeping cells to the dirty list to keep pool_manager aware of them
	for(var/turf/T as anything in sleeping_cells)
		dirty |= T

	GLOB.pool_manager.update_pools(dirty)

/datum/controller/subsystem/processing/liquid/proc/get_pool(turf/T)
	return GLOB.pool_manager.get_pool(T)

/datum/controller/subsystem/processing/liquid/proc/get_pool_avg(list/pool)
	return GLOB.pool_manager.get_pool_avg_fluid(pool)

/datum/controller/subsystem/processing/liquid/proc/spread_shock(mob/living/carbon/C, turf/T, shock_damage, def_zone, siemens_coeff)
	return GLOB.liquid_registry.execute_flag_behavior(FLUID_CONDUCTIVE, "conduct_shock", C, T, shock_damage, def_zone, siemens_coeff)


/datum/controller/subsystem/processing/liquid/proc/remove_unwanted_cells()
	for(var/turf/T as anything in cell_index)
		if(!can_process_fluid(T))
			T.cell.fluid_flags &= ~FLUID_MOVED
			cell_index -= T
			if(get_fluid_level(T) > FLUID_EMPTY && !(T in sleeping_cells))
				sleeping_cells[T] = TRUE

/datum/controller/subsystem/processing/liquid/proc/can_process_fluid(turf/T) as num
	if(!T?.cell)
		return FALSE
	return isopenspace(T) && get_fluid_level(T) > FLUID_EMPTY || !isopenspace(T) && (T.cell.fluid_flags & FLUID_MOVED || T.cell.new_fluidsum > MIN_FLUID_VOLUME)

/datum/controller/subsystem/processing/liquid/proc/get_vector_to_neighbor(turf/T, turf/neighbor) as /vector
	if(!T || !neighbor)
		return vector(0, 0)

	var/dx = neighbor.x - T.x
	var/dy = neighbor.y - T.y

	// Handle case where T and neighbor are the same position
	if(dx == 0 && dy == 0)
		return vector(0, 0)

	// Use subsystem vector buffer to reduce allocations
	neighbor_vector_buffer = vector(dx, dy)
	neighbor_vector_buffer.Normalize()

	return vector(neighbor_vector_buffer.x, neighbor_vector_buffer.y)


/datum/controller/subsystem/processing/liquid/proc/get_flow_multiplier(turf/T, turf/neighbor, vector/flow_vector) as num
	if(!flow_vector || !T?.cell || !neighbor?.cell)
		return 0

	var/vector/neighbor_vector = get_vector_to_neighbor(T, neighbor)
	if(!neighbor_vector)
		return 0

	// Apply per-turf flow vector modifications if they exist, e.g., for rivers and so on - otherwise we just skip these
	if(T.cell.flow_vector_modification)
		flow_vector.x *= (T.cell.flow_vector_modification.x * T.cell.flow_vector_modification.z) // This is where we use the z axis as a multiplier, which lets flow vector modifiers exist as a vector datum instead of a list
		flow_vector.y *= (T.cell.flow_vector_modification.y * T.cell.flow_vector_modification.z)

	if(neighbor.cell.flow_vector_modification)
		neighbor_vector.x *= (neighbor.cell.flow_vector_modification.x * neighbor.cell.flow_vector_modification.z)
		neighbor_vector.y *= (neighbor.cell.flow_vector_modification.y * neighbor.cell.flow_vector_modification.z)

	var/flow_multiplier = (flow_vector.Dot(neighbor_vector) + 2) / 3

	flow_multiplier = max(flow_multiplier, 0.5) // A minimum flow rate here lets us make pools even out faster.

	return flow_multiplier

/datum/controller/subsystem/processing/liquid/proc/update_cell(turf/T)
	if(!T?.cell)
		return FALSE

	for(var/datum/liquid/fluid as anything in T.cell.fluid_volume)
		var/current_amount = T.cell.fluid_volume[fluid]
		if(GET_TOTAL_FLUID(T) <= 0)
			return // This is so that if a cell gets emptied during a cycle, we won't bother to update it on the next loop if it's still empty

		// Retrieve viable neighbors and calculate average fluid amount
		var/list/neighbors = list()

		for(var/turf/neighbor as anything in T)
			if(neighbor.density)
				continue
			neighbors += neighbor

		var/average_amount = get_average_amount(T, neighbors, current_amount)

		// Calculate the flow vector for fluid movement direction and speed
		var/vector/flow_vector = calculate_flow_vector(T, neighbors, current_amount)

		// Calculate transfer amounts to neighbors individually
		var/list/transfer_out = calculate_transfer_out(T, neighbors, flow_vector, current_amount, average_amount, fluid)

		// Handle open space special case first so fluids don't spread before dropping
		handle_open_space(T, current_amount, fluid)

		// Distribute the fluid to neighbors, ensuring even-ish distribution

		distribute_fluid(T, neighbors, transfer_out, current_amount, average_amount, fluid)

		update_fluidsum(T, TRUE)
		T.cell.fluid_flags |= FLUID_MOVED
		cell_index[T] = TRUE


/datum/controller/subsystem/processing/liquid/proc/calculate_flow_vector(turf/T, list/neighbors, current_amount) as /vector
	// Reset subsystem vector buffer instead of creating new one
	flow_vector_buffer = vector(0, 0)

	for(var/turf/neighbor as anything in neighbors)
		if(!neighbor?.cell)
			continue
		var/vector/vector_to_neighbor = get_vector_to_neighbor(T, neighbor)
		if(!vector_to_neighbor)
			continue
		var/difference = current_amount - GET_TOTAL_FLUID(neighbor)
		if(difference != 0) // Only add if there's actually a difference to avoid type mismatch
			flow_vector_buffer += vector_to_neighbor * difference // Scalar multiplication: vector * scalar

	// Only normalize if the vector has magnitude
	if(flow_vector_buffer.x != 0 || flow_vector_buffer.y != 0)
		flow_vector_buffer.Normalize()

	// Return a copy to prevent external modification of our buffer
	return vector(flow_vector_buffer.x, flow_vector_buffer.y)

/datum/controller/subsystem/processing/liquid/proc/get_neighbors(turf/T) as /list
	var/list/neighbors = list()
	for(var/turf/neighbor as anything in T)
		// Check for directional barriers between turfs (windows/doors)
		if(T.LinkBlocked(T, neighbor))
			continue
		// Check if destination turf blocks flow
		if(!neighbor.blocks_flow())
			neighbors += neighbor
	return neighbors

/datum/controller/subsystem/processing/liquid/proc/get_average_amount(turf/T, list/neighbors, current_amount) as num
	var/average_amount = current_amount
	for(var/turf/neighbor as anything in neighbors)
		average_amount += GET_TOTAL_FLUID(neighbor)
	if(length(neighbors) > 0)
		average_amount /= (length(neighbors) + 1)
	return average_amount

/datum/controller/subsystem/processing/liquid/proc/calculate_transfer_out(turf/T, list/neighbors, vector/flow_vector, current_amount, average_amount, fluid) as /list
	var/list/transfer_out = list()
	var/transfer_threshold = 2
	for(var/turf/neighbor as anything in neighbors)
		var/difference = current_amount - GET_TOTAL_FLUID(neighbor)
		if(difference <= transfer_threshold)
			continue // Skip transfers that are below the threshold

		var/flow_multiplier = get_flow_multiplier(T, neighbor, flow_vector)

		// Apply pool-based speed boost for better equilibration
		var/pool_multiplier = 1.0
		if(GLOB.pool_manager.is_in_same_pool(T, neighbor))
			// Same pool - apply speed boost
			pool_multiplier = 2.0

			// Large pool additional boost with state-aware calculation
			var/pool_size = get_safe_pool_size(T)
			if(pool_size > 0) // Valid pool size
				if(pool_size > 50)
					pool_multiplier = 3.0
				if(pool_size > 100)
					pool_multiplier = 4.0
				else
					pool_multiplier = 1.5

		var/max_transfer = FLUID_MAX_TRANSFER_RATE * pool_multiplier
		var/transfer_amount = min(difference * flow_multiplier * pool_multiplier, T.cell.fluid_volume[fluid], max_transfer)
		transfer_out[neighbor] = max(0, transfer_amount)
	return transfer_out

/datum/controller/subsystem/processing/liquid/proc/distribute_fluid(turf/T, list/neighbors, list/transfer_out, current_amount, average_amount, fluid)
	var/leftover_fluid = 0
	var/total_transferred_out = 0
	// First, sum up the total transfer out to know how much is moving
	for(var/turf/neighbor as anything in neighbors)
		total_transferred_out += transfer_out[neighbor]

	var/total_transferable_amount = Clamp(0, current_amount - average_amount, total_transferred_out)

	var/amount_transferred = 0 // Track the amount of fluid actually transferred

	var/max_neighbors = 4

	for(var/turf/neighbor as anything in neighbors)
		// Normalize the transfer amount by the number of neighbors the cell has.
		// This is to ensure proportional transfer of fluid when less than 4 neighbors are present
		var/transfer_amount = length(neighbors) == max_neighbors ? transfer_out[neighbor] : transfer_out[neighbor] * (max_neighbors / length(neighbors))

		if(transfer_amount < MIN_FLUID_VOLUME)
			continue

		// Adjust based on how much is actually transferable
		if(total_transferred_out > 0)
			transfer_amount = max(0, transfer_amount * (total_transferable_amount / total_transferred_out))

		// Ensure we never transfer enough liquid to exceed the maximum volume
		transfer_amount = min(transfer_amount, MAX_FLUID_VOLUME - neighbor.cell.fluid_volume[GetLiquidInstance(fluid, neighbor)])

		// Now also ensure we do not transfer more than the remaining transferable amount
		transfer_amount = Clamp(0, transfer_amount, total_transferable_amount - amount_transferred)

		var/transfered = Floor(transfer_amount)
		leftover_fluid += fract(transfer_amount)
		if(leftover_fluid > MIN_FLUID_VOLUME)
			transfered += Floor(leftover_fluid)
			leftover_fluid = fract(leftover_fluid)

		// Actually transfer the fluid
		if(transfered > 0)
			T.cell.new_volume[fluid] -= transfered
			neighbor.cell.new_volume[GetLiquidInstance(fluid, neighbor, TRUE)] += transfered
			update_fluidsum(neighbor, TRUE)
			cell_index[neighbor] = TRUE
			amount_transferred += transfered // Update the transferred amount
			neighbor.cell.fluid_flags |= FLUID_MOVED

			// Flow interaction: knock over unanchored things with strong flow
			if(transfered >= 15) // Significant fluid transfer
				handle_flow_interaction(T, neighbor, transfered, FALSE)
		else if(transfered < 0) // This should not ever happen, but if it does, that's bad and we'd better report it
			CRASH("Negative transfer amount was detected in distribute_fluid for turf [T] to neighbor [neighbor]!")

/datum/controller/subsystem/processing/liquid/proc/handle_flow_interaction(turf/source, turf/target, transfer_amount, is_pressure = FALSE, list/pressure_path)
	// Calculate flow direction
	var/flow_dir
	if(is_pressure && pressure_path && length(pressure_path) >= 2)
		// For pressure flow, use the last segment of the pressure path
		var/turf/path_end = pressure_path[length(pressure_path)]
		var/turf/path_prev = pressure_path[length(pressure_path) - 1]
		flow_dir = get_dir(path_prev, path_end)
	else
		// For normal flow, use direct source to target
		flow_dir = get_dir(source, target)

	if(!flow_dir)
		return

	// Check for mobs and objects that can be affected by flow
	for(var/atom/movable/AM in target)

		// Skip everything except mobs and items
		if(!ismob(AM) && !isitem(AM))
			continue

		// Skip anchored objects
		if(AM.anchored)
			continue

		// Calculate flow intensity based on type
		var/intensity_multiplier = 1.0
		var/deviation_range = 15
		var/base_dev_range = list(3, 10)
		var/threshold_strong = 25
		var/threshold_moderate = 15

		if(is_pressure)
			// Pressure flow is more intense
			intensity_multiplier = 1.5 + (length(pressure_path) / 10)
			deviation_range = 25
			base_dev_range = list(5, 15)
			threshold_strong = 20
			threshold_moderate = 15

		var/throw_range = min(is_pressure ? 4 : 3, (transfer_amount * intensity_multiplier) / (is_pressure ? 15 : 20))
		var/throw_speed = min(is_pressure ? 4 : 3, (transfer_amount * intensity_multiplier) / (is_pressure ? 10 : 15))

		var/dx = target.x - source.x
		var/dy = target.y - source.y

		var/deviation = rand(-deviation_range, deviation_range)
		var/angle = arctan(dy, dx) + deviation

		// Calculate target position
		var/target_x = target.x + cos(angle) * throw_range
		var/target_y = target.y + sin(angle) * throw_range
		var/turf/target_turf = locate(target_x, target_y, target.z)
		var/atom/potential_blocker = line_encounters_type(AM, target_turf, null, TRUE)
		if(potential_blocker && potential_blocker.density)
			target_turf = potential_blocker

		if(isliving(AM))
			var/mob/living/L = AM
			var/dev = rand(base_dev_range[1], base_dev_range[2])
			var/amt = max(0, round(dev - 0 / 2))

			if(transfer_amount >= threshold_strong)
				if(is_pressure)
					L.Knockdown(30)
					to_chat(L, "<span class='danger'>A surge of pressurized liquid blasts into you with tremendous force!</span>")
				else
					L.Knockdown(20)
					to_chat(L, "<span class='warning'>The rushing liquid crashes into you and sweeps you away!</span>")
			else if(transfer_amount >= threshold_moderate && is_pressure)
				L.Knockdown(10)
				to_chat(L, "<span class='warning'>The pressurized liquid strikes you with considerable force!</span>")
			else
				if(amt > 0)
					amt = round(amt / 2)
				dev = round(dev / 2)
				L.Stun(5)
				if(is_pressure)
					to_chat(L, "<span class='notice'>The flowing liquid pushes against you!</span>")
				else
					to_chat(L, "<span class='notice'>The rushing liquid nearly knocks you off your feet!</span>")

		if(throw_range > 0 && target_turf)
			AM.throw_at(target_turf, throw_range, throw_speed)


/datum/controller/subsystem/processing/liquid/proc/GetLiquidInstance(datum/liquid/fluid, turf/T, buffered = FALSE) as /datum
	if(buffered)
		return locate(fluid.type) in T.cell.new_volume
	else
		return locate(fluid.type) in T.cell.fluid_volume

/datum/controller/subsystem/processing/liquid/proc/handle_open_space(turf/T, current_amount, fluid)
	if(isopenspace(T))
		var/turf/below = GetBelow(T)
		if(!below || below.blocks_flow())
			return

		var/max_transfer_amount = 100 - below.cell.fluidsum

		max_transfer_amount = max(max_transfer_amount, 0)

		var/transfer_amount = min(T.cell.new_volume[fluid], max_transfer_amount)

		if(transfer_amount > 0)
			T.cell.new_volume[fluid] -= transfer_amount
			below.cell.new_volume[GetLiquidInstance(fluid, below, TRUE)] += transfer_amount
			update_fluidsum(below, TRUE)
			below.cell.fluid_flags |= FLUID_MOVED
			cell_index[below] = TRUE

/datum/controller/subsystem/processing/liquid/proc/process_sources()
	for(var/turf/T as anything in liquid_sources)
		for(var/datum/liquid/fluid as anything in T.cell.fluid_volume)
			T.cell.fluid_volume[fluid] += min(MAX_FLUID_VOLUME, T.cell.production_rate)
			update_cell(T)

/datum/controller/subsystem/processing/liquid/proc/process_sinks()
	for(var/turf/T as anything in liquid_sinks)
		for(var/datum/liquid/fluid as anything in T.cell.fluid_volume)
			T.cell.fluid_volume[fluid] = max(T.cell.fluid_volume[fluid] - T.cell.absorption_rate, 0)
			update_cell(T)

/datum/controller/subsystem/processing/liquid/proc/update_fluidsum(turf/T, var/buffered = FALSE)
	var/sum = 0
	if(buffered)
		for(var/datum/liquid/fluid as anything in T.cell.new_volume)
			sum += T.cell.new_volume[fluid]
		T.cell.new_fluidsum = sum
	else
		for(var/datum/liquid/fluid as anything in T.cell.fluid_volume)
			sum += T.cell.fluid_volume[fluid]
		T.cell.fluidsum = sum
		T.cell.last_fluid_level = get_fluid_level(T)

// Update everything version, for calling during init if necessary
/datum/controller/subsystem/processing/liquid/proc/update_fluidsums()
	for(var/turf/T as anything in cell_index)
		var/sum = 0
		for(var/datum/liquid/fluid as anything in T.cell.fluid_volume)
			sum += T.cell.fluid_volume[fluid]
		T.cell.fluidsum = sum
		T.cell.last_fluid_level = get_fluid_level(T)

/datum/controller/subsystem/processing/liquid/proc/get_fluidsums(turf/T) as num
	var/sum = 0
	for(var/datum/liquid/fluid as anything in T.cell.fluid_volume)
		sum += T.cell.fluid_volume[fluid]
	return sum

/datum/controller/subsystem/processing/liquid/proc/get_fluid_level(turf/T) as num
	if(!istype(T) || !T.cell) return FLUID_EMPTY
	var/fluidsum = T.cell.fluidsum

	switch(fluidsum)
		if(0)
			return FLUID_EMPTY
		if(1 to 20)
			return FLUID_VERY_LOW
		if(21 to 30)
			return FLUID_LOW
		if(31 to 40)
			return FLUID_MEDIUM
		if(41 to 55)
			return FLUID_HIGH
		if(56 to 60)
			return FLUID_VERY_HIGH
		if(61 to 95)
			return FLUID_FULL
		else
			return FLUID_OVERFLOW

/turf/liquid_source
	name = "Liquid source"

/turf/liquid_source/Initialize()
	. = ..()
	SSliquid.liquid_sources += src
	cell.is_liquid_source = TRUE
	cell.production_rate = 1  // Amount of liquid produced per tick

/turf/liquid_source/Destroy()
	SSliquid.liquid_sources -= src
	return ..()

/turf/liquid_sink
	name = "Liquid sink"

/turf/liquid_sink/Initialize()
	. = ..()
	SSliquid.liquid_sinks += src
	cell.is_liquid_sink = TRUE
	cell.absorption_rate = 1  // Amount of liquid absorbed per tick

/turf/liquid_sink/Destroy()
	SSliquid.liquid_sinks -= src
	return ..()

/datum/controller/subsystem/processing/liquid/proc/update_cell_image(turf/T) // This is for manually forcing turfs to update their fluid overlay for debugging purposes
	var/datum/liquid/mostfluid = T.get_highest_fluid_by_volume()

	if(mostfluid)
		T.liquid_overlay.color = mostfluid.color

	var/fluid_level = get_fluid_level(T)
	switch(fluid_level)
		if(FLUID_EMPTY) T.liquid_overlay.alpha = 0
		if(FLUID_VERY_LOW) T.liquid_overlay.alpha = 80
		if(FLUID_LOW) T.liquid_overlay.alpha = 100
		if(FLUID_MEDIUM) T.liquid_overlay.alpha = 115
		if(FLUID_HIGH) T.liquid_overlay.alpha = 145
		if(FLUID_VERY_HIGH) T.liquid_overlay.alpha = 185
		if(FLUID_FULL)
			if(isopenspace(T) && GET_FLUID_LEVEL(T) > FLUID_EMPTY)
				T.liquid_overlay.alpha = 125
				T.liquid_overlay.color = T.liquid_overlay.color
				T.liquid_overlay.alpha = 80
			else
				T.liquid_overlay.alpha = 205
		if(FLUID_OVERFLOW)
			if(isopenspace(T) && GET_FLUID_LEVEL(T) > FLUID_EMPTY)
				T.liquid_overlay.alpha = 125
				T.liquid_overlay.color = T.liquid_overlay.color
				T.liquid_overlay.alpha = 80
			else
				T.liquid_overlay.alpha = 235

	if((T.cell.last_fluid_level < fluid_level) && (fluid_level >= FLUID_FULL) || (T.cell.last_fluid_level > fluid_level) && (fluid_level < FLUID_FULL))
		var/list/queue = list()
		var/list/pool = get_pool(T)
		var/pool_avg = get_pool_avg(pool)
		if(pool_avg > 70) queue[pool] = TRUE
		if(length(queue)) for(var/list/p as anything in queue) for(var/turf/in_pool as anything in p) in_pool.liquid_overlay.update_icon()


/datum/controller/subsystem/processing/liquid/proc/convert_fluid_to_reagent(datum/liquid/fluid, amount, atom/container, turf/T)
	return GLOB.liquid_manager.convert_fluid_to_reagent(fluid, amount, container, T)

/datum/controller/subsystem/processing/liquid/proc/convert_reagent_to_fluid(reagent_type, amount, atom/container, turf/T)
	return GLOB.liquid_manager.convert_reagent_to_fluid(reagent_type, amount, container, T)

//The testing spawner

/obj/item/liquid_spawner
	name = "Liquid Spawner"
	desc = "A magical device that spawns liquid."
	icon_state = "tome"
	var/fluid_amount = 10
	var/fluid = WATER

/obj/item/liquid_spawner/attack_self(mob/user)
	var/turf/T = get_turf(user)
	if(T)
		var/datum/liquid/t_fluid = T.get_fluid_datum(fluid)
		if(!t_fluid) CRASH ("Unable to find fluid data for [fluid] on [T] at [T.x], [T.y], [T.z]!")
		T += t_fluid * fluid_amount
		user.visible_message("[user] uses \the [src] to summon [fluid_amount] units of [t_fluid.name]. Total [t_fluid.name] volume: [T[t_fluid]].")

/obj/item/liquid_spawner/attack_right(mob/user)
	switch(fluid_amount)
		if(10) fluid_amount = 20
		if(20) fluid_amount = 30
		if(30) fluid_amount = 40
		if(40) fluid_amount = 50
		if(50) fluid_amount = 10
	to_chat(user, "<span class='notice'>The fluid transfer amount is now [fluid_amount].</span>")

/obj/item/liquid_spawner/ShiftRightClick(mob/user)
	if(fluid == WATER)
		fluid = FUEL
	else
		fluid = WATER
	to_chat(user, "<span class='notice'>The fluid type is now [fluid].</span>")

/obj/effect/liquid
	icon = 'icons/turf/newwater.dmi'
	icon_state = "bottom2"
	plane = GAME_PLANE
	layer = BELOW_MOB_LAYER
	mouse_opacity = 0
	var/list/trims
	var/list/current_trim_dirs

/obj/effect/water/trim/Initialize(direction)
	. = ..()
	dir = direction

/obj/effect/liquid/Initialize()
	. = ..()
	trims = list()
	current_trim_dirs = list()
	for(var/direction in GLOB.cardinals)
		trims["[direction]"] = new /obj/effect/water/trim(direction)
		current_trim_dirs["[direction]"] = FALSE

/obj/effect/liquid/update_icon()
	// Calculate which directions need trims based on current neighbor states
	var/list/needed_trim_dirs = list()
	for(var/direction in GLOB.cardinals)
		needed_trim_dirs["[direction]"] = FALSE

		var/turf/turf_to_check = get_step(src, direction)
		if(!turf_to_check?.cell) // Make sure this doesn't try updating icons before liquid datums get initialized
			continue

		// Skip certain turf types that don't need trims
		if(isopenspace(turf_to_check) || istype(turf_to_check, /turf/open/water) || (istype(turf_to_check, /turf/open/floor) && GET_FLUID_LEVEL(turf_to_check) >= FLUID_FULL))
			continue

		// Check if this direction needs a trim
		if(istype(turf_to_check, /turf/open) && GET_FLUID_LEVEL(turf_to_check) < FLUID_FULL && GET_FLUID_LEVEL(turf_to_check) >= FLUID_VERY_HIGH)
			needed_trim_dirs["[direction]"] = TRUE

	// Check if anything actually changed before modifying vis_contents
	var/changes_needed = FALSE
	for(var/direction in GLOB.cardinals)
		if(current_trim_dirs["[direction]"] != needed_trim_dirs["[direction]"])
			changes_needed = TRUE
			break

	// Only update vis_contents if changes are actually needed
	if(changes_needed)
		// Remove trims that are no longer needed
		for(var/direction in GLOB.cardinals)
			if(current_trim_dirs["[direction]"] && !needed_trim_dirs["[direction]"])
				vis_contents -= trims["[direction]"]
				current_trim_dirs["[direction]"] = FALSE

			// Add trims that are newly needed
			else if(!current_trim_dirs["[direction]"] && needed_trim_dirs["[direction]"])
				vis_contents += trims["[direction]"]
				current_trim_dirs["[direction]"] = TRUE


//================================================================
// --- Pressure Job Datum ---
// Efficient data structure for BFS pressure path tracing,
// based on the A* pathfinding approach but simplified for BFS.
// Reuses single datum per pressure search to minimize allocations.
//================================================================
/pressure_job
	parent_type = /datum
	var/alist/parent = new()        // parent[turf] = source_turf
	var/alist/visited = new()       // visited[turf] = TRUE
	var/list/queue = new()          // simple BFS queue of turfs
	var/start_z = 0                 // z-level constraint for pressure

/pressure_job/proc/Reset()
	parent.len = 0
	visited.len = 0
	queue.len = 0
	start_z = 0

/pressure_job/proc/reconstruct_pressure_path(turf/outlet) as /list
	var/list/path = list(outlet)
	var/turf/current = outlet
	while(parent[current])
		current = parent[current]
		path.Insert(1, current)
	return path

// Pressure flow system - DF-style hydraulic pressure teleportation
/datum/controller/subsystem/processing/liquid/proc/process_pressure_flow()
	var/list/pressure_sources = list()

	// Find all pressure sources (full tiles that could push fluid)
	for(var/turf/T as anything in cell_index)
		if(get_fluid_level(T) >= FLUID_FULL)
			pressure_sources += T

	// Process each pressure source
	for(var/turf/source as anything in pressure_sources)
		process_pressure_from_source(source)

/datum/controller/subsystem/processing/liquid/proc/process_pressure_from_source(turf/source)
	if(!source?.cell || get_fluid_level(source) < FLUID_FULL)
		return

	var/pressure_job/job = get_pressure_job()
	job.start_z = source.z
	job.queue += source
	job.visited[source] = TRUE

	// Trace pressure paths using efficient BFS
	while(length(job.queue))
		var/turf/current = job.queue[1]
		job.queue.Cut(1, 2)

		// Check if we found a pressure outlet (non-full tile that can receive fluid)
		if(get_fluid_level(current) < FLUID_FULL && can_receive_pressure_fluid(current))
			var/list/path = job.reconstruct_pressure_path(current)
			execute_pressure_transfer(source, current, path)
			continue

		// Only continue tracing through full tiles
		if(get_fluid_level(current) < FLUID_FULL)
			continue

		// Add valid neighbors to trace
		for(var/direction in list(NORTH, SOUTH, EAST, WEST))
			var/turf/neighbor = get_step(current, direction)
			if(!neighbor || job.visited[neighbor])
				continue

			// Check for directional barriers between current and neighbor (windows/doors)
			if(current.LinkBlocked(current, neighbor))
				continue

			if(neighbor.blocks_flow())
				continue

			if(current.blocks_flow())
				continue

			// Allow going down, or horizontal at same z-level, but never above start z
			if(neighbor.z > job.start_z)
				continue

			if(get_fluid_level(neighbor) < FLUID_FULL)
				// Special case: allow tracing to outlets (non-full tiles that can receive)
				// But we still need to verify the path to the outlet respects barriers
				if(can_receive_pressure_fluid(neighbor))
					job.parent[neighbor] = current
					job.visited[neighbor] = TRUE
					job.queue += neighbor
				continue

			job.parent[neighbor] = current
			job.visited[neighbor] = TRUE
			job.queue += neighbor

	return_pressure_job(job)

/datum/controller/subsystem/processing/liquid/proc/can_receive_pressure_fluid(turf/T)
	if(!T?.cell)
		return FALSE

	// Can receive if not at max capacity and not blocked
	return get_fluid_level(T) < FLUID_FULL && !T.blocks_flow()

/datum/controller/subsystem/processing/liquid/proc/execute_pressure_transfer(turf/source, turf/outlet, list/path)
	if(!source?.cell || !outlet?.cell)
		return

	// Calculate how much pressure transfer can occur
	var/source_excess = source.cell.fluidsum - 60 // Only transfer excess above "full"
	if(source_excess <= 0)
		return

	var/outlet_capacity = MAX_FLUID_VOLUME - outlet.cell.fluidsum
	if(outlet_capacity <= 0)
		return

	// Transfer amount based on path length (longer paths = less transfer)
	var/path_resistance = max(1, length(path) / 4)
	var/transfer_amount = min(source_excess, outlet_capacity, 20 / path_resistance)

	if(transfer_amount < 1)
		return

	// Find the dominant fluid type at source
	var/datum/liquid/dominant_fluid = source.get_highest_fluid_by_volume()
	if(!dominant_fluid)
		return

	// Execute the pressure teleportation with validation
	var/source_fluid_amount = source.cell.fluid_volume[dominant_fluid]
	if(source_fluid_amount >= transfer_amount)
		// Validate neither cell is currently being processed to prevent conflicts
		if((source in cells_in_processing) || (outlet in cells_in_processing))
			return // Skip pressure transfer if cells are being processed

		source.cell.fluid_volume[dominant_fluid] -= transfer_amount
		outlet.cell.fluid_volume[GetLiquidInstance(dominant_fluid, outlet, FALSE)] += transfer_amount

		update_fluidsum(source, FALSE)
		update_fluidsum(outlet, FALSE)

		source.cell.fluid_flags |= FLUID_MOVED
		outlet.cell.fluid_flags |= FLUID_MOVED
		cell_index[source] = TRUE
		cell_index[outlet] = TRUE

		// Trigger flow interactions at the pressure outlet
		// Pressure transfers should probably create stronger effects than normal flow, so we make the threshold for effects lower.
		if(transfer_amount >= 10)
			handle_flow_interaction(source, outlet, transfer_amount, TRUE, path)

/datum/controller/subsystem/processing/liquid/proc/get_pressure_job() as /pressure_job
	var/pressure_job/job
	if(pressure_job_pool_size > 0)
		job = pressure_job_pool[pressure_job_pool_size]
		pressure_job_pool.len--
		pressure_job_pool_size--
		pressure_job_pool_hits++

		// Validate job integrity before reuse
		if(!validate_pressure_job_integrity(job))
			job = new /pressure_job()
			pressure_job_pool_misses++
	else
		job = new /pressure_job()
		pressure_job_pool_misses++

	job.Reset()
	return job

/datum/controller/subsystem/processing/liquid/proc/return_pressure_job(pressure_job/job)
	if(job && pressure_job_pool_size < pressure_job_pool_max)
		// Validate job state before returning to pool
		if(validate_pressure_job_for_pooling(job))
			pressure_job_pool += job
			pressure_job_pool_size++
		else
			// Job is corrupted, don't pool it
			qdel(job)
	else if(job)
		// Pool is full, dispose of the job
		qdel(job)

//================================================================
// --- Pool Integration Functions ---
// These functions integrate the pool system with the
// main liquid subsystem processing cycle.
//================================================================

/**
 * Gets pool size for a turf.
 *
 * @param T The turf to get pool size for.
 * @return The size of the pool.
 */
/datum/controller/subsystem/processing/liquid/proc/get_safe_pool_size(turf/T)
	if(!T?.cell)
		return 0

	return GLOB.pool_manager.get_pool_size(T)

//================================================================
// --- Enhanced Pressure Job Pool Management ---
// These functions implement lifecycle tracking and validation
// for pressure job objects to prevent memory leaks and ensure
// proper resource management.
//================================================================

/**
 * Validates pressure job integrity before reuse from pool.
 * Ensures the job is in a valid state for reuse.
 *
 * @param job The pressure job to validate.
 * @return TRUE if job is valid for reuse, FALSE otherwise.
 */
/datum/controller/subsystem/processing/liquid/proc/validate_pressure_job_integrity(pressure_job/job)
	if(!job)
		return FALSE

	// Check that required data structures exist
	if(!istype(job.parent, /alist) || !istype(job.visited, /alist) || !islist(job.queue))
		return FALSE

	// Ensure data structures are properly initialized
	if(!job.parent || !job.visited || !job.queue)
		return FALSE

	// Check for reasonable state (should be reset but verify structure)
	if(length(job.parent) > 1000 || length(job.visited) > 1000 || length(job.queue) > 100)
		// Suspiciously large, might be corrupted
		return FALSE

	return TRUE

/**
 * Validates pressure job state before returning to pool.
 * Ensures the job is properly cleaned and safe for pooling.
 *
 * @param job The pressure job to validate for pooling.
 * @return TRUE if job is safe to pool, FALSE otherwise.
 */
/datum/controller/subsystem/processing/liquid/proc/validate_pressure_job_for_pooling(pressure_job/job)
	if(!job)
		return FALSE

	// Auto-recovery: Always attempt to reset before validation
	job.Reset()

	// Validate basic integrity after reset
	if(!validate_pressure_job_integrity(job))
		return FALSE

	// Verify reset was successful
	if(length(job.parent) > 0 || length(job.visited) > 0 || length(job.queue) > 0 || job.start_z != 0)
		// Force a more aggressive reset if normal reset failed
		try
			job.parent = new()
			job.visited = new()
			job.queue = new()
			job.start_z = 0
		catch
			return FALSE

		// Final validation after aggressive reset
		if(length(job.parent) > 0 || length(job.visited) > 0 || length(job.queue) > 0)
			return FALSE

	return TRUE

/**
 * Performs maintenance on the pressure job pool.
 * Removes corrupted jobs and validates pool integrity.
 */
/datum/controller/subsystem/processing/liquid/proc/cleanup_pressure_job_pool()
	if(!pressure_job_pool || pressure_job_pool_size == 0)
		return

	var/list/valid_jobs = list()

	// Validate all jobs in the pool
	for(var/i = 1; i <= pressure_job_pool_size; i++)
		var/pressure_job/job = pressure_job_pool[i]
		if(validate_pressure_job_integrity(job) && validate_pressure_job_for_pooling(job))
			valid_jobs += job
		else
			qdel(job)

	// Rebuild pool with valid jobs only
	pressure_job_pool = valid_jobs
	pressure_job_pool_size = length(valid_jobs)

	// Log cleanup results if monitoring is enabled

/**
 * Gets performance statistics for the pressure job pool.
 * Used for monitoring and debugging pool efficiency.
 *
 * @return An associative list of pool statistics.
 */
/datum/controller/subsystem/processing/liquid/proc/get_pressure_job_pool_stats()
	var/list/stats = list()

	stats["pool_size"] = pressure_job_pool_size
	stats["pool_max"] = pressure_job_pool_max
	stats["pool_hits"] = pressure_job_pool_hits
	stats["pool_misses"] = pressure_job_pool_misses

	var/total_requests = pressure_job_pool_hits + pressure_job_pool_misses
	if(total_requests > 0)
		stats["pool_efficiency"] = (pressure_job_pool_hits / total_requests) * 100
	else
		stats["pool_efficiency"] = 0

	return stats

//================================================================
// --- Utility Functions ---
// Basic utility functions for the liquid subsystem.
//================================================================

/**
 * Optimizes the cell index by removing invalid entries.
 * Helps maintain performance when the cell index grows large.
 */
/datum/controller/subsystem/processing/liquid/proc/optimize_cell_index()
	var/list/invalid_entries = list()

	for(var/turf/T as anything in cell_index)
		if(!T?.cell || !can_process_fluid(T))
			invalid_entries += T

	if(length(invalid_entries) > 0)
		cell_index -= invalid_entries

/**
 * Gets comprehensive performance statistics for monitoring.
 * Provides detailed information about system performance and resource usage.
 *
 * @return An associative list of performance statistics.
 */
/datum/controller/subsystem/processing/liquid/proc/get_comprehensive_performance_stats()
	var/list/stats = list()

	// Basic processing statistics
	stats["phase"] = phase
	stats["cell_index_size"] = length(cell_index)
	stats["process_queue_size"] = length(process_queue)
	stats["reset_queue_size"] = length(reset_queue)
	stats["cells_in_processing"] = length(cells_in_processing)
	// cells_pending_sync stat removed - no longer used with direct volume sync

	// Performance optimization statistics
	stats["max_cells_per_tick"] = max_cells_per_tick

	// Pool manager statistics
	if(GLOB.pool_manager)
		var/list/pool_stats = GLOB.pool_manager.get_performance_statistics()
		for(var/stat_name in pool_stats)
			stats["pool_[stat_name]"] = pool_stats[stat_name]

	// Pressure job pool statistics
	var/list/pressure_stats = get_pressure_job_pool_stats()
	for(var/stat_name in pressure_stats)
		stats["pressure_[stat_name]"] = pressure_stats[stat_name]

	return stats
