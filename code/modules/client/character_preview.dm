/// A preview of a character for use in the preferences menu
/atom/movable/screen/map_view/char_preview
	name = "character_preview"

	/// The body that is displayed
	var/mob/living/carbon/human/dummy/body
	/// The preferences this refers to
	var/datum/preferences/preferences

	var/image/canvas

	bound_height = 128

/atom/movable/screen/map_view/char_preview/Initialize(mapload, datum/preferences/preferences)
	. = ..()
	src.preferences = preferences

/atom/movable/screen/map_view/char_preview/Destroy()
	canvas?.cut_overlays()
	canvas = null
	QDEL_NULL(body)
	preferences?.preferences_menu?.character_preview_view = null
	preferences = null
	return ..()

/// Updates the currently displayed body
/atom/movable/screen/map_view/char_preview/proc/update_body()
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
		canvas.plane = GAME_PLANE

	preferences.preferences_menu.render_new_preview_appearance(body)

	var/offset = 0
	for(var/dir in GLOB.cardinals)
		var/static/dummy = icon('icons/turf/floors.dmi', "floor")
		var/image/bg = image(dummy, dir=dir, pixel_y=offset, layer=SPACE_LAYER)
		bg.plane = GAME_PLANE

		// Look man, I have no idea why this works. The body appearance doesn't add properly otherwise.
		var/image/body_apearance = image(dummy, dir=dir, pixel_y=offset)
		body_apearance.appearance = body.appearance
		body_apearance.plane = GAME_PLANE

		bg.add_overlay(body_apearance)
		canvas.add_overlay(bg)
		offset+=32

	appearance = canvas.appearance

/atom/movable/screen/map_view/char_preview/proc/create_body()
	QDEL_NULL(body)

	body = new
