/obj/structure/door_frame
	name = "door frame"
	desc = "A frame, waiting to become a door."
	icon = 'icons/obj/doors/airlocks/station/airlock.dmi'
	icon_state = "construction"
	density = FALSE
	anchored = FALSE
	can_atmos_pass = CANPASS_ALWAYS
	max_integrity = /datum/material/steel::wall_integrity * 0.5
	smoothing_groups = SMOOTH_GROUP_WALLS
	smoothing_groups_with = SMOOTH_GROUP_GRILLE + SMOOTH_GROUP_WALLS
	var/construction_stage = DOOR_CONSTRUCT_FRAME
	var/fitting_stage = DOOR_FIT_NONE
	var/obj/item/electronics/board = null
	/// Visual only. Never enters max_integrity.
	var/datum/material/panel_material = null
	/// Empty until multi-frame doors exist.
	var/list/linked_frames = list()

/// Handles updating smoothing. No really, thats it.
/obj/structure/door_frame/proc/update_smoothing(allow_smoothing)
	var/already_smoothing = smoothing_flags != NONE
	if(already_smoothing == allow_smoothing)
		return
	// Not initial(smoothing_flags): Initialize's SETUP_SMOOTHING has already OR'd
	// SMOOTH_OBJ in because we name object groups, so the off state has to be
	// spelled out rather than inherited.
	smoothing_flags = allow_smoothing ? (SMOOTH_BITMASK | SMOOTH_OBJ) : NONE
	QUEUE_SMOOTH(src)
	QUEUE_SMOOTH_NEIGHBORS(src)

/obj/structure/door_frame/Initialize(mapload)
	. = ..()
	update_smoothing(FALSE)

/obj/structure/door_frame/proc/can_finish(mob/user, silent = FALSE)
	var/turf/my_loc = get_turf(src)
	if(!istype(my_loc, /turf/open/floor) || istype(my_loc, /turf/open/floor/plating))
		if(!silent)
			balloon_alert(user, "no floor!")
		return FALSE
	return TRUE

/// The one place that decides a frame is ready to weld, so that a board and
/// panelling being optional lives in exactly one proc.
/obj/structure/door_frame/proc/advance_fitting()
	if(construction_stage < DOOR_CONSTRUCT_WIRED)
		return
	var/ready = TRUE
	if(!isnull(board))
		ready = fitting_stage >= DOOR_FIT_BOARD_SECURED
	if(ready && !isnull(panel_material))
		ready = fitting_stage >= DOOR_FIT_PANEL_FINALIZED
	construction_stage = ready ? DOOR_CONSTRUCT_READY : DOOR_CONSTRUCT_WIRED

/// The icon file this frame's panelling should draw, falling back to steel's so
/// that the 109 materials with no door art of their own still look like a door.
/obj/structure/door_frame/proc/panel_icon()
	if(!SSmaterials.initialized)
		return
	var/datum/material/instance = GET_MATERIAL_REF(panel_material)
	var/list/icon/icons = (isnull(instance) ? null : instance.door_icons) || /datum/material/steel::door_icons
	if(!length(icons))
		stack_trace("unimplemented door_icons: [panel_material]")
		return
	return icons[MAP(atom_integrity / max_integrity, 0, 1, 1, length(icons))]

/obj/structure/door_frame/attackby(obj/item/held, mob/user, params)
	if(!Adjacent(held))
		return ..()
	if(istype(held, /obj/item/stack/cable_coil))
		return add_wiring(user, held)
	if(istype(held, /obj/item/electronics))
		return seat_board(user, held)
	return ..()

/obj/structure/door_frame/proc/add_wiring(mob/user, obj/item/stack/cable_coil/coils)
	if(construction_stage != DOOR_CONSTRUCT_SECURED)
		balloon_alert(user, construction_stage == DOOR_CONSTRUCT_FRAME ? "secure it first!" : "already wired!")
		return TRUE
	if(coils.get_amount() < DOOR_WIRING_COST)
		balloon_alert(user, "not enough!")
		return TRUE
	balloon_alert_to_viewers("wiring...")
	if(!coils.use_tool(src, user, DOOR_CONSTRUCT_STEP_TIME, volume = 50))
		return TRUE
	if(!coils.use(DOOR_WIRING_COST))
		balloon_alert(user, "not enough!")
		return TRUE
	construction_stage = DOOR_CONSTRUCT_WIRED
	advance_fitting()
	return TRUE

/obj/structure/door_frame/proc/seat_board(mob/user, obj/item/electronics/board_item)
	if(construction_stage < DOOR_CONSTRUCT_WIRED)
		balloon_alert(user, "needs wiring!")
		return TRUE
	if(!isnull(board))
		balloon_alert(user, "already boarded!")
		return TRUE
	balloon_alert_to_viewers("seating...")
	if(!board_item.use_tool(src, user, DOOR_CONSTRUCT_FIT_STEP_TIME, volume = 50))
		return TRUE
	if(QDELETED(src) || !Adjacent(board_item))
		return TRUE
	if(!user.temporarilyRemoveItemFromInventory(board_item))
		balloon_alert(user, "can't reach!")
		return TRUE
	board_item.forceMove(src)
	board = board_item
	fitting_stage = DOOR_FIT_BOARD_SEATED
	advance_fitting()
	return TRUE

/obj/structure/door_frame/screwdriver_act(mob/living/user, obj/item/tool)
	if(!Adjacent(user))
		return ..()
	switch(fitting_stage)
		if(DOOR_FIT_BOARD_SEATED)
			balloon_alert_to_viewers("securing board...")
			if(!tool.use_tool(src, user, DOOR_CONSTRUCT_FIT_STEP_TIME, volume = 50))
				return TRUE
			fitting_stage = DOOR_FIT_BOARD_SECURED
		if(DOOR_FIT_BOARD_SECURED)
			if(isnull(board))
				return ..()
			balloon_alert_to_viewers("loosening board...")
			if(!tool.use_tool(src, user, DOOR_CONSTRUCT_FIT_STEP_TIME, volume = 50))
				return TRUE
			fitting_stage = DOOR_FIT_BOARD_SEATED
		if(DOOR_FIT_PANEL_HUNG)
			balloon_alert_to_viewers("securing panels...")
			if(!tool.use_tool(src, user, DOOR_CONSTRUCT_FIT_STEP_TIME, volume = 50))
				return TRUE
			fitting_stage = DOOR_FIT_PANEL_SECURED
		if(DOOR_FIT_PANEL_SECURED)
			balloon_alert_to_viewers("loosening panels...")
			if(!tool.use_tool(src, user, DOOR_CONSTRUCT_FIT_STEP_TIME, volume = 50))
				return TRUE
			fitting_stage = DOOR_FIT_PANEL_HUNG
		else
			return ..()
	advance_fitting()
	return TRUE

/obj/structure/door_frame/screwdriver_act_secondary(mob/living/user, obj/item/tool)
	if(!Adjacent(user))
		return ..()
	if(fitting_stage != DOOR_FIT_PANEL_SECURED)
		return ..()
	balloon_alert_to_viewers("finishing panels...")
	if(!tool.use_tool(src, user, DOOR_CONSTRUCT_FIT_STEP_TIME, volume = 50))
		return TRUE
	fitting_stage = DOOR_FIT_PANEL_FINALIZED
	advance_fitting()
	return TRUE

/obj/structure/door_frame/crowbar_act(mob/living/user, obj/item/tool)
	if(!Adjacent(user))
		return ..()
	if(isnull(panel_material))
		return ..()
	balloon_alert_to_viewers("removing panels...")
	if(!tool.use_tool(src, user, DOOR_CONSTRUCT_STEP_TIME, volume = 50))
		return TRUE
	user.put_in_hands(new panel_material.sheet_type(drop_location(), DOOR_PANEL_COST))
	panel_material = null
	fitting_stage = isnull(board) ? DOOR_FIT_NONE : DOOR_FIT_BOARD_SECURED
	advance_fitting()
	return TRUE

/obj/structure/door_frame/welder_act_secondary(mob/living/user, obj/item/tool)
	if(!Adjacent(user))
		return ..()
	if(construction_stage != DOOR_CONSTRUCT_READY)
		return ..()
	if(!can_finish(user))
		return TRUE
	balloon_alert_to_viewers("welding...")
	if(!tool.use_tool(src, user, DOOR_CONSTRUCT_STEP_TIME, volume = 50))
		return TRUE
	finalize_door()
	return TRUE

/// Turns this frame into the finished door. The turf under the frame is left
/// exactly as it was: a door is an object, so it never changes the floor.
/obj/structure/door_frame/proc/finalize_door()
	var/obj/machinery/door/airlock/new_door = new(drop_location())
	new_door.apply_from_frame(src)
	qdel(src)
	return new_door

/obj/structure/door_frame/wrench_act(mob/living/user, obj/item/tool)
	if(!Adjacent(user))
		return ..()
	if(!anchored && !can_finish(user))
		return TRUE
	balloon_alert_to_viewers(anchored ? "unsecuring..." : "securing...")
	if(!tool.use_tool(src, user, DOOR_CONSTRUCT_STEP_TIME, volume = 50))
		return TRUE
	anchored = !anchored
	construction_stage = anchored ? DOOR_CONSTRUCT_SECURED : DOOR_CONSTRUCT_FRAME
	update_smoothing(anchored)
	return TRUE

/obj/structure/door_frame/examine(mob/user)
	. = ..()
	switch(construction_stage)
		if(DOOR_CONSTRUCT_FRAME)
			. += span_notice("The floor anchor bolts can be [span_bold("wrenched")] secure.")
		if(DOOR_CONSTRUCT_SECURED)
			. += span_notice("The frame can be [span_bold("wrenched")] loose, and needs <i>wiring</i>.")
		if(DOOR_CONSTRUCT_WIRED)
			if(isnull(board))
				. += span_notice("The maintenance panel is wired, and its circuit slot is <i>empty</i>.")
			else
				. += span_notice("The circuit is <i>connected loosely</i> to its slot, and the panel is [span_bold("screwed")] shut.")
		if(DOOR_CONSTRUCT_READY)
			. += span_notice("This frame can be [span_bold("welded")] into a door.")
