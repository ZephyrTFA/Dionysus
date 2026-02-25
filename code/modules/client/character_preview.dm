// This is necessary because you can open the set preferences menu before
// the atoms SS is done loading.
INITIALIZE_IMMEDIATE(/atom/movable/screen/character_preview_view)

/// A preview of a character for use in the preferences menu
/atom/movable/screen/character_preview_view
	name = "character_preview"
	del_on_map_removal = FALSE
	layer = GAME_PLANE
	plane = GAME_PLANE

	/// The body that is displayed
	var/mob/living/carbon/human/dummy/body

	/// The preferences this refers to
	var/datum/preferences/preferences

	var/list/plane_masters = list()

	/// The client that is watching this view
	var/client/client

	var/image/canvas

/atom/movable/screen/character_preview_view/Initialize(mapload, datum/preferences/preferences, client/client)
	. = ..()

	assigned_map = "character_preview_map"

	src.preferences = preferences

/atom/movable/screen/character_preview_view/Destroy()
	canvas?.cut_overlays()
	canvas = null // No qdel, it gets mad
	QDEL_NULL(body)

	for (var/plane_master in plane_masters)
		client?.screen -= plane_master
		qdel(plane_master)

	client?.clear_map(assigned_map)

	preferences?.preferences_menu?.character_preview_view = null

	client = null
	plane_masters = null
	preferences = null

	return ..()

/// Updates the currently displayed body
/atom/movable/screen/character_preview_view/proc/update_body()
	if (isnull(body))
		create_body()
	else
		body.wipe_state()

	if (canvas)
		canvas.cut_overlays()
	else
		var/static/icon/dummy
		if (!dummy)
			dummy = icon('icons/mob/tails.dmi', "blank_template")
			dummy.Scale(32, 128)

		canvas = image(dummy)

	preferences.render_new_preview_appearance(body)

	var/offset = 0
	for(var/dir in GLOB.cardinals)
		var/mutable_appearance/app = mutable_appearance(body, direction=dir)
		app.pixel_x = offset
		canvas.add_overlay(app)
		offset += 32

	appearance = canvas.appearance

/atom/movable/screen/character_preview_view/proc/create_body()
	QDEL_NULL(body)

	body = new

	// Without this, it doesn't show up in the menu
	body.appearance_flags &= ~KEEP_TOGETHER
