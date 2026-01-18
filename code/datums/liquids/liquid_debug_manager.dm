/**
 * Liquid Debug Manager
 *
 * This system provides comprehensive debugging and monitoring tools for the liquid
 * simulation subsystem. It allows admins to inspect liquid cell states, pool
 * information, and track fluid behaviors for debugging and troubleshooting.
 *
 */

// Main debug manager, uses nanoUI because it's easier to work with than TGUI
GLOBAL_DATUM_INIT(liquid_debug_manager, /datum/liquid_debug_manager, new)

/datum/liquid_debug_manager
    var/name = "Liquid Debug Manager"
    var/list/performance_metrics = list()
    var/monitoring_enabled = FALSE
    // Enhanced navigation and view state
    var/view_mode = "dashboard" // "dashboard", "pools", "performance", "cells", "reports", "system", "tests"
    var/view_submode = "" // For sub-sections within main views
    var/list/navigation_stack = list() // Navigation breadcrumb trail
    var/selected_pool_root = null // Stores a turf reference for selected pool
    var/selected_cell_data = null
    var/system_report = null

    // Unit testing integration
    var/test_results = null // Stores test results for display
    var/tests_running = FALSE // Flag to indicate tests are running

    // Enhanced filtering and search
    var/pool_filter_mode = "all" // "all", "large", "small", "critical", "by_fluid"
    var/pool_sort_mode = "size_desc" // "size_desc", "size_asc", "fluid_desc", "location"
    var/search_query = ""
    var/max_displayed_pools = 20 // Pagination limit
    var/pool_display_offset = 0

    // System health and alerts
    var/list/system_alerts = list()
    var/system_health_status = "unknown" // "healthy", "warning", "critical", "unknown"
    var/last_health_check = 0

    // Memory management and performance optimization
    var/debug_data_timer = 0
    var/debug_data_cleanup_interval = 300 // Clean up every 5 minutes
    var/max_cell_debug_entries = 1000 // Limit debug data accumulation
    var/list/cell_debug_data = list() // Tracked cell debug information
    var/debug_memory_limit = 1048576 // Maximum memory usage in bytes, totalling 1mb. Extremely small and yet I don't expect more than 5-6kb to actually be used, so this is plenty of room.
    var/current_debug_memory = 0 // Current estimated memory usage

    // Performance monitoring
    var/performance_sample_interval = 50 // Sample performance every 50 cycles
    var/performance_sample_timer = 0
    var/list/performance_history = list() // Rolling performance history
    var/max_performance_samples = 100 // Keep last 100 performance samples

/datum/liquid_debug_manager/New()
    ..()
    performance_metrics = list(
        "cells_processed" = 0,
        "pools_updated" = 0,
        "dsu_unions" = 0,
        "dsu_finds" = 0,
        "conversions_performed" = 0,
        "average_processing_time" = 0,
        "pressure_pool_size" = 0,
        "pressure_pool_hits" = 0,
        "pressure_pool_misses" = 0,
        "pressure_pool_efficiency" = 100, // Start at 100% (perfect efficiency when no requests)
        "debug_memory_usage" = 0,
        "performance_alerts" = 0
    )

    cell_debug_data = list()
    performance_history = list()

    // Initialize navigation and health monitoring
    navigation_stack = list()
    system_alerts = list()

    // Start periodic cleanup timer
    spawn(debug_data_cleanup_interval * 10) // Convert to deciseconds
        periodic_debug_cleanup()

    // Start health monitoring
    spawn(100) // Start after 10 seconds
        periodic_health_check()

/datum/liquid_debug_manager/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1, var/datum/nanoui/master_ui = null, datum/topic_state/state = GLOB.default_state)
    if(!user || !user.client)
        return

    var/list/data = get_ui_data()

    ui = SSnanoui.try_update_ui(user, src, ui_key, ui, data, force_open)
    if(!ui)
        var/datum/asset/nanoui/templates = get_asset_datum(/datum/asset/nanoui)
        templates.send(user.client, list("layout_default.tmpl", "liquid_debug.tmpl")) // I hate having to do this for every UI with a template but it won't work otherwise
        ui = new(user, src, ui_key, "liquid_debug.tmpl", "Liquid Debug Manager", 900, 700, state = state)
        ui.set_initial_data(data)
        ui.open()
        ui.set_auto_update(1)

/datum/liquid_debug_manager/proc/get_ui_data()
    var/list/data = list()

    // Core system state
    data["monitoring_enabled"] = monitoring_enabled
    data["view_mode"] = view_mode
    data["view_submode"] = view_submode
    data["navigation_stack"] = navigation_stack.Copy()
    data["system_report"] = system_report

    // System health and alerts
    update_system_health()
    data["system_health"] = system_health_status
    data["system_alerts"] = system_alerts.Copy()
    data["alert_count"] = length(system_alerts)

    // Enhanced metrics with categorization
    data["metrics"] = get_categorized_metrics()

    // Dashboard overview data
    if(view_mode == "dashboard")
        data += get_dashboard_data()

    // Pool data with filtering and sorting
    if(view_mode == "pools")
        data += get_filtered_pools_data()

    // Performance monitoring data
    if(view_mode == "performance")
        data += get_performance_data()

    // Cell inspection data
    if(view_mode == "cells")
        data["selected_cell"] = selected_cell_data
        data += get_cell_inspection_data()

    // System reports data
    if(view_mode == "reports")
        data += get_reports_data()

    // System management data
    if(view_mode == "system")
        data += get_system_management_data()

    // Unit tests data
    if(view_mode == "tests")
        data += get_tests_data()

    // Search and filtering state
    data["pool_filter_mode"] = pool_filter_mode
    data["pool_sort_mode"] = pool_sort_mode
    data["search_query"] = search_query
    data["max_displayed_pools"] = max_displayed_pools
    data["pool_display_offset"] = pool_display_offset

    return data

/datum/liquid_debug_manager/Topic(href, href_list, datum/topic_state/state)
    // Core system controls
    if(href_list["toggle_monitoring"])
        monitoring_enabled = !monitoring_enabled
        return TOPIC_REFRESH

    // Enhanced navigation system
    if(href_list["navigate_to"])
        navigate_to_view(href_list["navigate_to"], href_list["submode"])
        return TOPIC_REFRESH

    if(href_list["navigate_back"])
        navigate_back()
        return TOPIC_REFRESH

    if(href_list["navigate_home"])
        navigate_to_view("dashboard")
        return TOPIC_REFRESH

    // Pool management
    if(href_list["view_pools"])
        navigate_to_view("pools")
        return TOPIC_REFRESH

    if(href_list["filter_pools"])
        pool_filter_mode = href_list["filter_pools"]
        pool_display_offset = 0 // Reset pagination
        return TOPIC_REFRESH

    if(href_list["sort_pools"])
        pool_sort_mode = href_list["sort_pools"]
        return TOPIC_REFRESH

    if(href_list["search_pools"])
        search_query = href_list["search_pools"]
        pool_display_offset = 0 // Reset pagination
        return TOPIC_REFRESH

    if(href_list["pool_page"])
        var/new_offset = text2num(href_list["pool_page"])
        if(new_offset >= 0)
            pool_display_offset = new_offset
        return TOPIC_REFRESH

    if(href_list["inspect_pool"])
        var/pool_ref = href_list["inspect_pool"]
        var/turf/T = locate(pool_ref)
        if(T?.cell)
            selected_pool_root = pool_ref
            selected_cell_data = get_cell_data(T)
            navigate_to_view("cells", "pool_inspection")
        return TOPIC_REFRESH

    // Performance monitoring
    if(href_list["view_performance"])
        navigate_to_view("performance")
        return TOPIC_REFRESH

    if(href_list["performance_section"])
        view_submode = href_list["performance_section"]
        return TOPIC_REFRESH

    // System reports
    if(href_list["view_reports"])
        navigate_to_view("reports")
        return TOPIC_REFRESH

    if(href_list["generate_report"])
        var/report_type = href_list["report_type"] || "system"
        system_report = generate_enhanced_report(report_type)
        navigate_to_view("reports", "view_report")
        return TOPIC_REFRESH

    if(href_list["close_report"])
        system_report = null
        view_submode = ""
        return TOPIC_REFRESH

    // System management
    if(href_list["view_system"])
        navigate_to_view("system")
        return TOPIC_REFRESH

    if(href_list["validate_system"])
        system_report = validate_system_integrity()
        navigate_to_view("reports", "validation")
        return TOPIC_REFRESH

    if(href_list["clear_cache"])
        clear_debug_cache()
        return TOPIC_REFRESH

    if(href_list["clear_alerts"])
        clear_system_alerts()
        return TOPIC_REFRESH

    // Unit testing controls
    if(href_list["view_tests"])
        navigate_to_view("tests")
        return TOPIC_REFRESH

    if(href_list["run_all_tests"])
        spawn()
            tests_running = TRUE
            test_results = GLOB.liquid_test_suite.run_all_tests()
            tests_running = FALSE
        return TOPIC_REFRESH

    if(href_list["clear_test_results"])
        test_results = null
        return TOPIC_REFRESH

    if(href_list["refresh"])
        return TOPIC_REFRESH

    return ..()

/datum/liquid_debug_manager/CanUseTopic(mob/user, datum/topic_state/state)
    if(!user?.client?.holder)
        return STATUS_CLOSE
    if(!(user.client.holder.rights & R_DEBUG))
        return STATUS_CLOSE
    return STATUS_INTERACTIVE

/datum/liquid_debug_manager/proc/get_cell_data(turf/T)
    if(!T?.cell)
        return null

    var/pool_root = GLOB.pool_manager.dsu.find(T)
    var/pool_size = GLOB.pool_manager.get_pool_size(T)

    var/list/cell_data = list(
        "x" = T.x,
        "y" = T.y,
        "z" = T.z,
        "fluidsum" = T.cell.fluidsum,
        "pool_root" = "[pool_root]",
        "pool_size" = pool_size,
        "fluid_flags" = T.cell.fluid_flags
    )

    // Get fluid breakdown
    var/list/fluids_data = list()
    var/list/fluids = GET_ALL_FLUIDS(T)
    if(length(fluids))
        for(var/datum/liquid/fluid in fluids)
            fluids_data += list(list(
                "name" = fluid.name,
                "amount" = fluids[fluid]
            ))

    cell_data["fluids"] = fluids_data
    return cell_data

/datum/liquid_debug_manager/proc/toggle_monitoring()
    monitoring_enabled = !monitoring_enabled
    return monitoring_enabled

/datum/liquid_debug_manager/proc/record_performance_metric(metric_name, value)
    if(!monitoring_enabled)
        return

    if(metric_name in performance_metrics)
        performance_metrics[metric_name] = value

    // Update memory usage tracking
    performance_metrics["debug_memory_usage"] = current_debug_memory

    // Sample performance history periodically
    performance_sample_timer++
    if(performance_sample_timer >= performance_sample_interval)
        sample_performance_history()
        performance_sample_timer = 0

/datum/liquid_debug_manager/proc/get_performance_report()
    var/list/report = list()
    for(var/metric in performance_metrics)
        report[metric] = performance_metrics[metric]
    return report

// clear_debug_cache function moved to enhanced version at end of file

/datum/liquid_debug_manager/proc/inspect_cell(turf/T)
    if(!T?.cell)
        return "Invalid turf or cell"

    var/list/info = list()
    info += "Coordinates: ([T.x], [T.y], [T.z])"
    info += "Total Fluid: [T.cell.fluidsum]"
    var/root = GLOB.pool_manager.dsu.find(T)
    info += "Pool Root: [root]"
    info += "Pool Size: [GLOB.pool_manager.get_pool_size(T)]"
    info += "Fluid Flags: [T.cell.fluid_flags]"

    var/list/fluids = GET_ALL_FLUIDS(T)
    if(length(fluids))
        info += "Fluid Breakdown:"
        for(var/datum/liquid/fluid in fluids)
            info += "  - [fluid.name]: [fluids[fluid]] units"
    else
        info += "No fluids present"

    return jointext(info, "\n")

/datum/liquid_debug_manager/proc/validate_system_integrity()
    var/list/errors = list()

    // Validate core managers exist
    if(!GLOB.pool_manager)
        errors += "ERROR: Pool manager not found"
    if(!GLOB.liquid_manager)
        errors += "ERROR: Liquid manager not found"
    if(!GLOB.liquid_registry)
        errors += "ERROR: Liquid registry not found"

    // Validate subsystem state
    if(!SSliquid)
        errors += "ERROR: Liquid subsystem not found"
    else
        // Validate state tracking from Phase 1 implementation
        if(SSliquid.cells_in_processing && length(SSliquid.cells_in_processing) > 0)
            for(var/turf/T in SSliquid.cells_in_processing)
                if(!T?.cell)
                    errors += "Invalid turf in cells_in_processing: [T]"

        // cells_pending_sync validation removed - no longer used with direct volume sync

    // Validate pool manager state
    if(GLOB.pool_manager)
        // Check DSU integrity
        if(!GLOB.pool_manager.dsu)
            errors += "Pool manager DSU not initialized"

        // Validate tracked turfs
        var/invalid_turfs = 0
        for(var/turf/T in GLOB.pool_manager.liquid_turfs)
            if(!istype(T) || !T.cell || T.cell.fluidsum < MIN_FLUID_VOLUME)
                invalid_turfs++
                log_debug("Liquid Debug: Invalid turf in liquid_turfs: [T]")

        if(invalid_turfs > 0)
            errors += "Found [invalid_turfs] invalid entries in tracked liquid turfs"

    // Validate liquid registry integrity
    if(GLOB.liquid_registry)
        var/registry_result = GLOB.liquid_registry.validate_registry_integrity()
        if(registry_result != "Registry integrity validated successfully")
            errors += "Registry validation failed: [registry_result]"

    // Return results
    if(length(errors) > 0)
        return "VALIDATION FAILED:\n" + jointext(errors, "\n")
    else
        return "System integrity validated successfully. All subsystems are stable."

/datum/liquid_debug_manager/proc/validate_ui_data_consistency()
    var/list/errors = list()

    // Validate monitoring state
    if(!isnum(monitoring_enabled))
        errors += "Invalid monitoring_enabled state - not boolean"

    // Validate view mode
    if(!istext(view_mode))
        errors += "Invalid view_mode - not text"
    else if(!(view_mode in list("dashboard", "pools", "performance", "cells", "reports", "system")))
        errors += "Invalid view_mode value: [view_mode]"

    // Validate performance metrics
    if(!islist(performance_metrics))
        errors += "Performance metrics is not a list"
    else
        var/list/required_metrics = list("cells_processed", "pools_updated", "dsu_unions", "dsu_finds", "conversions_performed", "average_processing_time")
        for(var/metric in required_metrics)
            if(!(metric in performance_metrics))
                errors += "Missing required performance metric: [metric]"
            else if(!isnum(performance_metrics[metric]))
                errors += "Invalid performance metric value for [metric]: [performance_metrics[metric]]"

    // Validate selected pool state
    if(selected_pool_root && !istext(selected_pool_root))
        errors += "Invalid selected_pool_root - not a valid reference"

    // Validate selected cell data consistency
    if(selected_cell_data)
        if(!islist(selected_cell_data))
            errors += "Selected cell data is not a list"
        else
            var/list/required_fields = list("x", "y", "z", "fluidsum", "pool_root", "pool_size", "fluid_flags", "fluids")
            for(var/field in required_fields)
                if(!(field in selected_cell_data))
                    errors += "Missing required cell data field: [field]"

    // Validate system report state
    if(system_report && !istext(system_report))
        errors += "System report is not text"

    // Return validation result
    if(length(errors) > 0)
        return "UI DATA VALIDATION FAILED:\n" + jointext(errors, "\n")
    else
        return "UI data consistency validated successfully"


/datum/liquid_debug_manager/proc/generate_system_report()
    var/list/report = list()

    report += "=== Liquid Simulation Debug Report ==="
    report += "Generated: [time2text(world.time)]"
    report += "Architecture: Modern Disjoint Set Union (DSU)"
    report += ""

    if(GLOB.pool_manager)
        report += "=== Pool Statistics ==="
        var/list/pool_stats = GLOB.pool_manager.get_pool_statistics()
        for(var/stat in pool_stats)
            report += "[stat]: [pool_stats[stat]]"
    else
        report += "!!! POOL MANAGER NOT FOUND !!!" // How in the fuck did this happen?
    report += ""

    report += "=== Cell Index State ==="
    report += "Active cells in cell_index: [length(SSliquid.cell_index)]"
    report += "Sleeping cells: [length(SSliquid.sleeping_cells)]"
    report += ""

    report += "=== Performance Metrics ==="
    var/list/perf = get_performance_report()
    for(var/metric in perf)
        report += "[metric]: [perf[metric]]"
    report += ""

    report += "=== System Integrity ==="
    report += validate_system_integrity()

    return jointext(report, "\n")

//================================================================
// --- Memory Management and Performance Optimization ---
// These functions implement automatic cleanup and memory limits
// for debug data to prevent indefinite accumulation.
//================================================================

/**
 * Periodic cleanup of debug data to prevent memory accumulation.
 * Runs automatically in a background loop when monitoring is enabled.
 */
/datum/liquid_debug_manager/proc/periodic_debug_cleanup()
    while(TRUE)
        sleep(debug_data_cleanup_interval * 10) // Convert to deciseconds

        if(!monitoring_enabled)
            continue

        cleanup_debug_data()
        cleanup_performance_history()

        // Update memory usage estimate
        update_debug_memory_usage()

/**
 * Cleans up accumulated cell debug data to prevent memory leaks.
 * Removes old entries when the limit is exceeded.
 */
/datum/liquid_debug_manager/proc/cleanup_debug_data()
    if(!cell_debug_data || length(cell_debug_data) <= max_cell_debug_entries)
        return

    var/entries_to_remove = length(cell_debug_data) - max_cell_debug_entries
    var/entries_removed = 0

    while(entries_removed < entries_to_remove && length(cell_debug_data) > 0)
        cell_debug_data.Cut(1, 2)
        entries_removed++

    if(entries_removed > 0)
        world.log << "DEBUG CLEANUP: Removed [entries_removed] old cell debug entries"

/**
 * Cleans up performance history to maintain rolling window.
 * Keeps only the most recent performance samples.
 */
/datum/liquid_debug_manager/proc/cleanup_performance_history()
    if(!performance_history || length(performance_history) <= max_performance_samples)
        return

    var/excess_samples = length(performance_history) - max_performance_samples

    // Remove oldest samples
    performance_history.Cut(1, excess_samples + 1)

/**
 * Samples current performance metrics for historical tracking.
 * Creates a snapshot of current performance state.
 */
/datum/liquid_debug_manager/proc/sample_performance_history()
    if(!monitoring_enabled)
        return

    var/list/sample = list()
    sample["timestamp"] = world.time
    sample["cells_processed"] = performance_metrics["cells_processed"]
    sample["average_processing_time"] = performance_metrics["average_processing_time"]
    sample["pressure_pool_efficiency"] = performance_metrics["pressure_pool_efficiency"]
    sample["debug_memory_usage"] = current_debug_memory

    performance_history += list(sample)

    // Ensure we don't exceed the maximum sample count
    if(length(performance_history) > max_performance_samples)
        performance_history.Cut(1, 2)

/**
 * Updates the estimated debug memory usage.
 * Provides rough tracking of memory consumption by debug systems.
 */
/datum/liquid_debug_manager/proc/update_debug_memory_usage()
    current_debug_memory = 0

    // Estimate memory usage from debug data structures
    current_debug_memory += length(cell_debug_data) * 100 // Rough estimate per cell entry
    current_debug_memory += length(performance_history) * 50 // Rough estimate per performance sample
    current_debug_memory += length(performance_metrics) * 20 // Rough estimate per metric

    // Check if we're approaching memory limits
    if(current_debug_memory > debug_memory_limit * 0.8) // 80% of limit
        world.log << "DEBUG WARNING: Debug memory usage at [current_debug_memory]/[debug_memory_limit] bytes"

        // Force cleanup if we exceed the limit
        if(current_debug_memory > debug_memory_limit)
            force_debug_cleanup()

/**
 * Forces immediate cleanup of debug data when memory limits are exceeded.
 * More aggressive cleanup than the periodic version.
 */
/datum/liquid_debug_manager/proc/force_debug_cleanup()
    // Reduce limits temporarily for aggressive cleanup
    var/original_cell_limit = max_cell_debug_entries
    var/original_performance_limit = max_performance_samples

    max_cell_debug_entries = original_cell_limit / 2
    max_performance_samples = original_performance_limit / 2

    cleanup_debug_data()
    cleanup_performance_history()

    // Restore original limits
    max_cell_debug_entries = original_cell_limit
    max_performance_samples = original_performance_limit

    world.log << "DEBUG EMERGENCY: Forced aggressive cleanup due to memory limit"

/**
 * Adds cell debug data with memory-aware limits.
 * Prevents indefinite accumulation of debug information.
 *
 * @param T The turf to add debug data for.
 */
/datum/liquid_debug_manager/proc/add_cell_debug(turf/T)
    if(!monitoring_enabled || !T?.cell)
        return

    // Check memory limits before adding
    if(current_debug_memory > debug_memory_limit)
        return // Skip adding if we're at limit

    var/cell_key = "[T.x],[T.y],[T.z]"
    var/list/debug_info = list(
        "timestamp" = world.time,
        "fluidsum" = T.cell.fluidsum,
        "fluid_flags" = T.cell.fluid_flags,
        "processing_phase" = SSliquid.phase
    )

    cell_debug_data[cell_key] = debug_info

    // Update memory usage estimate
    current_debug_memory += 100 // Rough estimate per entry

/**
 * Gets memory management statistics for monitoring.
 * Returns current memory usage and limits.
 *
 * @return An associative list of memory statistics.
 */
/datum/liquid_debug_manager/proc/get_memory_stats()
    var/list/stats = list()

    stats["current_memory"] = current_debug_memory
    stats["memory_limit"] = debug_memory_limit
    stats["memory_usage_percent"] = current_debug_memory / debug_memory_limit * 100
    stats["cell_debug_entries"] = length(cell_debug_data)
    stats["max_cell_entries"] = max_cell_debug_entries
    stats["performance_samples"] = length(performance_history)
    stats["max_performance_samples"] = max_performance_samples

    return stats

/**
 * Clears all debug cache and resets memory tracking.
 * Enhanced version of the original clear_debug_cache function.
 */
/datum/liquid_debug_manager/proc/clear_debug_cache()
    // Reset view state
    view_mode = "dashboard"
    selected_pool_root = null
    selected_cell_data = null
    system_report = null

    // Clear debug data structures
    cell_debug_data.len = 0
    performance_history.len = 0

    // Reset memory tracking
    current_debug_memory = 0
    debug_data_timer = 0
    performance_sample_timer = 0

    world.log << "DEBUG: Cleared all debug cache and reset memory tracking"

//================================================================
// --- Enhanced UI Data Retrieval Functions ---
// These functions provide organized data for the new interface
//================================================================

/**
 * Enhanced navigation system for better user experience.
 * Tracks navigation history and provides breadcrumb trails.
 */
/datum/liquid_debug_manager/proc/navigate_to_view(new_view, new_submode = "")
    // Add current view to navigation stack for back button
    if(view_mode != "dashboard" && view_mode != new_view)
        var/list/nav_entry = list("view" = view_mode, "submode" = view_submode)
        navigation_stack += list(nav_entry)

        // Limit navigation stack depth
        if(length(navigation_stack) > 5)
            navigation_stack.Cut(1, 2)

    view_mode = new_view
    view_submode = new_submode

    // Clear context-sensitive data when changing views
    if(new_view != "cells")
        selected_cell_data = null
    if(new_view != "reports")
        system_report = null

/datum/liquid_debug_manager/proc/navigate_back()
    if(length(navigation_stack) > 0)
        var/list/prev_view = navigation_stack[length(navigation_stack)]
        navigation_stack.Cut(length(navigation_stack))

        view_mode = prev_view["view"]
        view_submode = prev_view["submode"]
    else
        view_mode = "dashboard"
        view_submode = ""

/**
 * Gets categorized performance metrics for better organization.
 * Groups related metrics together for cleaner presentation.
 */
/datum/liquid_debug_manager/proc/get_categorized_metrics()
    var/list/categorized = list()

    // Core processing metrics
    categorized["processing"] = list(
        "cells_processed" = performance_metrics["cells_processed"],
        "pools_updated" = performance_metrics["pools_updated"],
        "average_processing_time" = performance_metrics["average_processing_time"],
        "conversions_performed" = performance_metrics["conversions_performed"]
    )

    // DSU performance metrics
    categorized["dsu"] = list(
        "dsu_unions" = performance_metrics["dsu_unions"],
        "dsu_finds" = performance_metrics["dsu_finds"]
    )

    // Cache performance metrics
    categorized["cache"] = list(
        "pressure_pool_size" = performance_metrics["pressure_pool_size"],
        "pressure_pool_hits" = performance_metrics["pressure_pool_hits"],
        "pressure_pool_misses" = performance_metrics["pressure_pool_misses"],
        "pressure_pool_efficiency" = performance_metrics["pressure_pool_efficiency"]
    )

    // System health metrics
    categorized["system"] = list(
        "debug_memory_usage" = performance_metrics["debug_memory_usage"],
        "performance_alerts" = performance_metrics["performance_alerts"]
    )

    return categorized

/**
 * Gets dashboard overview data with key indicators.
 * Provides high-level system status and quick access.
 */
/datum/liquid_debug_manager/proc/get_dashboard_data()
    var/list/dashboard = list()

    // Quick stats
    var/pool_count = 0
    var/cell_count = 0
    var/critical_pools = 0

    if(GLOB.pool_manager)
        var/list/pool_stats = GLOB.pool_manager.get_pool_statistics()
        pool_count = pool_stats["total_pools"]
        cell_count = pool_stats["total_turfs_in_pools"]
        critical_pools = count_critical_pools()

    dashboard["quick_stats"] = list(
        "total_pools" = pool_count,
        "total_cells" = cell_count,
        "critical_pools" = critical_pools,
        "monitoring_status" = monitoring_enabled ? "Active" : "Inactive"
    )

    // System status indicators
    dashboard["status_indicators"] = list(
        "subsystem_status" = SSliquid ? "Running" : "Stopped",
        "pool_manager_status" = GLOB.pool_manager ? "Active" : "Missing",
        "liquid_registry_status" = GLOB.liquid_registry ? "Active" : "Missing",
        "cells_in_processing" = SSliquid ? length(SSliquid.cells_in_processing) : 0
    )

    // Recent performance snapshot
    dashboard["performance_snapshot"] = list(
        "avg_processing_time" = performance_metrics["average_processing_time"],
        "cache_efficiency" = performance_metrics["pressure_pool_efficiency"],
        "memory_usage" = performance_metrics["debug_memory_usage"],
        "recent_alerts" = length(system_alerts)
    )

    return dashboard

/**
 * Gets filtered and sorted pool data with pagination.
 * Supports multiple filtering modes and sorting options.
 */
/datum/liquid_debug_manager/proc/get_filtered_pools_data()
    var/list/pools_data = list()

    if(!GLOB.pool_manager)
        return list("pools" = list(), "total_pools" = 0, "displayed_pools" = 0)

    var/list/all_pools = GLOB.pool_manager.get_all_pools_for_debug()
    var/list/filtered_pools = list()

    // Apply filtering
    for(var/list/turf_list in all_pools)
        var/pool_cell_count = length(turf_list)
        if(pool_cell_count == 0) continue

        var/turf/root_turf = GLOB.pool_manager.dsu.find(turf_list[1])
        var/avg_fluid = GLOB.pool_manager.get_pool_avg_fluid(turf_list)

        // Apply filters
        if(!passes_pool_filter(pool_cell_count, avg_fluid, root_turf))
            continue

        // Apply search query
        if(search_query != "")
            var/search_text = "[root_turf.x],[root_turf.y],[root_turf.z] [pool_cell_count] [avg_fluid]"
            if(!findtext(lowertext(search_text), lowertext(search_query)))
                continue

        var/list/pool_info = list(
            "id" = ref(root_turf),
            "root_coords" = "[root_turf.x],[root_turf.y],[root_turf.z]",
            "cell_count" = pool_cell_count,
            "avg_fluid" = avg_fluid,
            "status" = get_pool_status(pool_cell_count, avg_fluid),
            "z_level" = root_turf.z
        )

        filtered_pools += list(pool_info)

    // Apply sorting
    filtered_pools = sort_pools_data(filtered_pools)

    // Apply pagination
    var/total_filtered = length(filtered_pools)
    var/start_index = pool_display_offset + 1
    var/end_index = min(pool_display_offset + max_displayed_pools, total_filtered)

    if(start_index <= total_filtered)
        pools_data = filtered_pools.Copy(start_index, end_index + 1)

    return list(
        "pools" = pools_data,
        "total_pools" = total_filtered,
        "displayed_pools" = length(pools_data),
        "page_start" = start_index,
        "page_end" = end_index,
        "has_prev_page" = pool_display_offset > 0,
        "has_next_page" = end_index < total_filtered,
        "prev_page_offset" = max(0, pool_display_offset - max_displayed_pools),
        "next_page_offset" = pool_display_offset + max_displayed_pools
    )

/**
 * Determines if a pool passes the current filter criteria.
 */
/datum/liquid_debug_manager/proc/passes_pool_filter(cell_count, avg_fluid, turf/root_turf)
    switch(pool_filter_mode)
        if("all")
            return TRUE
        if("large")
            return cell_count >= 10
        if("small")
            return cell_count < 10
        if("critical")
            return avg_fluid > 50 || cell_count > 20
        if("by_fluid")
            return avg_fluid > 10
        else
            return TRUE

/**
 * Gets pool status indicator for display.
 */
/datum/liquid_debug_manager/proc/get_pool_status(cell_count, avg_fluid)
    if(avg_fluid > 50)
        return "high_fluid"
    else if(cell_count > 20)
        return "large_pool"
    else if(avg_fluid > 20)
        return "normal"
    else if(avg_fluid > 5)
        return "low_fluid"
    else
        return "minimal"

/**
 * Sorts pool data according to current sort mode.
 */
/datum/liquid_debug_manager/proc/sort_pools_data(list/pools)
    switch(pool_sort_mode)
        if("size_desc")
            return sort_list_by_key(pools, "cell_count", -1)
        if("size_asc")
            return sort_list_by_key(pools, "cell_count", 1)
        if("fluid_desc")
            return sort_list_by_key(pools, "avg_fluid", -1)
        if("location")
            return sort_list_by_key(pools, "root_coords", 1)
        else
            return pools

/**
 * Utility function to sort list of associative lists by a key.
 */
/datum/liquid_debug_manager/proc/sort_list_by_key(list/input_list, key, direction = 1)
    // Simple bubble sort implementation
    var/list/sorted_list = input_list.Copy()
    var/n = length(sorted_list)

    for(var/i = 1; i <= n - 1; i++)
        for(var/j = 1; j <= n - i; j++)
            var/list/current = sorted_list[j]
            var/list/next = sorted_list[j + 1]

            var/should_swap = FALSE
            if(direction > 0) // Ascending
                should_swap = current[key] > next[key]
            else // Descending
                should_swap = current[key] < next[key]

            if(should_swap)
                sorted_list[j] = next
                sorted_list[j + 1] = current

    return sorted_list

/**
 * Gets performance monitoring data with historical trends.
 */
/datum/liquid_debug_manager/proc/get_performance_data()
    var/list/perf_data = list()

    // Current performance metrics
    perf_data["current_metrics"] = get_categorized_metrics()

    // Performance history for trends
    perf_data["performance_history"] = performance_history.Copy()

    // Performance alerts and warnings
    perf_data["performance_alerts"] = get_performance_alerts()

    // Memory management statistics
    perf_data["memory_stats"] = get_memory_stats()

    return perf_data

/**
 * Gets current performance alerts and warnings.
 */
/datum/liquid_debug_manager/proc/get_performance_alerts()
    var/list/alerts = list()

    // Check for performance issues
    if(performance_metrics["average_processing_time"] > 50)
        alerts += "High processing time detected ([performance_metrics["average_processing_time"]]ms)"

    if(performance_metrics["pressure_pool_efficiency"] < 70)
        alerts += "Low cache efficiency ([performance_metrics["pressure_pool_efficiency"]]%)"

    if(current_debug_memory > debug_memory_limit * 0.8)
        alerts += "High debug memory usage ([current_debug_memory]/[debug_memory_limit] bytes)"

    if(SSliquid && length(SSliquid.cells_in_processing) > 50)
        alerts += "Many cells stuck in processing ([length(SSliquid.cells_in_processing)] cells)"

    return alerts

/**
 * Gets cell inspection data for detailed cell analysis.
 */
/datum/liquid_debug_manager/proc/get_cell_inspection_data()
    var/list/cell_data = list()

    if(selected_cell_data)
        cell_data["selected_cell"] = selected_cell_data

    // Add debugging context if available
    if(selected_pool_root)
        var/turf/T = locate(selected_pool_root)
        if(T?.cell)
            cell_data["pool_context"] = get_pool_context(T)

    return cell_data

/**
 * Gets pool context information for cell inspection.
 */
/datum/liquid_debug_manager/proc/get_pool_context(turf/T)
    var/list/context = list()

    if(GLOB.pool_manager)
        var/pool_size = GLOB.pool_manager.get_pool_size(T)
        var/pool_root = GLOB.pool_manager.dsu.find(T)

        context["pool_size"] = pool_size
        context["pool_root"] = "[pool_root]"
        context["is_processing"] = (T in SSliquid.cells_in_processing)

    return context

/**
 * Gets system reports data with different report types.
 */
/datum/liquid_debug_manager/proc/get_reports_data()
    var/list/reports_data = list()

    reports_data["available_reports"] = list(
        "system" = "Complete System Report",
        "performance" = "Performance Analysis",
        "integrity" = "System Integrity Check",
        "pools" = "Pool Statistics Report",
        "memory" = "Memory Usage Report"
    )

    if(system_report)
        reports_data["current_report"] = system_report
        reports_data["report_type"] = view_submode

    return reports_data

/**
 * Gets system management data for admin controls.
 */
/datum/liquid_debug_manager/proc/get_system_management_data()
    var/list/mgmt_data = list()

    // System controls
    mgmt_data["system_controls"] = list(
        "monitoring_enabled" = monitoring_enabled,
        "subsystem_running" = (SSliquid != null),
        "pool_manager_active" = (GLOB.pool_manager != null),
        "registry_active" = (GLOB.liquid_registry != null)
    )

    // Maintenance options
    mgmt_data["maintenance_options"] = list(
        "cache_size" = length(cell_debug_data),
        "performance_samples" = length(performance_history),
        "memory_usage" = current_debug_memory,
        "memory_limit" = debug_memory_limit
    )

    return mgmt_data

/**
 * Counts pools that meet critical criteria.
 */
/datum/liquid_debug_manager/proc/count_critical_pools()
    if(!GLOB.pool_manager)
        return 0

    var/critical_count = 0
    var/list/all_pools = GLOB.pool_manager.get_all_pools_for_debug()

    for(var/list/turf_list in all_pools)
        var/pool_cell_count = length(turf_list)
        if(pool_cell_count == 0) continue

        var/avg_fluid = GLOB.pool_manager.get_pool_avg_fluid(turf_list)

        // Consider pools critical if they're very large or have high fluid content
        if(pool_cell_count > 20 || avg_fluid > 50)
            critical_count++

    return critical_count

/**
 * Generates enhanced reports with better formatting.
 */
/datum/liquid_debug_manager/proc/generate_enhanced_report(report_type = "system")
    switch(report_type)
        if("system")
            return generate_system_report()
        if("performance")
            return generate_performance_report()
        if("integrity")
            return validate_system_integrity()
        if("pools")
            return generate_pools_report()
        if("memory")
            return generate_memory_report()
        else
            return generate_system_report()

/**
 * Generates a detailed performance analysis report.
 */
/datum/liquid_debug_manager/proc/generate_performance_report()
    var/list/report = list()

    report += "=== Liquid System Performance Report ==="
    report += "Generated: [time2text(world.time)]"
    report += ""

    // Performance metrics by category
    var/list/categorized = get_categorized_metrics()

    report += "=== Processing Performance ==="
    for(var/metric in categorized["processing"])
        report += "[metric]: [categorized["processing"][metric]]"
    report += ""

    report += "=== Cache Performance ==="
    for(var/metric in categorized["cache"])
        report += "[metric]: [categorized["cache"][metric]]"
    report += ""

    report += "=== System Health ==="
    for(var/metric in categorized["system"])
        report += "[metric]: [categorized["system"][metric]]"
    report += ""

    // Performance alerts
    var/list/alerts = get_performance_alerts()
    if(length(alerts) > 0)
        report += "=== Performance Alerts ==="
        for(var/alert in alerts)
            report += "! [alert]"
        report += ""

    return jointext(report, "\n")

/**
 * Generates a detailed pools analysis report.
 */
/datum/liquid_debug_manager/proc/generate_pools_report()
    var/list/report = list()

    report += "=== Pool Analysis Report ==="
    report += "Generated: [time2text(world.time)]"
    report += ""

    if(!GLOB.pool_manager)
        report += "ERROR: Pool manager not available"
        return jointext(report, "\n")

    var/list/pool_stats = GLOB.pool_manager.get_pool_statistics()

    report += "=== Pool Statistics ==="
    for(var/stat in pool_stats)
        report += "[stat]: [pool_stats[stat]]"
    report += ""

    // Pool size distribution
    var/list/all_pools = GLOB.pool_manager.get_all_pools_for_debug()
    var/small_pools = 0
    var/medium_pools = 0
    var/large_pools = 0
    var/critical_pools = 0

    for(var/list/turf_list in all_pools)
        var/pool_size = length(turf_list)
        if(pool_size == 0) continue

        var/avg_fluid = GLOB.pool_manager.get_pool_avg_fluid(turf_list)

        if(pool_size < 5)
            small_pools++
        else if(pool_size < 15)
            medium_pools++
        else
            large_pools++

        if(pool_size > 20 || avg_fluid > 50)
            critical_pools++

    report += "=== Pool Size Distribution ==="
    report += "Small pools (< 5 cells): [small_pools]"
    report += "Medium pools (5-14 cells): [medium_pools]"
    report += "Large pools (15+ cells): [large_pools]"
    report += "Critical pools: [critical_pools]"
    report += ""

    return jointext(report, "\n")

/**
 * Generates a memory usage analysis report.
 */
/datum/liquid_debug_manager/proc/generate_memory_report()
    var/list/report = list()

    report += "=== Memory Usage Report ==="
    report += "Generated: [time2text(world.time)]"
    report += ""

    var/list/memory_stats = get_memory_stats()

    report += "=== Debug Memory Usage ==="
    for(var/stat in memory_stats)
        report += "[stat]: [memory_stats[stat]]"
    report += ""

    report += "=== Cache Statistics ==="
    report += ""

    return jointext(report, "\n")

/**
 * Updates system health status based on current conditions.
 */
/datum/liquid_debug_manager/proc/update_system_health()
    var/current_time = world.time

    // Only update health status periodically
    if(current_time - last_health_check < 50) // Every 5 seconds
        return

    last_health_check = current_time
    system_alerts.len = 0

    // Check system components
    if(!SSliquid)
        system_alerts += "Liquid subsystem not running"
        system_health_status = "critical"
        return

    if(!GLOB.pool_manager)
        system_alerts += "Pool manager missing"
        system_health_status = "critical"
        return

    if(!GLOB.liquid_registry)
        system_alerts += "Liquid registry missing"
        system_health_status = "warning"

    // Check performance indicators
    if(performance_metrics["average_processing_time"] > 100)
        system_alerts += "Very high processing time"
        system_health_status = "warning"

    if(performance_metrics["pressure_pool_efficiency"] < 50)
        system_alerts += "Very low cache efficiency"
        system_health_status = "warning"

    if(current_debug_memory > debug_memory_limit)
        system_alerts += "Debug memory limit exceeded"
        system_health_status = "warning"

    if(length(SSliquid.cells_in_processing) > 100)
        system_alerts += "Many cells stuck in processing"
        system_health_status = "warning"

    // Set health status
    if(length(system_alerts) == 0)
        system_health_status = "healthy"
    else if(system_health_status != "critical")
        system_health_status = "warning"

/**
 * Periodic health check function.
 */
/datum/liquid_debug_manager/proc/periodic_health_check()
    while(TRUE)
        sleep(100) // Check every 10 seconds

        if(monitoring_enabled)
            update_system_health()

/**
 * Clears system alerts.
 */
/datum/liquid_debug_manager/proc/clear_system_alerts()
    system_alerts.len = 0
    system_health_status = "unknown"

/**
 * Gets unit testing data for tests view.
 */
/datum/liquid_debug_manager/proc/get_tests_data()
    var/list/tests_data = list()

    tests_data["tests_running"] = tests_running
    tests_data["test_results"] = test_results
    tests_data["test_suite_available"] = (GLOB.liquid_test_suite != null)

    if(GLOB.liquid_test_suite)
        tests_data["tests_run"] = GLOB.liquid_test_suite.tests_run
        tests_data["tests_passed"] = GLOB.liquid_test_suite.tests_passed
        tests_data["tests_failed"] = GLOB.liquid_test_suite.tests_failed
        tests_data["current_test"] = GLOB.liquid_test_suite.current_test

    return tests_data