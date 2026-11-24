/obj/machinery/door
	abstract_type = /obj/machinery/door
	name = "door"
	desc = "A door."
	icon = 'icons/obj/doors/airlocks/station/airlock.dmi'
	icon_state = "closed"
	density = TRUE
	opacity = TRUE
	anchored = TRUE
	layer = CLOSED_DOOR_LAYER
	can_atmos_pass = CANPASS_DENSITY
	max_integrity = /datum/material/steel::wall_integrity
	processing_flags = NONE
	/// The AC board installed in this door.
	var/obj/item/electronics/board = null
	/// The material of this door's panelling.
	var/datum/material/panel_material = null

/obj/machinery/door/Initialize(mapload)
	. = ..()
	update_appearance(UPDATE_ICON)

/obj/machinery/door/update_icon(updates)
	. = ..()
	var/panel_file = get_door_panel_icon(panel_material, max_integrity ? atom_integrity / max_integrity : 1)
	if(!isnull(panel_file))
		icon = panel_file

/obj/machinery/door/airlock
	name = "airlock"
	desc = "A steel airlock."

/// The one place a finished door takes its state from the frame it was welded out of.
/obj/machinery/door/airlock/proc/apply_from_frame(obj/structure/door_frame/frame)
	panel_material = frame.panel_material
	board = frame.board
	if(!isnull(board))
		board.forceMove(src)
	update_appearance(UPDATE_ICON)

/// Builds the frame back out of this door, carrying its fittings with it. The floor
/// under the door is left alone: a door is an object, so it never changes the turf.
/obj/machinery/door/airlock/proc/deconstruct_to_frame()
	var/obj/structure/door_frame/frame = new(drop_location())
	frame.panel_material = panel_material
	frame.anchored = TRUE
	frame.construction_stage = DOOR_CONSTRUCT_READY
	frame.update_smoothing(TRUE)
	if(!isnull(board))
		board.forceMove(frame)
		frame.board = board
		frame.fitting_stage = DOOR_FIT_BOARD_SECURED
	frame.advance_fitting()
	qdel(src)
	return frame

/obj/machinery/door/airlock/crowbar_act(mob/living/user, obj/item/tool)
	if(!Adjacent(user))
		return ..()
	balloon_alert_to_viewers("prying...")
	if(!tool.use_tool(src, user, DOOR_CONSTRUCT_STEP_TIME, volume = 50))
		return TRUE
	deconstruct_to_frame()
	return TRUE

/obj/machinery/door/airlock/atom_destruction(damage_flag)
	. = ..()
	deconstruct_to_frame()
