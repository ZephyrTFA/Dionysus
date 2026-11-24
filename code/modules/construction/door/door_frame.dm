/obj/structure/door_frame
	name = "door frame"
	desc = "A frame, waiting to become a door."
	icon = 'icons/obj/doors/airlocks/station/airlock.dmi'
	icon_state = "construction"
	density = FALSE
	anchored = FALSE
	can_atmos_pass = CANPASS_ALWAYS
	max_integrity = /datum/material/steel::wall_integrity * 0.5
	/// How far the frame itself has been built. One of DOOR_CONSTRUCT_*.
	var/construction_stage = DOOR_CONSTRUCT_FRAME
	/// How far the optional fittings have been built. One of DOOR_FIT_*.
	var/fitting_stage = DOOR_FIT_NONE
	/// The AC board sat in this frame, if it has one.
	var/obj/item/electronics/board = null
	/// The material of the panelling hung on this frame, if it has any. Visual only.
	var/datum/material/panel_material = null
	/// Frames linked to this one for a multi-tile door. Empty until linking exists.
	var/list/linked_frames = list()
