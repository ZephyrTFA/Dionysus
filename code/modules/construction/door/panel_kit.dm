/obj/item/door_panel_kit
	name = "panel kit"
	desc = "An all-in-one kit for paneling doors."
	icon_state = "skub"
	color = "green"
	/// The material the panels in this kit are made of. Null until a sheet loads it.
	var/datum/material/panel_material = null
	/// How many panels are left in the kit. One sheet restocks one panel.
	var/uses_left = 0
