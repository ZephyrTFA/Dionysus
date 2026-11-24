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
	// Nothing to process yet: opening, power and access all come later.
	processing_flags = NONE
	/// The AC board installed in this door, carried over from its frame.
	var/obj/item/electronics/board = null
	/// The material of this door's panelling. Visual only: it never touches integrity.
	var/datum/material/panel_material = null

/obj/machinery/door/airlock
	name = "airlock"
	desc = "A steel airlock."
