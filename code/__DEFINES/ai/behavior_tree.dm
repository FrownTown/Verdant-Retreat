// ==============================================================================
// BEHAVIOR TREE DEFINES
// ==============================================================================

#define NODE_FAILURE	0
#define NODE_SUCCESS 	1
#define NODE_RUNNING	2

#define AI_HIBERNATION_RANGE 15 // How far away players need to be for an AI to go to sleep.
#define AI_HIBERNATION_DELAY 20 SECONDS // The amount of time before an AI goes to sleep if there are no players nearby.
#define NPC_VIEWRANGE 15 // How far NPCs can see for line-of-sight checks.
#define AI_FIND_TARGET_DELAY 2 SECONDS // The amount of time between the AI's searches for new targets.
#define AI_AGGRESSORS_RESET 10 SECONDS // How long to wait before resetting aggressors if an AI ends up without a target.
#define AI_SQUAD_MAX_JOIN_DIST 15
#define AI_SQUAD_MERGE_DIST 15

// These defines are defaults for things that can be changed while initializing an AI.
#define AI_DEFAULT_THINK_DELAY 0.5 SECONDS
#define AI_DEFAULT_MOVE_DELAY 1 SECOND // MAY THEY RUN (this allows us to set custom move delays on a per-mob basis by accessing the mob's ai_root node.next_move_delay variable. Setting it to 1 decisecond allows NPCs to move as fast as players.)
#define AI_DEFAULT_ATTACK_DELAY 1 SECOND
#define AI_DEFAULT_CHATTER_DELAY 3 SECONDS
#define AI_DEFAULT_EMOTE_DELAY 5 SECONDS
#define AI_DEFAULT_MAX_FEAR 60
#define AI_DEFAULT_PURSUE_TIME 10 SECONDS
#define AI_DEFAULT_SEARCH_TIME 10 SECONDS
#define AI_DEFAULT_KEEPAWAY_DIST 3
#define AI_DEFAULT_FLEE_DIST 10
#define AI_DEFAULT_CHASE_TIMEOUT 4 SECONDS
#define AI_DEFAULT_REPATH_DELAY 0.5 SECONDS
#define AI_DEFAULT_SLEEP_DELAY 80 SECONDS

// Flags related to the action timer.
#define AI_ACTION_FIRST_ATTEMPT 1
#define AI_ACTION_TIMED_OUT 2
#define AI_ACTION_WAITING 3
// Defines related to specific behaviors and their states or other variables.

#define AI_BUMBLE_STATE_IDLE 1
#define AI_BUMBLE_STATE_MOVING 2

// These are flags that can be set to control AI behavior in situations where it is not possible or inconvenient to do so - e.g., if the mob smashes obstacles, the check needs to be made in the pathfinding code.
#define AI_FLAG_SMASH_OBSTACLES 0x1
#define AI_FLAG_FEARLESS 0x2
#define AI_FLAG_PERSISTENT 0x4 // For mobs that don't sleep.
#define AI_FLAG_ASSUMEDIRECTCONTROL 0x8 // Used to prevent NPCs that are being controlled by an admin using AI commander from going back to sleep if there are no players around.
#define AI_FLAG_FORCESLEEP 0x16 // Forces the mob to skip processing, used for certain status effects etc.

// Defines for AI states tracked by the AI commander module
#define AI_CMD_STATE_MOVE 0
#define AI_CMD_STATE_ATTACK 1


// Below are the AI blackboard block IDs. Basically, these are just strings used as keys in an associative list. The values can be whatever arbitrary data the AI needs to track.
// Since the blackboard best operates by staying small and adding/removing keys as needed, some variables that are accessed every tick are defined on the behavior tree node itself, and are not stored in the blackboard.
// For example, the next_think_delay variable is stored in the node itself, not the blackboard. Variables that do not need to be accessed as frequently are safe to store in the blackboard and can be added here as string defines.

#define AIBLK_LAST_TARGET "last_target"
#define AIBLK_LAST_KNOWN_TARGET_LOC "last_known_target_loc"
#define AIBLK_PURSUE_TIME "pursue_time"
#define AIBLK_SEARCH_TIME "search_time"
#define AIBLK_SEARCH_START_TIME "search_start_time"
#define AIBLK_PURSUE_START_TIME "pursue_start_time"
#define AIBLK_FLEE_DIST "flee_dist"
#define AIBLK_ACTION_TIMEOUT "action_timeout"
#define AIBLK_TARGET_LOST_TIMER "target_lost_timer"
#define AIBLK_HIBERNATION_TIMER "hibernation_timer"
#define AIBLK_FIND_TARGET_TIMER "find_target_timer"
#define AIBLK_AGGRESSORS "aggressors"
#define AIBLK_AGRSR_RST_TMR "aggressors_reset_timer"
#define AIBLK_EXHAUSTED "exhausted"
#define AIBLK_KEEPAWAY_DIST "keepaway_distance"
#define AIBLK_STAND_UP_TIMER "stand_up_timer"
#define AIBLK_UNDER_FIRE "under_fire"
#define AIBLK_LAST_ATTACKER "last_attacker"
#define AIBLK_IN_COVER "in_cover"
#define AIBLK_COVER_TIMER "cover_timer"
#define AIBLK_MOVE_ACTIVE "move_active"
#define AIBLK_CHASE_TIMEOUT "chase_timeout"
#define AIBLK_ATTACKED_OBSTACLE "attacked_obstacle"
#define AIBLK_AI_COMMANDER "ai_commander"
#define AIBLK_BUMBLE_STATE "bumble_state"
#define AIBLK_BUMBLE_NEXT_TICK "bumble_next_tick"
#define AIBLK_COMBAT_STYLE "fight_style"
#define AIBLK_GRABBING "grabbing"
#define AIBLK_BURST_COUNT "burstcount"
#define AIBLK_HIGH_VALUE_TARGET "high_value_target"
#define AIBLK_STRAGGLER_TARGET "straggler_target"
#define AIBLK_TIME_WAIT "time_wait"
#define AIBLK_AGGRO_LIST "aggro_list"
#define AIBLK_TIMER_DELAY "timer_delay"
#define AIBLK_BURROWING "burrowing"
#define AIBLK_IS_ACTIVE "is_active"
#define AIBLK_CHARGE_RATE "charge_rate"
#define AIBLK_CURRENT_TARGET "current_target"
#define AIBLK_SIGHT_RANGE "sight_range"
#define AIBLK_AGGRO_TICK "aggro_tick"
#define AIBLK_HAS_ATTACKED "has_attacked"
#define AIBLK_IDLE_SOUNDS "idle_sounds"
#define AIBLK_IDLE_SOUND_TIMER "idle_sound_timer"
#define AIBLK_THREAT_SOUND "threat_sound"
#define AIBLK_THREAT_MESSAGE "threat_message"
#define AIBLK_AGGRO_THRESHOLD "aggro_threshold"
#define AIBLK_CRITTER_PATH "critter_path"
#define AIBLK_ATTACK_LIST "attack_list"
#define AIBLK_IDEAL_RANGE "ideal_range"
#define AIBLK_OBJECT_HIT "object_hit"
#define AIBLK_BLOODTYPE "bloodtype"
#define AIBLK_BLOODCOLOR "bloodcolor"
#define AIBLK_HARVEST_LIST "harvest_list"
#define AIBLK_DAMAGE_OVERLAY "damage_overlay"
#define AIBLK_OVERLAY_UPDATED "overlay_updated"
#define AIBLK_S_ACTION "s_action"

#define AIBLK_AGGRESSION "aggression"
#define AIBLK_AGGRESSION_PACIFIST 0
#define AIBLK_AGGRESSION_DEFENSIVE 1
#define AIBLK_AGGRESSION_AGGRESSIVE 2
#define AIBLK_AGGRESSION_BERSERK 3

// --- GOAP Blackboard Keys ---
#define AIBLK_GOAP_PLAN "goap_plan"
#define AIBLK_GOAP_CURRENT_ACTION "goap_current_action"
#define AIBLK_WORLD_STATE "world_state"
#define AIBLK_CURRENT_GOAL "current_goal"
#define AIBLK_PLAN_MONITOR_ACTIVE "plan_monitor_active"
#define AIBLK_CURRENT_BT_ACTION "current_bt_action"
#define AIBLK_TEMP_GOAL "temp_goal"
#define AIBLK_GOAP_PLAN_STEP "goap_plan_step"


// The following are defines for fighting styles. Mobs have a default behavior regardless, but this lets us do different things sometimes to make them more interesting.
#define AI_STYLE_DEFAULT 0
#define AI_STYLE_UNARMED 1
#define AI_STYLE_ONEHANDED 2
#define AI_STYLE_TWOHANDED 3
#define AI_STYLE_DUALWIELD 4

// Defines related to squad behavior, all of these except for the "AIBLK_SQUAD_DATUM" reference (which should be set on the mob's blackboard) are generally stored in a shared blackboard for the squad's ai_squad datum.
#define AIBLK_SQUAD_DATUM "squad_datum"
#define AIBLK_SQUAD_PRIORITY_TARGET "squad_priority_target"
#define AIBLK_SQUAD_KNOWN_ENEMIES "squad_known_enemies"
#define AIBLK_SQUAD_TACTICAL_TARGET "tactical_target"
#define AIBLK_SQUAD_PRIORITY_TARGET_IN_COVER "squad_target_in_cover"
#define AIBLK_SQUAD_HUNT_TARGET "squad_hunt_target"
#define AIBLK_SQUAD_SHOULD_REGROUP "squad_should_regroup"
#define AIBLK_SQUAD_PATROL_TARGET "squad_patrol_target"
#define AIBLK_SQUAD_HUNT_LOCATION "squad_hunt_location"
#define AIBLK_MONSTER_BAIT "monster_bait"

#define SS_PRIORITY_AI 67
#define INIT_ORDER_AI 8
