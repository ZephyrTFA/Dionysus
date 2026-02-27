/**
 * A screen object, which acts as a container for turfs and other things
 * you want to show on the map, which you usually attach to "vis_contents".
 * Additionally manages the plane masters required to display said container contents
 */
INITIALIZE_IMMEDIATE(/atom/movable/screen/map_view)
/atom/movable/screen/map_view
	name = "screen"
	layer = GAME_PLANE
	plane = GAME_PLANE
	del_on_map_removal = FALSE
	var/list/viewers_to_planes = list()

/atom/movable/screen/map_view/Destroy()
	for(var/ckey in viewers_to_planes)
		hide_from_client(GLOB.directory[ckey])
	return ..()

/atom/movable/screen/map_view/proc/generate_view(map_key)
	// Map keys have to start and end with an A-Z character,
	// and definitely NOT with a square bracket or even a number.
	// I wasted 6 hours on this. :agony:
	// -- Stylemistake
	assigned_map = map_key
	set_position(1, 1)

/**
 * Generates and displays the map view to a client
 * Make sure you at least try to pass tgui_window if map view needed on UI,
 * so it will wait a signal from TGUI, which tells windows is fully visible.
 *
 * If you use map view not in TGUI, just call it as usualy.
 * If UI needs planes, call display_to_client.
 *
 * * show_to - Mob which needs map view
 * * window - Optional. TGUI window which needs map view
 */
/atom/movable/screen/map_view/proc/display_to(mob/show_to, datum/tgui_window/window)
	if(window && !window.visible)
		RegisterSignal(window, COMSIG_TGUI_WINDOW_VISIBLE, PROC_REF(display_on_ui_visible))
	else
		display_to_client(show_to.client)

/atom/movable/screen/map_view/proc/display_on_ui_visible(datum/tgui_window/window, client/show_to)
	SIGNAL_HANDLER
	display_to_client(show_to)
	UnregisterSignal(window, COMSIG_TGUI_WINDOW_VISIBLE)

/atom/movable/screen/map_view/proc/display_to_client(client/show_to)
	show_to.register_map_obj(src)
	if(viewers_to_planes[show_to.ckey])
		for(var/atom/movable/screen/plane_master/plane_master as anything in viewers_to_planes[show_to.ckey])
			show_to.register_map_obj(plane_master)
		return

	var/list/show_to_planes = list()
	for(var/atom/movable/screen/plane_master/plane_master as anything in subtypesof(/atom/movable/screen/plane_master) - /atom/movable/screen/plane_master/blackness)
		var/atom/movable/screen/plane_master/instance = new plane_master
		instance.assigned_map = assigned_map
		if(instance.blend_mode_override)
			instance.blend_mode = instance.blend_mode_override
		instance.screen_loc = "[assigned_map]:1,1"
		instance.del_on_map_removal = FALSE
		show_to_planes += instance
		show_to.register_map_obj(instance)
	viewers_to_planes[show_to.ckey] = show_to_planes

/atom/movable/screen/map_view/proc/hide_from(mob/hide_from)
	hide_from_client(hide_from?.canon_client)

/atom/movable/screen/map_view/proc/hide_from_client(client/hide_from)
	if(!hide_from)
		return
	hide_from.clear_map(assigned_map)
