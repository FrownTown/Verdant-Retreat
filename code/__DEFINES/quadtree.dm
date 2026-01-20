// ==============================================================================
// QUADTREE DEFINES
// ==============================================================================

#define SS_PRIORITY_QUADTREE		68
#define INIT_ORDER_QUADTREE  10

#define QUADTREE_CAPACITY 12
#define QUADTREE_BOUNDARY_MINIMUM_WIDTH 12
#define QUADTREE_BOUNDARY_MINIMUM_HEIGHT 12
#define QTREE_EXCLUDE_OBSERVER 1
#define QTREE_SCAN_MOBS 2
#define QTREE_SCAN_HEARABLES 4

#define RECT new /datum/shape/rectangle
#define QTREE new /datum/quadtree

#define SEARCH_QTREE(qtree, shape_range, flags) qtree.query_range(shape_range, null, flags)
#define ENTITIES_IN_RANGE(npc) (SSquadtree.players_in_range((npc).qt_range, (npc).z, QTREE_SCAN_MOBS|QTREE_EXCLUDE_OBSERVER) + SSquadtree.npcs_in_range((npc).qt_range, (npc).z, QTREE_SCAN_MOBS|QTREE_EXCLUDE_OBSERVER))
