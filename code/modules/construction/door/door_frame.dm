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
