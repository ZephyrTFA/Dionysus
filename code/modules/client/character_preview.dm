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
	/// The appearance to display
	var/mutable_appearance/rendered_appearance

	/// The preferences this refers to
	var/datum/preferences/preferences

	var/list/plane_masters = list()

	/// The client that is watching this view
	var/client/client

	var/list/atom/movable/screen/subscreens = list()

/atom/movable/screen/character_preview_view/Initialize(mapload, datum/preferences/preferences, client/client)
	. = ..()

	assigned_map = "character_preview_map"

	src.preferences = preferences

/atom/movable/screen/character_preview_view/Destroy()
	QDEL_NULL(body)
	QDEL_LIST_ASSOC_VAL(subscreens)

	for (var/plane_master in plane_masters)
		client?.screen -= plane_master
		qdel(plane_master)

	client?.clear_map(assigned_map)

	preferences?.character_preview_view = null

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

	rendered_appearance = preferences.render_new_preview_appearance(body)

	for(var/index in subscreens)
		var/atom/movable/screen/subscreen = subscreens[index]
		var/cache_dir = subscreen.dir
		subscreen.appearance = rendered_appearance.appearance
		subscreen.dir = cache_dir

/atom/movable/screen/character_preview_view/proc/create_body()
	QDEL_NULL(body)

	body = new

	// Without this, it doesn't show up in the menu
	body.appearance_flags &= ~KEEP_TOGETHER

/// Registers the relevant map objects to a client
/atom/movable/screen/character_preview_view/proc/register_to_client(client/client)
	QDEL_LIST(plane_masters)

	src.client = client

	if (!client)
		return

	for (var/plane_master_type in subtypesof(/atom/movable/screen/plane_master) - /atom/movable/screen/plane_master/blackness)
		var/atom/movable/screen/plane_master/plane_master = new plane_master_type()
		plane_master.screen_loc = "[assigned_map]:0,CENTER"
		client?.screen |= plane_master

		plane_masters += plane_master

	var/pos
	for(var/dir in GLOB.cardinals)
		pos++
		var/atom/movable/screen/subscreen/preview = subscreens["preview-[dir]"]
		if(!preview)
			preview = new
			subscreens["preview-[dir]"] = preview
			client?.register_map_obj(preview)

		preview.appearance = rendered_appearance.appearance
		preview.dir = dir
		preview.set_position(0, pos)


	client?.register_map_obj(src)

INITIALIZE_IMMEDIATE(/atom/movable/screen/subscreen)
/atom/movable/screen/subscreen
	name = "preview_subscreen"
	assigned_map = "character_preview_map"
