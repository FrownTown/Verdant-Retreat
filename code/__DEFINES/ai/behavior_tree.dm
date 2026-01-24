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


// Below are the AI blackboard block IDs. These are pre-hashed integers using DJB2 for O(1) lookup performance.
// Since the blackboard best operates by staying small and adding/removing keys as needed, some variables that are accessed every tick are defined on the behavior tree node itself, and are not stored in the blackboard.
// For example, the next_think_delay variable is stored in the node itself, not the blackboard. Variables that do not need to be accessed as frequently are safe to store in the blackboard and can be added here.
// To add a new key: use the hash_key() proc or calculate offline with DJB2: hash=5381; foreach char: hash=((hash<<5)+hash)+ascii

#define AIBLK_LAST_TARGET 3201366655
#define AIBLK_LAST_KNOWN_TARGET_LOC 933682856
#define AIBLK_PURSUE_TIME 1052354711
#define AIBLK_SEARCH_TIME 2198377641
#define AIBLK_SEARCH_START_TIME 232128118
#define AIBLK_PURSUE_START_TIME 762170596
#define AIBLK_FLEE_DIST 1488591700
#define AIBLK_ACTION_TIMEOUT 1803782633
#define AIBLK_TARGET_LOST_TIMER 1247053325
#define AIBLK_HIBERNATION_TIMER 4063078008
#define AIBLK_FIND_TARGET_TIMER 477520140
#define AIBLK_AGGRESSORS 3852929285
#define AIBLK_AGRSR_RST_TMR 4083629895
#define AIBLK_EXHAUSTED 3598989904
#define AIBLK_KEEPAWAY_DIST 1895957158
#define AIBLK_STAND_UP_TIMER 3611594211
#define AIBLK_UNDER_FIRE 3578318280
#define AIBLK_LAST_ATTACKER 3907377287
#define AIBLK_IN_COVER 1527915610
#define AIBLK_COVER_TIMER 1403358628
#define AIBLK_MOVE_ACTIVE 3593390551
#define AIBLK_CHASE_TIMEOUT 3661582383
#define AIBLK_ATTACKED_OBSTACLE 2750374706
#define AIBLK_AI_COMMANDER 1616762436
#define AIBLK_BUMBLE_STATE 1238011004
#define AIBLK_BUMBLE_NEXT_TICK 3640329828
#define AIBLK_COMBAT_STYLE 1457505095
#define AIBLK_GRABBING 3137883969
#define AIBLK_BURST_COUNT 3727158142
#define AIBLK_HIGH_VALUE_TARGET 1070525191
#define AIBLK_STRAGGLER_TARGET 2336891158
#define AIBLK_TIME_WAIT 1520367784
#define AIBLK_AGGRO_LIST 4220306736
#define AIBLK_TIMER_DELAY 4245321940
#define AIBLK_BURROWING 3712805828
#define AIBLK_IS_ACTIVE 1427855836
#define AIBLK_CHARGE_RATE 1715811130
#define AIBLK_CURRENT_TARGET 3327832526
#define AIBLK_SIGHT_RANGE 477643888
#define AIBLK_AGGRO_TICK 4220593695
#define AIBLK_HAS_ATTACKED 1250788193
#define AIBLK_IDLE_SOUNDS 843181854
#define AIBLK_IDLE_SOUND_TIMER 1670475947
#define AIBLK_THREAT_SOUND 3266253237
#define AIBLK_THREAT_MESSAGE 1164434929
#define AIBLK_AGGRO_THRESHOLD 1531807745
#define AIBLK_CRITTER_PATH 2553415438
#define AIBLK_ATTACK_LIST 1526378200
#define AIBLK_IDEAL_RANGE 202162192
#define AIBLK_OBJECT_HIT 2939805024
#define AIBLK_BLOODTYPE 2688930135
#define AIBLK_BLOODCOLOR 2814824596
#define AIBLK_HARVEST_LIST 564062173
#define AIBLK_DAMAGE_OVERLAY 1630181381
#define AIBLK_OVERLAY_UPDATED 2463880429
#define AIBLK_S_ACTION 396869365
#define AIBLK_AGGRESSION 3852922647
#define AIBLK_AGGRESSION_PACIFIST 0
#define AIBLK_AGGRESSION_DEFENSIVE 1
#define AIBLK_AGGRESSION_AGGRESSIVE 2
#define AIBLK_AGGRESSION_BERSERK 3

// --- GOAP Blackboard Keys (UNUSED - GOAP not implemented, kept for future reference) ---
/*
#define AIBLK_GOAP_PLAN "goap_plan"
#define AIBLK_GOAP_CURRENT_ACTION "goap_current_action"
#define AIBLK_WORLD_STATE "world_state"
#define AIBLK_CURRENT_GOAL "current_goal"
#define AIBLK_PLAN_MONITOR_ACTIVE "plan_monitor_active"
#define AIBLK_CURRENT_BT_ACTION "current_bt_action"
#define AIBLK_TEMP_GOAL "temp_goal"
#define AIBLK_GOAP_PLAN_STEP "goap_plan_step"
*/


// The following are defines for fighting styles. Mobs have a default behavior regardless, but this lets us do different things sometimes to make them more interesting.
#define AI_STYLE_DEFAULT 0
#define AI_STYLE_UNARMED 1
#define AI_STYLE_ONEHANDED 2
#define AI_STYLE_TWOHANDED 3
#define AI_STYLE_DUALWIELD 4

// Additional common blackboard keys
#define AIBLK_PATH_BLOCKED_COUNT 1337861901
#define AIBLK_SQUAD_ROLE 2256380660
#define AIBLK_SQUAD_MATES 1439693852
#define AIBLK_SQUAD_SIZE 2256410525
#define AIBLK_CHECK_TARGET 2126968617
#define AIBLK_CHOSEN_TARGET 3313257675
#define AIBLK_COMMAND_MODE 4095657576
#define AIBLK_DEFENDING_FROM_INTERRUPT 2090323752
#define AIBLK_EATING_BODY 3407477514
#define AIBLK_FOLLOW_TARGET 957203774
#define AIBLK_FOOD_TARGET 1093245107
#define AIBLK_FRIEND_REF 4276576057
#define AIBLK_IGNORED_TARGETS 2970821542
#define AIBLK_IS_PINNING 2294615443
#define AIBLK_LAST_TARGET_SWITCH_TIME 760318686
#define AIBLK_MINION_FOLLOW_TARGET 3784633959
#define AIBLK_MINION_TRAVEL_DEST 3428781259
#define AIBLK_PERFORM_EMOTE_ID 436950949
#define AIBLK_POSSIBLE_TARGETS 1774935263
#define AIBLK_REINFORCEMENTS_COOLDOWN 2663956941
#define AIBLK_REINFORCEMENTS_SAY 1972377141
#define AIBLK_TAMED 275327088
#define AIBLK_USE_TARGET 1055946712
#define AIBLK_VALID_TARGETS 1936541742
#define AIBLK_VIOLATION_INTERRUPTED 2051936303
#define AIBLK_DRAG_START_LOC 3709814029
#define AIBLK_NEXT_HUNGER_CHECK 197228649
#define AIBLK_PERFORM_SPEECH_TEXT 2131996155
#define AIBLK_TARGETED_ACTION 1050961938
#define AIBLK_DEADITE_MIGRATION_PATH 2615654634

// Defines related to squad behavior, all of these except for the "AIBLK_SQUAD_DATUM" reference (which should be set on the mob's blackboard) are generally stored in a shared blackboard for the squad's ai_squad datum.
#define AIBLK_SQUAD_DATUM 1429021085
#define AIBLK_SQUAD_PRIORITY_TARGET 2477609386
#define AIBLK_SQUAD_KNOWN_ENEMIES 1239884084
#define AIBLK_SQUAD_TACTICAL_TARGET 2708954288
#define AIBLK_SQUAD_PRIORITY_TARGET_IN_COVER 3665828413
#define AIBLK_SQUAD_HUNT_TARGET 3646257703
#define AIBLK_SQUAD_SHOULD_REGROUP 1646854484
#define AIBLK_SQUAD_PATROL_TARGET 2494653050
#define AIBLK_SQUAD_HUNT_LOCATION 886796441
#define AIBLK_MONSTER_BAIT 2437825292

// Defines for goblin squad roles
#define GOB_SQUAD_ROLE_RESTRAINER 1
#define GOB_SQUAD_ROLE_STRIPPER 2
#define GOB_SQUAD_ROLE_VIOLATOR 3
#define GOB_SQUAD_ROLE_ATTACKER 4

#define SS_PRIORITY_AI 67
#define INIT_ORDER_AI 8
