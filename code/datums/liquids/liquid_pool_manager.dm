/**
 * Liquid Pool Manager (Refactored)
 *
 * This system manages pools of connected liquid cells using a modular union-find
 * data structure. It handles the lifecycle of liquid pools as turfs gain or lose
 * fluid and connect to or disconnect from their neighbors.
 *
 * The DSU operates directly on turf references for simplicity's sake.
 */

GLOBAL_DATUM_INIT(pool_manager, /datum/pool_manager, new)

/datum/pool_manager
    var/name = "Pool Manager"

    /// union-find data structure, has its own modular implementation for reuse if we want
    var/disjoint_set/dsu

    /// A list of all turfs currently containing liquid so we can iterate over them instead of the whole world.
    var/list/liquid_turfs

    /// Timer for continuous liquid behavior processing
    var/continuous_behavior_timer = 0

    /// Timer for floor chemical reaction processing
    var/reaction_timer = 0

    // Performance monitoring
    var/list/pool_statistics_cache = list() // Cached statistics for performance
    var/cache_timer = 0
    var/cache_refresh_interval = 25 // Refresh cache every 25 ticks

/datum/pool_manager/New()
    ..()
    dsu = new()
    liquid_turfs = list()
    pool_statistics_cache = list()

/**
 * Turf update processing
 *
 * @param dirty_turfs A list of turfs whose fluid state has changed.
 */
/datum/pool_manager/proc/update_pools(list/dirty_turfs)
    var/list/safe_updates = list()

    for (var/turf/T as anything in dirty_turfs)
        if(!T?.cell)
            continue

        safe_updates += T

    for (var/turf/T as anything in safe_updates)
        update_turf_connectivity(T)


/**
 * Checks if two turfs are part of the same contiguous liquid pool.
 * @param T1 The first turf.
 * @param T2 The second turf.
 * @return TRUE if they are in the same pool, FALSE otherwise.
 */
/datum/pool_manager/proc/is_in_same_pool(turf/T1, turf/T2)
    if (!T1?.cell || !T2?.cell || T1.cell.fluidsum < MIN_FLUID_VOLUME || T2.cell.fluidsum < MIN_FLUID_VOLUME)
        return FALSE

    // Perform connectivity check
    return dsu.is_connected(T1, T2)

/**
 * Retrieves all turfs belonging to the same pool as the given turf.
 * @param T The turf to query.
 * @return A list of all turfs in the pool.
 */
/datum/pool_manager/proc/get_pool(turf/T)
    if (!T?.cell || T.cell.fluidsum < MIN_FLUID_VOLUME)
        return list(T) // Return a list containing only itself if invalid.

    var/root = dsu.find(T)
    if (!root)
        return list(T)

    var/list/pool_turfs = list()

    for (var/turf/member as anything in liquid_turfs)
        if (dsu.find(member) == root)
            pool_turfs += member

    return pool_turfs

/**
 * Gets the number of turfs in a specific pool.
 * @param T The turf whose pool size we want.
 * @return The size of the pool.
 */
/datum/pool_manager/proc/get_pool_size(turf/T)
    if (!T?.cell || T.cell.fluidsum < MIN_FLUID_VOLUME)
        return 1

    return dsu.get_set_size(T)

/**
 * Calculates the average fluid volume across all turfs in a pool.
 * @param pool A list of turfs representing a pool.
 * @return The average fluid volume.
 */
/datum/pool_manager/proc/get_pool_avg_fluid(list/pool)
    if (!length(pool))
        return 0

    var/total_fluid = 0
    for (var/turf/T as anything in pool)
        if (T?.cell)
            total_fluid += T.cell.fluidsum

    return total_fluid / length(pool)

/**
 * Wrapper for the DSU's add_element proc. Creates a new pool for a single turf.
 * Contains fallbacks for ensuring the turf is tracked before adding it.
 */
/datum/pool_manager/proc/attach_to_new_pool(turf/T)
    // Basic validation
    if (!T?.cell || T.cell.fluidsum < MIN_FLUID_VOLUME)
        return

    if (!(T in liquid_turfs))
        liquid_turfs += T
        dsu.add_element(T)

    // Also immediately try to connect to neighbors.
    for (var/d in GLOB.cardinals)
        var/turf/N = get_step(T, d)
        if (N?.cell && N.cell.fluidsum >= MIN_FLUID_VOLUME && !N.blocks_flow() && !T.LinkBlocked(T, N))
            dsu.union(T, N)

/**
 * Wrapper for the DSU's union proc. Attaches a turf to an existing pool, represented by another turf.
 * Contains fallbacks to ensure both turfs are tracked before merging the pools.
 */
/datum/pool_manager/proc/attach_to_pool(turf/T, turf/existing_pool_turf)
    // Basic validation
    if (!T?.cell || !existing_pool_turf?.cell || T.cell.fluidsum < MIN_FLUID_VOLUME)
        return

    // Ensure both turfs are tracked before trying to union them.
    if (!(T in liquid_turfs))
        liquid_turfs += T
        dsu.add_element(T)

    if (!(existing_pool_turf in liquid_turfs))
        liquid_turfs += existing_pool_turf
        dsu.add_element(existing_pool_turf)

    dsu.union(T, existing_pool_turf)

/**
 * Cleans up the list of tracked turfs by removing those that no longer have liquid.
 */
/datum/pool_manager/proc/cleanup_empty_pools()
    var/list/to_remove = list()

    for (var/turf/T as anything in liquid_turfs)
        if (!T?.cell || T.cell.fluidsum < MIN_FLUID_VOLUME)
            to_remove += T

    if (length(to_remove))
        liquid_turfs -= to_remove

/**
 * Gathers statistics about the current state of all liquid pools.
 * @return An associative list of statistics.
 */
/datum/pool_manager/proc/get_pool_statistics()
    // Return cached statistics if they're still fresh
    if(cache_timer < cache_refresh_interval && length(pool_statistics_cache) > 0)
        cache_timer++
        return pool_statistics_cache.Copy()

    // Cache expired or doesn't exist, recalculate
    var/list/roots = list()

    for (var/turf/T in liquid_turfs)
        var/root = dsu.find(T)
        roots[root] = TRUE // Use list as a set to find unique roots

    var/largest_pool = 0

    if (length(roots))
        for (var/turf/root in roots)
            var/size = dsu.get_set_size(root)
            if (size > largest_pool)
                largest_pool = size

    // Update cache
    pool_statistics_cache = list(
        "total_pools" = length(roots),
        "largest_pool" = largest_pool,
        "total_turfs_in_pools" = length(liquid_turfs),
        "average_pool_size" = length(roots) > 0 ? length(liquid_turfs) / length(roots) : 0
    )

    cache_timer = 0

    return pool_statistics_cache.Copy()

/**
 * Generates a comprehensive list of all distinct pools for debugging.
 * @return A list where each element is another list containing the turfs of a single pool.
 */
/datum/pool_manager/proc/get_all_pools_for_debug()
    var/list/pools = list()
    var/list/roots_found = list()

    for (var/turf/T in liquid_turfs)
        var/root = dsu.find(T)
        if (root in roots_found)
            continue
        roots_found[root] = TRUE
        pools += get_pool(T)

    return pools

/**
 * Processes continuous liquid behaviors for all mobs standing in liquid pools.
 * Should be called periodically from the liquid subsystem.
 */
/datum/pool_manager/proc/process_continuous_behaviors()
    continuous_behavior_timer++

    // Process continuous behaviors every 5 ticks (5 seconds)
    if(continuous_behavior_timer < 5)
        return

    continuous_behavior_timer = 0

    // Basic cache maintenance
    cache_timer++

    // Process all mobs standing in liquid pools
    for(var/turf/T as anything in liquid_turfs)
        if(!T?.cell || T.cell.fluidsum < MIN_FLUID_VOLUME)
            continue

        // Find all mobs on this liquid turf
        for(var/mob/living/M in T)
            if(!M || M.stat == DEAD)
                continue

            // Apply continuous behaviors for each liquid type
            for(var/datum/liquid/fluid as anything in T.cell.fluid_volume)
                if(T.cell.fluid_volume[fluid] < MIN_FLUID_VOLUME)
                    continue

                // Execute continuous flag-based behaviors with sophisticated exposure
                if(fluid.fluid_flags & FLUID_PERMEATING)
                    // Use the sophisticated exposure system that checks is_drowning
                    GLOB.liquid_registry.apply_liquid_chemical_effects(M, T, fluid)

                if(fluid.fluid_flags & FLUID_CORROSIVE)
                    GLOB.liquid_registry.execute_flag_behavior(FLUID_CORROSIVE, "corrode_mob", M, T, fluid)

                // Execute continuous liquid-specific behaviors
                GLOB.liquid_registry.execute_liquid_behavior(fluid.type, "continuous_effect", M, T)

/**
 * Processes chemical reactions on liquid turfs when dynamic liquids are enabled.
 * Should be called periodically from the liquid subsystem.
 */
/datum/pool_manager/proc/process_floor_reactions()
    if(!GLOB.liquid_registry.allow_dynamic_liquids)
        return

    reaction_timer++

    // Process floor reactions every 10 ticks (10 seconds) - slower than behaviors
    if(reaction_timer < 10)
        return

    reaction_timer = 0

    // Process reactions on liquid turfs that have multiple reagent types
    for(var/turf/T as anything in liquid_turfs)
        if(!T?.cell || T.cell.fluidsum < MIN_FLUID_VOLUME)
            continue

        // Only process if there are multiple liquids with reagents that could react
        var/reagent_count = 0
        for(var/datum/liquid/fluid as anything in T.cell.fluid_volume)
            if(fluid.reagent && T.cell.fluid_volume[fluid] >= MIN_FLUID_VOLUME)
                reagent_count++
                if(reagent_count >= 2)
                    break

        if(reagent_count >= 2)
            GLOB.liquid_registry.process_floor_reactions(T)

//================================================================
// --- Core Pool Functions ---
// Basic pool connectivity and management functions.
//================================================================

/**
 * Updates connectivity for a turf.
 *
 * @param T The turf to update connectivity for.
 */
/datum/pool_manager/proc/update_turf_connectivity(turf/T)
    if (!T?.cell)
        return

    var/has_liquid = T.cell.fluidsum >= MIN_FLUID_VOLUME
    var/is_tracked = (T in liquid_turfs)

    // Turf lost all its liquid
    if (!has_liquid && is_tracked)
        liquid_turfs -= T
        // Note: The turf reference might remain in the DSU's parent list, but it's inert
        // and will be overwritten if the turf gets liquid again. This is fine.

    // Turf gained liquid
    if (has_liquid && !is_tracked)
        liquid_turfs += T
        dsu.add_element(T) // Add it as a new, single-element pool.

    // Turf has liquid, connect it to valid neighbors.
    if (has_liquid)
        for (var/d in GLOB.cardinals)
            var/turf/N = get_step(T, d)
            if (N?.cell && N.cell.fluidsum >= MIN_FLUID_VOLUME && !N.blocks_flow() && !T.LinkBlocked(T, N))
                dsu.union(T, N)


/**
 * Gets performance statistics for pool operations.
 * Provides insight into pool system efficiency and bottlenecks.
 *
 * @return An associative list of performance statistics.
 */
/datum/pool_manager/proc/get_performance_statistics()
    var/list/stats = list()

    stats["total_liquid_turfs"] = length(liquid_turfs)
    stats["cache_refresh_interval"] = cache_refresh_interval
    stats["cache_age"] = cache_timer

    // Include cached pool statistics if available
    if(length(pool_statistics_cache) > 0)
        for(var/stat_name in pool_statistics_cache)
            stats["cached_[stat_name]"] = pool_statistics_cache[stat_name]

    return stats