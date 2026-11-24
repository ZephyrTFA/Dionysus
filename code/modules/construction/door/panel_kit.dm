/obj/item/door_panel_kit
	name = "panel kit"
	desc = "An all-in-one kit for paneling doors."
	icon_state = "skub"
	color = "green"
	/// The material for the panels.
	var/datum/material/panel_material = null
	/// How many panels are left.
	var/uses_left = 0

/obj/item/door_panel_kit/pre_attack(obj/structure/door_frame/frame, mob/living/user, params)
	if(!istype(frame))
		return ..()
	if(!user.Adjacent(frame))
		return ..()
	if(isnull(panel_material) || uses_left <= 0)
		balloon_alert(user, "empty!")
		return TRUE
	if(!isnull(frame.panel_material))
		balloon_alert(user, "already panelled!")
		return TRUE
	if(!isnull(frame.board) && frame.fitting_stage < DOOR_FIT_BOARD_SECURED)
		balloon_alert(user, "secure the board!")
		return TRUE
	frame.panel_material = panel_material
	frame.fitting_stage = DOOR_FIT_PANEL_HUNG
	frame.advance_fitting()
	uses_left--
	return TRUE

/obj/item/door_panel_kit/attackby(obj/item/item, mob/living/user, params)
	if(!istype(item, /obj/item/stack/sheet))
		return ..()
	var/obj/item/stack/sheet/sheet = item
	if(panel_material && sheet.material_type != panel_material)
		balloon_alert(user, "wrong material!")
		return TRUE
	panel_material = sheet.material_type
	if(!sheet.use(1))
		balloon_alert(user, "not enough!")
		return TRUE
	uses_left += 1
	balloon_alert(user, "restocked one")
	return TRUE

/obj/item/door_panel_kit/attackby_secondary(obj/item/weapon, mob/user, params)
	if(!istype(weapon, /obj/item/stack/sheet))
		return ..()
	var/obj/item/stack/sheet/sheet = weapon
	if(panel_material && sheet.material_type != panel_material)
		balloon_alert(user, "wrong material!")
		return TRUE
	panel_material = sheet.material_type
	var/to_take = sheet.get_amount()
	sheet.use(to_take)
	uses_left += to_take
	balloon_alert(user, "restocked all")
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
