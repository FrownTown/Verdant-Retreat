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
// To add a new key: use the hash_key() proc or calculate a define with DJB2: hash=5381; foreach char: hash=((hash<<5)+hash)+ascii; mask by &0xffffff to avoid loss of integer precision

#define AIBLK_LAST_TARGET 13695615
#define AIBLK_LAST_KNOWN_TARGET_LOC 10935976
#define AIBLK_PURSUE_TIME 12167319
#define AIBLK_SEARCH_TIME 562345
#define AIBLK_SEARCH_START_TIME 14024310
#define AIBLK_PURSUE_START_TIME 7195876
#define AIBLK_FLEE_DIST 12196692
#define AIBLK_ACTION_TIMEOUT 8620521
#define AIBLK_TARGET_LOST_TIMER 5539341
#define AIBLK_HIBERNATION_TIMER 2991736
#define AIBLK_FIND_TARGET_TIMER 7758092
#define AIBLK_AGGRESSORS 10946821
#define AIBLK_AGRSR_RST_TMR 6766407
#define AIBLK_EXHAUSTED 8665680
#define AIBLK_KEEPAWAY_DIST 131750
#define AIBLK_STAND_UP_TIMER 4492771
#define AIBLK_UNDER_FIRE 4771272
#define AIBLK_LAST_ATTACKER 15063175
#define AIBLK_IN_COVER 1188954
#define AIBLK_COVER_TIMER 10849700
#define AIBLK_MOVE_ACTIVE 3066327
#define AIBLK_CHASE_TIMEOUT 4149295
#define AIBLK_ATTACKED_OBSTACLE 15688498
#define AIBLK_AI_COMMANDER 6149700
#define AIBLK_BUMBLE_STATE 13274236
#define AIBLK_BUMBLE_NEXT_TICK 16451172
#define AIBLK_COMBAT_STYLE 14664519
#define AIBLK_GRABBING 544577
#define AIBLK_BURST_COUNT 2616190
#define AIBLK_HIGH_VALUE_TARGET 13560583
#define AIBLK_STRAGGLER_TARGET 4858134
#define AIBLK_TIME_WAIT 10418344
#define AIBLK_AGGRO_LIST 9225520
#define AIBLK_TIMER_DELAY 686292
#define AIBLK_BURROWING 5041092
#define AIBLK_IS_ACTIVE 1792476
#define AIBLK_CHARGE_RATE 4535098
#define AIBLK_CURRENT_TARGET 5943758
#define AIBLK_SIGHT_RANGE 7881840
#define AIBLK_AGGRO_TICK 9512479
#define AIBLK_HAS_ATTACKED 9274209
#define AIBLK_IDLE_SOUNDS 4321054
#define AIBLK_IDLE_SOUND_TIMER 9531563
#define AIBLK_THREAT_SOUND 11473333
#define AIBLK_THREAT_MESSAGE 6807025
#define AIBLK_AGGRO_THRESHOLD 5081089
#define AIBLK_CRITTER_PATH 3278606
#define AIBLK_ATTACK_LIST 16428760
#define AIBLK_IDEAL_RANGE 835600
#define AIBLK_OBJECT_HIT 3792224
#define AIBLK_BLOODTYPE 4575575
#define AIBLK_BLOODCOLOR 13029524
#define AIBLK_HARVEST_LIST 10414045
#define AIBLK_DAMAGE_OVERLAY 2791429
#define AIBLK_OVERLAY_UPDATED 14406893
#define AIBLK_S_ACTION 10993397
#define AIBLK_AGGRESSION 10940183
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
#define AIBLK_PATH_BLOCKED_COUNT 12461837
#define AIBLK_SQUAD_ROLE 8233716
#define AIBLK_SQUAD_MATES 13630492
#define AIBLK_SQUAD_SIZE 8263581
#define AIBLK_CHECK_TARGET 13039401
#define AIBLK_CHOSEN_TARGET 8146123
#define AIBLK_COMMAND_MODE 2016872
#define AIBLK_DEFENDING_FROM_INTERRUPT 9948968
#define AIBLK_EATING_BODY 1702666
#define AIBLK_FOLLOW_TARGET 902462
#define AIBLK_FOOD_TARGET 2726067
#define AIBLK_FRIEND_REF 15163193
#define AIBLK_IGNORED_TARGETS 1254310
#define AIBLK_IS_PINNING 12914067
#define AIBLK_LAST_TARGET_SWITCH_TIME 5343966
#define AIBLK_MINION_FOLLOW_TARGET 9760359
#define AIBLK_MINION_TRAVEL_DEST 6229195
#define AIBLK_PERFORM_EMOTE_ID 743333
#define AIBLK_POSSIBLE_TARGETS 13327583
#define AIBLK_REINFORCEMENTS_COOLDOWN 13156813
#define AIBLK_REINFORCEMENTS_SAY 9442869
#define AIBLK_TAMED 6891632
#define AIBLK_USE_TARGET 15759320
#define AIBLK_VALID_TARGETS 7161902
#define AIBLK_VIOLATION_INTERRUPTED 5115951
#define AIBLK_DRAG_START_LOC 2049293
#define AIBLK_NEXT_HUNGER_CHECK 12679273
#define AIBLK_PERFORM_SPEECH_TEXT 1289723
#define AIBLK_TARGETED_ACTION 10774546
#define AIBLK_DEADITE_MIGRATION_PATH 15186154

// Defines related to squad behavior, all of these except for the "AIBLK_SQUAD_DATUM" reference (which should be set on the mob's blackboard) are generally stored in a shared blackboard for the squad's ai_squad datum.
#define AIBLK_SQUAD_DATUM 2957725
#define AIBLK_SQUAD_PRIORITY_TARGET 11358634
#define AIBLK_SQUAD_KNOWN_ENEMIES 15147316
#define AIBLK_SQUAD_TACTICAL_TARGET 7822512
#define AIBLK_SQUAD_PRIORITY_TARGET_IN_COVER 8395325
#define AIBLK_SQUAD_HUNT_TARGET 5601831
#define AIBLK_SQUAD_SHOULD_REGROUP 2687316
#define AIBLK_SQUAD_PATROL_TARGET 11625082
#define AIBLK_SQUAD_HUNT_LOCATION 14381209
#define AIBLK_MONSTER_BAIT 5128972

// Defines for goblin squad roles
#define GOB_SQUAD_ROLE_RESTRAINER 1
#define GOB_SQUAD_ROLE_STRIPPER 2
#define GOB_SQUAD_ROLE_VIOLATOR 3
#define GOB_SQUAD_ROLE_ATTACKER 4

// Defines for goblin restrainer states
#define GOB_RESTRAIN_STATE_NONE 0
#define GOB_RESTRAIN_STATE_GRABBING 1
#define GOB_RESTRAIN_STATE_UPGRADING 2
#define GOB_RESTRAIN_STATE_TACKLING 3
#define GOB_RESTRAIN_STATE_PINNING 4
#define GOB_RESTRAIN_STATE_PINNED 5

// Blackboard key for restrainer state
#define AIBLK_RESTRAIN_STATE 8745623

// ==============================================================================
// STATEFUL BEHAVIOR TREE - SIGNAL SYSTEM
// ==============================================================================
// These signals are used by Observer nodes and Service nodes to implement
// event-driven behavior instead of polling every tick

// Fired when the mob's target changes (acquired, lost, or switched)
#define COMSIG_AI_TARGET_CHANGED "ai_target_changed"

// Fired when blackboard data critical to decision-making is updated
#define COMSIG_AI_BLACKBOARD_UPDATED "ai_blackboard_updated"

// Fired when the mob takes damage or is attacked
#define COMSIG_AI_ATTACKED "ai_attacked"

// Fired when the mob's health drops below a threshold
#define COMSIG_AI_LOW_HEALTH "ai_low_health"

// Fired when pain is critical (for fleeing)
#define COMSIG_AI_PAIN_CRIT "ai_pain_crit"

// Fired when hunger is high (for scavenging)
#define COMSIG_AI_HUNGRY "ai_hungry"

// Fired when squad state changes (role assigned, squad formed, etc.)
#define COMSIG_AI_SQUAD_CHANGED "ai_squad_changed"

// Fired when target becomes incapacitated
#define COMSIG_AI_TARGET_INCAPACITATED "ai_target_incapacitated"

// Fired when target recovers from incapacitation
#define COMSIG_AI_TARGET_RECOVERED "ai_target_recovered"

// Fired when movement is blocked repeatedly
#define COMSIG_AI_PATH_BLOCKED "ai_path_blocked"

// Fired when movement fails completely (repath needed)
#define COMSIG_AI_MOVEMENT_FAILED "ai_movement_failed"

#define SS_PRIORITY_AI 67
#define INIT_ORDER_AI 8