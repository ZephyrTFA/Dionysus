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

/obj/machinery/door/airlock
	name = "airlock"
	desc = "A steel airlock."

/// The one place a finished door takes its state from the frame it was welded out of.
/obj/machinery/door/airlock/proc/apply_from_frame(obj/structure/door_frame/frame)
	panel_material = frame.panel_material
	board = frame.board
	if(!isnull(board))
		board.forceMove(src)
	icon = frame.panel_icon() || initial(icon)
	update_appearance()
