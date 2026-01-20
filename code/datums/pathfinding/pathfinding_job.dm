// ==============================================================================
// PATHFINDING JOB
// ==============================================================================

//================================================================
// --- Pathfinding Job Datum ---
// Encapsulates all data and logic for a single A* search.
// These are created and recycled by the main subsystem.
// We then use lists to actually track and store path and values.
// Before, there was a PathNode datum for every turf in the path.
// Now we only use a single datum for the entire job, and after
// we're done with it, we put it back in the pool, reducing the
// number of created objects from 1 per turf to 2 per job.
//================================================================
/pathfinding_job
	parent_type = /datum
	var/alist/parent      = new()
	var/alist/g_score     = new()
	var/alist/f_score     = new()
	var/alist/closed_set  = new()
	var/PriorityQueue/open_set
	var/path_comparer/comparer

/pathfinding_job/New()
	..()

	comparer = new (src.f_score)
	open_set = new /PriorityQueue(comparer)

/pathfinding_job/proc/Run(mob/living/mover, turf/start, turf/end, max_cost = INFINITY) as /list // By default, no max cost. Pass into A_Star() to limit search depth.
	start = get_turf(start)
	end = get_turf(end)
	if(!start || !end) return

	g_score[start] = 0
	f_score[start] = heuristic(start, end)
	open_set.EnqueueComparer(start)

	while(!open_set.IsEmpty())

		var/turf/current = open_set.Dequeue()

		if(current == end)
			return reconstruct_path(parent, current)

		closed_set[current] = TRUE

		for(var/turf/neighbor as anything in get_neighbors_3d(mover, current))
			if(closed_set[neighbor]) continue

			var/tentative_g_score = g_score[current] + get_move_cost(mover, current, neighbor)

			if(max_cost > 0 && tentative_g_score > max_cost)
				continue

			var/existing_g_score = g_score[neighbor]

			if(existing_g_score && tentative_g_score >= existing_g_score) continue

			parent[neighbor] = current
			g_score[neighbor] = tentative_g_score
			f_score[neighbor] = tentative_g_score + heuristic(neighbor, end)

			open_set.EnqueueComparer(neighbor)

	return

/pathfinding_job/proc/Reset()
	parent.len = 0
	g_score.len = 0
	f_score.len = 0
	closed_set.len = 0
	open_set.Clear()

//================================================================
// --- Helper Datums & Procs ---
//================================================================

// Helper object to allow the PriorityQueue to compare turfs using f_score, this gives us a 3-way comparison.
/path_comparer
	parent_type = /datum
	var/alist/f_scores

/path_comparer/New(alist/scores)
	src.f_scores = scores
	..	()

/path_comparer/proc/Compare(turf/a, turf/b) as num
	if(!a) return 1
	if(!b) return -1
	return f_scores[a] - f_scores[b]
