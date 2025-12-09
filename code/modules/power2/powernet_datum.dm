/datum/powernet_n
	var/list/obj/structure/cable/cables //! The cables in this powernet.
	var/list/list/datum/powernet_consumer/consumers //! The consumers in this powernet. [cable: [consumer]]
	var/list/list/datum/powernet_producer/producers //! The producers in this powernet. [cable: [producer]]
	var/net_voltage = 0 //! The voltage of this powernet.
	var/net_amperage = 0 //! The amperage of this powernet.
	var/excess_amperage = 0 //! The excess amperage of this powernet. Latest technologies can monitor this because fuck you I said they can.
	var/last_resistance = 0 //! The resistance of the powernet at the last process.
	var/last_eff_voltage = 0 //! The effective voltage of the powernet at the last process.

/datum/powernet_n/New()
	SSmachines.powernets[src] = TRUE
	consumers = list()
	producers = list()
	cables = list()
	return ..()

/datum/powernet_n/Destroy()
	SSmachines.powernets -= src
	for(var/obj/structure/cable/cable in cables)
		cable.powernet_n = null
	cables.Cut()
	consumers.Cut()
	producers.Cut()
	return ..()

/datum/powernet_n/ui_data(mob/user)
	var/list/data = list()
	data["voltage"] = net_voltage
	data["amperage"] = net_amperage
	data["resistance"] = last_resistance
	data["effective_voltage"] = last_eff_voltage
	data["cable_count"] = length(cables)
	data["excess_amperage"] = excess_amperage
	return data

/obj/structure/cable
	var/resistance_factor = 0.9 //! The resistance of this cable.
	var/datum/powernet_n/powernet_n = null

/datum/powernet_n/proc/add_cable(obj/structure/cable/cable)
	if(cables[cable])
		CRASH("attempted to add a cable to a powernet that already has it")
	cables[cable] = TRUE
	cable.powernet_n = src
	for(var/obj/structure/cable/other as anything in cable.get_cable_connections())
		if(isnull(other.powernet_n))
			add_cable(other)
			continue
		if(other.powernet_n == src)
			continue
		assimilate(other.powernet_n)

/datum/powernet_n/proc/add_machine(obj/structure/cable/cable, obj/machinery/power/machine)
	if(!cables[cable])
		CRASH("attempted to add a machine to a powernet using a cable that isn't in the powernet")
	if(!isnull(machine.consumer_datum))
		ASSERT(istype(machine.consumer_datum))
		consumers[cable] |= list(machine.consumer_datum)
	if(!isnull(machine.producer_datum))
		ASSERT(istype(machine.producer_datum))
		producers[cable] |= list(machine.producer_datum)

/datum/powernet_n/proc/remove_machine(obj/structure/cable/cable, obj/machinery/power/machine)
	if(!cables[cable])
		CRASH("attempted to remove a machine from a powernet using a cable that isn't in the powernet")
	if(!isnull(machine.consumer_datum))
		ASSERT(istype(machine.consumer_datum))
		consumers[cable] -= list(machine.consumer_datum)
	if(!isnull(machine.producer_datum))
		ASSERT(istype(machine.producer_datum))
		producers[cable] -= list(machine.producer_datum)

/datum/powernet_n/proc/remove_cable(obj/structure/cable/cable)
	cables -= cable
	consumers -= cable
	producers -= cable
	cable.powernet_n = null
	// iterate over our connected cables. our first connection keeps the powernet, the rest create new ones
	var/list/obj/structure/cable/old_connections = cable.get_cable_connections(ignore_self_qdel = TRUE)
	switch(length(old_connections)) // wow that was easy
		if(0, 1)
			if(length(cables) == 0)
				qdel(src)
			return
	var/self_inherited = FALSE
	while(old_connections.len)
		var/obj/structure/cable/old_connection = old_connections[1]
		old_connections -= old_connection
		if(!self_inherited)
			self_inherited = TRUE
			old_connections -= old_connection.get_all_connected_cables()
			continue
		var/datum/powernet_n/new_powernet = new
		for(var/obj/structure/cable/connected_cable as anything in old_connection.get_all_connected_cables())
			connected_cable.powernet_n = new_powernet
			cables -= connected_cable
			if(consumers[connected_cable])
				consumers -= connected_cable
				new_powernet.consumers[connected_cable] = TRUE
			if(producers[connected_cable])
				producers -= connected_cable
				new_powernet.producers[connected_cable] = TRUE
			new_powernet.cables[connected_cable] = TRUE

/datum/powernet_n/proc/assimilate(datum/powernet_n/other)
	for(var/obj/structure/cable/cable in other.cables)
		cable.powernet_n = src
		cables[cable] = TRUE
	other.cables.Cut()
	for(var/datum/powernet_consumer/consumer in other.consumers)
		consumers[consumer] = TRUE
	other.consumers.Cut()
	for(var/datum/powernet_producer/producer in other.producers)
		producers[producer] = TRUE	
	other.producers.Cut()
	qdel(other)

/datum/powernet_n/proc/calculate_line_resistance(voltage, amperage)
	var/resistance_recip = 0
	for(var/obj/structure/cable/cable as anything in cables)
		var/cable_resistance = cable.resistance_factor * (amperage / voltage)
		var/turf/open/cable_turf = get_turf(cable)
		cable_turf.zone.air.adjustThermalEnergy(cable_resistance * CABLE_RESISTANCE_ENERGY_TO_HEAT_COEFF)
		resistance_recip += 1 / cable_resistance
	if(resistance_recip == 0)
		return 1
	return 1 / resistance_recip

/*
 * This is not a dmdoc. Do not turn it into one.
 * 
 * Notably we DO NOT CARE about delta_time.
 * This enforces that the powernet is updated in a sane manner; as I am not willing to both implement and support partial updates.
 */
/datum/powernet_n/process(delta_time)
	if(!length(cables) || !length(consumers) || !length(producers))
		return
	
	// flatten node lists
	var/list/datum/powernet_consumer/consumers_flat = list()
	for(var/obj/structure/cable/node as anything in consumers)
		for(var/datum/powernet_consumer/consumer as anything in consumers[node])
			consumers_flat[consumer] = TRUE // it is technically possible for a consumer to be in multiple cables, but zebra lists don't care
	var/list/datum/powernet_producer/producers_flat = list()
	for(var/obj/structure/cable/node as anything in producers)
		for(var/datum/powernet_producer/producer as anything in producers[node])
			producers_flat[producer] = TRUE // see above
	
	// get line state
	var/total_voltage = 0
	var/line_amperage = 0
	var/total_sources = 0
	for(var/datum/powernet_producer/producer as anything in producers_flat)
		total_voltage += producer.voltage
		line_amperage += producer.amperage
		total_sources += 1
	var/line_voltage = total_voltage / total_sources

	// handle producer voltage mismatches
	for(var/datum/powernet_producer/producer as anything in producers_flat)
		var/voltage_tolerance_range = producer.voltage * producer.voltage_tolerance
		var/voltage_drift = abs(producer.voltage - line_voltage)
		if(voltage_drift < voltage_tolerance_range)
			continue
		var/drift_pct = voltage_drift / producer.voltage
		if(line_voltage < producer.voltage)
			drift_pct *= -1
		producer.handle_voltage_mismatch(drift_pct)

	// update network state
	net_voltage = line_voltage
	net_amperage = line_amperage
	last_resistance = calculate_line_resistance(line_voltage, line_amperage)
	last_eff_voltage = line_voltage * last_resistance

	// calculate line saturation
	excess_amperage = net_amperage
	var/total_wanted_amperage = 0
	var/available_amperage_pct = 1
	for(var/datum/powernet_consumer/consumer as anything in consumers_flat)
		total_wanted_amperage += consumer.amperage
	if(total_wanted_amperage > net_amperage)
		available_amperage_pct = net_amperage / total_wanted_amperage
	// process consumers
	for(var/datum/powernet_consumer/consumer as anything in consumers_flat)
		excess_amperage -= consumer.consume_power(line_voltage, consumer.amperage * available_amperage_pct)
	// handle excess amperage on the network
	if(excess_amperage > 0)
		for(var/datum/powernet_consumer/consumer as anything in consumers_flat)
			if(excess_amperage <= 0)
				break
			excess_amperage -= consumer.handle_excess_amperage(line_voltage, excess_amperage)
