/obj/item/door_panel_kit
	name = "panel kit"
	desc = "An all-in-one kit for paneling doors."
	icon_state = "skub"
	color = "green"
	/// The material for the panels.
	var/datum/material/panel_material = null
	/// How many panels are left.
	var/uses_left = 0
