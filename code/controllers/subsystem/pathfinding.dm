// ==============================================================================
// PATHFINDING SUBSYSYSTEM
// ==============================================================================

//================================================================
// PATHFINDING SUBSYSYSTEM
//================================================================
// This subsystem provides a high-performance, globally accessible A*
// pathfinding service. It should be drastically more performant than
// the previous version.
//
// Same usage as before - to use from anywhere in the code, simply call:
//      var/list/path = A_Star(mob.loc, target_loc)
//
// It uses a job pooling model to avoid runtime memory allocations and
// prevent garbage collection from lagging the server to death.
//================================================================

SUBSYSTEM_DEF(pathfinding)
	name = "Pathfinding"
	priority = SS_PRIORITY_AI
	init_order = INIT_ORDER_AI
	runlevels = RUNLEVELS_DEFAULT
	flags = SS_NO_FIRE
	// This subsystem doesn't tick, so we don't need to give it a wait.

	// This is our pool of reusable job objects.
	var/list/job_pool
	var/list/patrol_nodes

/datum/controller/subsystem/pathfinding/Initialize()
	NEW_SS_GLOBAL(SSpathfinding)

	job_pool = new
	patrol_nodes = new // This has to be manually populated by placing patrol points on the map, otherwise it just won't be used, which is also fine.

	for(var/i = 1; i <= 10; i++) // Preinitialize a few job datums to avoid first-tick latency
		job_pool += new /pathfinding_job()

	..	()


/datum/controller/subsystem/pathfinding/proc/FindPath(mob/living/mover, turf/start, turf/end)
	var/pathfinding_job/job = GetJob()
	var/list/path = job.Run(mover, start, end)
	RecycleJob(job)
	return path

	// Retrieves a job from the pool or creates one if needed.
/datum/controller/subsystem/pathfinding/proc/GetJob() as /pathfinding_job
	if(length(job_pool))
		var/pathfinding_job/job = job_pool[length(job_pool)]
		job_pool.len--
		return job
	else
		return new /pathfinding_job()

	// Resets a job and returns it to the pool for reuse.
/datum/controller/subsystem/pathfinding/proc/RecycleJob(pathfinding_job/job)
	if(length(job_pool) < MAX_POOLED_PATHING_JOBS) // This is to make sure we don't end up with *too* many of these if there's a ton of pathfinding requests at once for whatever reason.
		job.Reset()
		job_pool += job
	else
		qdel(job) // If this does end up happening somehow, don't worry - it'll just try again until there's a free request.
