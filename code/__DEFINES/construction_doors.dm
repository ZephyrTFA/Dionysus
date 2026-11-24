/*ALL DEFINES RELATED TO DOOR CONSTRUCTION, DOOR DECONSTRUCTION, OR DOOR FITTINGS GO HERE*/

//The main construction stages of a door frame.
#define DOOR_CONSTRUCT_FRAME 0
#define DOOR_CONSTRUCT_SECURED 1
#define DOOR_CONSTRUCT_WIRED 2
#define DOOR_CONSTRUCT_READY 3

//The optional fitting branch, walked only as far as the fittings actually installed.
//Mirrors the wall's deconstruction_r_step: a frame with no board and no panelling
//simply never leaves DOOR_FIT_NONE.
#define DOOR_FIT_NONE 0
#define DOOR_FIT_BOARD_SEATED 1
#define DOOR_FIT_BOARD_SECURED 2
#define DOOR_FIT_PANEL_HUNG 3
#define DOOR_FIT_PANEL_SECURED 4
#define DOOR_FIT_PANEL_FINALIZED 5

//How long a single tool step takes.
#define DOOR_CONSTRUCT_STEP_TIME 2 SECONDS
//Fittings take longer, as the wall's reinforced branch does.
#define DOOR_CONSTRUCT_FIT_STEP_TIME 5 SECONDS

//Costs of each part of a door, in the units the fitting is measured in.
#define DOOR_FRAME_COST 2
#define DOOR_WIRING_COST 5
#define DOOR_BOARD_COST 1
#define DOOR_PANEL_COST 1
