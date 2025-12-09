//////////////////////////////
// POWER MACHINERY BASE CLASS
//////////////////////////////

/////////////////////////////
// Definitions
/////////////////////////////

/obj/machinery/power
	name = null
	icon = 'icons/obj/power.dmi'
	anchored = TRUE
	obj_flags = CAN_BE_HIT
	use_power = NO_POWER_USE
	idle_power_usage = 0
	active_power_usage = 0
	// This is EXPLICITLY zeroed out. you MUST opt power equipment in to the data net as they underpin the concept.
	// NETWORK_FLAG_POWERNET_DATANODE will result in being added to powernet.data_nodes.
	// post_signal() will !!!directly queue signals with SSPackets by default!!!
	// Address-optimized receiving doesn't exist this far down.
	// You should know what you're doing if you're messing with stuff at this level anyways.
	network_flags = NONE
	var/obj/structure/cable/my_cable
	var/datum/powernet_consumer/consumer_datum
	var/datum/powernet_producer/producer_datum

/obj/machinery/power/Initialize(mapload)
	. = ..()
	if(!isturf(loc))
		return .
	var/turf/turf_loc = loc
	turf_loc.add_blueprints_preround(src)
	for(var/obj/structure/cable/cable in loc)
		if(cable.handle_machine_init(src))
			my_cable = cable
			break

/obj/machinery/power/Destroy()
	my_cable?.handle_machine_destroy(src)
	my_cable = null
	return ..()

/obj/machinery/power/proc/add_avail(amount)
	// TODO

/obj/machinery/power/proc/add_load(amount)
	// TODO

/obj/machinery/power/proc/surplus()
	// TODO

/obj/machinery/power/proc/avail(amount)
	// TODO

/obj/machinery/power/proc/add_delayedload(amount)
	// TODO

/obj/machinery/power/proc/delayed_surplus()
	// TODO

/obj/machinery/power/proc/newavail()
	// TODO

/obj/machinery/power/proc/disconnect_terminal() // machines without a terminal will just return, no harm no fowl.
	return

/obj/machinery/proc/powered(chan = power_channel, ignore_use_power = FALSE)
	return TRUE
	// TODO

/obj/machinery/proc/use_power(amount, chan = power_channel)
	// TODO

/obj/machinery/proc/directly_use_power(amount)
	return TRUE
	// TODO

/**
 * Attempts to draw power directly from the APC's Powernet rather than the APC's battery. For high-draw machines, like the cell charger
 *
 * Checks the surplus power on the APC's powernet, and compares to the requested amount. If the requested amount is available, this proc
 * will add the amount to the APC's usage and return that amount. Otherwise, this proc will return FALSE.
 * If the take_any var arg is set to true, this proc will use and return any surplus that is under the requested amount, assuming that
 * the surplus is above zero.
 * Args:
 * - amount, the amount of power requested from the Powernet. In standard loosely-defined SS13 power units.
 * - take_any, a bool of whether any amount of power is acceptable, instead of all or nothing. Defaults to FALSE
 */
/obj/machinery/proc/use_power_from_net(amount, take_any = FALSE)
	return amount // TODO

/obj/machinery/proc/addStaticPower(value, powerchannel)
	// TODO

/obj/machinery/proc/removeStaticPower(value, powerchannel)
	// TODO

/**
 * Called whenever the power settings of the containing area change
 *
 * by default, check equipment channel & set flag, can override if needed
 *
 * Returns TRUE if the NOPOWER flag was toggled
 */
/obj/machinery/proc/power_change()
	SIGNAL_HANDLER
	SHOULD_CALL_PARENT(TRUE)

	if(machine_stat & BROKEN)
		return
	var/initial_stat = machine_stat
	if(powered(power_channel))
		set_machine_stat(machine_stat & ~NOPOWER)
		if(initial_stat & NOPOWER)
			SEND_SIGNAL(src, COMSIG_MACHINERY_POWER_RESTORED)
			. = TRUE
	else
		set_machine_stat(machine_stat | NOPOWER)
		if(!(initial_stat & NOPOWER))
			SEND_SIGNAL(src, COMSIG_MACHINERY_POWER_LOST)
			. = TRUE
	update_appearance()

//Determines how strong could be shock, deals damage to mob, uses power.
//M is a mob who touched wire/whatever
//power_source is a source of electricity, can be power cell, area, apc, cable, powernet or null
//source is an object caused electrocuting (airlock, grille, etc)
//siemens_coeff - layman's terms, conductivity
//dist_check - set to only shock mobs within 1 of source (vendors, airlocks, etc.)
//No animations will be performed by this proc.
/proc/electrocute_mob(mob/living/carbon/victim, power_source, obj/source, siemens_coeff = 1, dist_check = FALSE, shock_flags = SHOCK_HANDS)
	if(!istype(victim) || ismecha(victim.loc))
		return FALSE //feckin mechs are dumb
	// TODO
	return 0

////////////////////////////////////////////////
// Misc.
///////////////////////////////////////////////

// return a cable able connect to machinery on layer if there's one on the turf, null if there isn't one
/turf/proc/get_cable_node()
	if(!can_have_cabling())
		return null
	for(var/obj/structure/cable/C in src)
		if(C.cable_connection_1 != NONE)
			continue
		return C
	return null
