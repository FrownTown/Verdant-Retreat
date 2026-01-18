/**
 * A Disjoint Set Union (DSU) or "Union-Find" data structure.
 *
 * An optimized data structure for tracking a partition of a set into disjoint subsets.
 * It is extremely efficient for determining if two elements are in the same subset
 * and for merging two subsets. This implementation uses both Path Compression and
 * Union by Size optimizations, which is about as close to O(1) as you can get.
 *
 * Used for liquid pools, but this could also be used for tracking any connected networks like power grids, etc.
 *
 * How to use:
 * 1. Create a new instance: var/dsu = new disjoint_set()
 * 2. Add elements to track: dsu.add_element(1)
 * 3. Merge sets: dsu.union(1, 2)
 * 4. Check for connectivity: if (dsu.is_connected(1, 4)) ...
 *
 */
/disjoint_set
	parent_type = /datum
	/// An associative list mapping each element to its parent in the tree.
	var/list/parent

	/// An associative list mapping a set's root element to its size.
	var/list/sizes

	/// The total number of disjoint sets currently being tracked.
	var/component_count = 0

/**
 * Constructor for the data structure.
 */
/disjoint_set/New()
	parent = list()
	sizes = list()
	..() // Standard BYOND practice to call parent's New()

/**
 * Adds a new element to the data structure, placing it in its own set.
 *
 * @param element The atom or value to add. Can be any datum, obj, turf, etc.
 */
/disjoint_set/proc/add_element(element)
	if (element in parent)
		return // Already in a set, do nothing.

	parent[element] = element // An element is its own parent initially.
	sizes[element] = 1        // The new set has a size of 1.
	component_count++

/**
 * Finds the representative (root) of the set containing the given element.
 *
 * This proc implements the **Path Compression** optimization. After finding
 * the root, it makes all nodes along the path point directly to the root,
 * dramatically speeding up future lookups.
 *
 * @param element The element whose set root we want to find.
 * @return The root element of the set, or null if the element is not in the DSU.
 */
/disjoint_set/proc/find(element)
	if (!(element in parent))
		return null // Not part of any set.

	// Find the root by traversing parent pointers.
	var/root = element
	while (parent[root] != root)
		root = parent[root]

	// Path Compression: Re-traverse the path and point all nodes to the root.
	var/current = element
	while (parent[current] != root)
		var/next = parent[current]
		parent[current] = root
		current = next

	return root

/**
 * Merges the sets containing two given elements into a single set.
 *
 * This proc implements the **Union by Size** optimization. It attaches
 * the smaller set's tree to the root of the larger set's tree to keep
 * the trees balanced and shallow.
 *
 * @param element_a The first element.
 * @param element_b The second element.
 * @return TRUE if a merge occurred, FALSE if they were already in the same set.
 */
/disjoint_set/proc/union(element_a, element_b)
	var/root_a = find(element_a)
	var/root_b = find(element_b)

	// If either element isn't in the DSU or they are already in the same set.
	if (!root_a || !root_b || root_a == root_b)
		return FALSE

	// Union by Size: Attach the smaller tree to the root of the larger tree.
	if (sizes[root_a] < sizes[root_b])
		// Swap them so root_a is always the larger set
		var/temp = root_a
		root_a = root_b
		root_b = temp

	// Merge smaller set (root_b) into the larger one (root_a).
	parent[root_b] = root_a
	sizes[root_a] += sizes[root_b]
	sizes -= root_b // Remove the size entry for the old root.

	component_count--
	return TRUE

/**
 * A convenience proc to check if two elements belong to the same set.
 *
 * @param element_a The first element.
 * @param element_b The second element.
 * @return TRUE if they are connected, FALSE otherwise.
 */
/disjoint_set/proc/is_connected(element_a, element_b)
	var/root_a = find(element_a)
	var/root_b = find(element_b)
	return root_a && (root_a == root_b)

/**
 * A convenience proc to get the size of the set an element belongs to.
 *
 * @param element The element to query.
 * @return The number of elements in the set, or 0 if the element is not found.
 */
/disjoint_set/proc/get_set_size(element)
	var/root = find(element)
	if (!root)
		return 0
	return sizes[root]
