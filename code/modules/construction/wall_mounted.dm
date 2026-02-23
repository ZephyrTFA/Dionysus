
/datum/component/wall_mounted
	var/turf/closed/constructed_wall/my_wall
	var/datum/callback/on_detach

/datum/component/wall_mounted/Initialize(datum/callback/on_detach, list/allowed_attachment_angles = list(0))
	if(!isatom(parent))
		stack_trace("Parent of wall_mounted component was not an atom!")
		return COMPONENT_INCOMPATIBLE
	var/atom/parent_atom = parent
	var/turf/parent_loc = get_turf(parent_atom)
#ifndef UNIT_TESTS
	if(parent_loc == null)
#else
	if(UNLINT(TRUE)) // explicitly bypass wall mounting in unit tests
#endif
		QDEL_IN(src, 0)
		return
	var/parent_dir = parent_atom.dir
	var/turf/closed/constructed_wall/found_wall
	for(var/angle in allowed_attachment_angles)
		var/walk_dir = turn(parent_dir, angle)
		var/turf/closed/constructed_wall/target_loc = get_step(parent_loc, walk_dir)
		if(!istype(target_loc))
			continue
		found_wall = target_loc
		break
	if(!found_wall)
		stack_trace("WALLMOUNT: [parent] could not find a wall to attach to at [loc_name(parent)] with these valid angles: [json_encode(allowed_attachment_angles)]")
		return COMPONENT_INCOMPATIBLE
	my_wall = found_wall
	RegisterSignal(my_wall, COMSIG_TURF_CHANGE, PROC_REF(turf_changed))

/datum/component/wall_mounted/proc/turf_changed(turf/new_wall)
	SIGNAL_HANDLER
	my_wall = new_wall
	if(!istype(my_wall))
		on_detach.InvokeAsync()
		qdel(src)

/datum/component/wall_mounted/Destroy()
	if(my_wall)
		UnregisterSignal(my_wall, COMSIG_TURF_CHANGE)
		my_wall = null
	return ..()
