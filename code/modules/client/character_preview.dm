/// A preview of a character for use in the preferences menu
/atom/movable/screen/map_view/byondui/char_preview
	name = "character_preview"

	/// The body that is displayed
	var/mob/living/carbon/human/dummy/body
	/// The preferences this refers to
	var/datum/preferences/preferences

	var/image/canvas

	var/list/subscreens = list()

	bound_height = 128

/atom/movable/screen/map_view/byondui/char_preview/Initialize(mapload, datum/preferences/preferences)
	. = ..()
	src.preferences = preferences

/atom/movable/screen/map_view/byondui/char_preview/Destroy()
	canvas?.cut_overlays()
	canvas = null
	QDEL_NULL(body)
	preferences?.preferences_menu?.character_preview_view = null
	preferences = null
	return ..()

/// Updates the currently displayed body
/atom/movable/screen/map_view/byondui/char_preview/proc/update_body()
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

	preferences.preferences_menu.render_new_preview_appearance(body)

	var/offset = -96
	for(var/dir in GLOB.cardinals)
		var/static/dummy = icon('icons/turf/floors.dmi', "floor")
		var/image/app = image(dummy, dir=dir, pixel_y=offset)
		// app.vis_contents += body
		canvas.add_overlay(app)
		offset+=1

	appearance = canvas.appearance

/atom/movable/screen/map_view/byondui/char_preview/proc/create_body()
	QDEL_NULL(body)

	body = new
