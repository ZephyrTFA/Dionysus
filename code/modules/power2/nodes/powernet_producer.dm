/datum/powernet_producer
	var/amperage = 0 //! The amperage of this producer.
	var/voltage = MEDIUM_VOLTAGE //! The voltage of this producer.
	var/voltage_tolerance = 0.05 //! The percentage the line voltage can vary by before it causes problems.

/datum/powernet_producer/proc/handle_voltage_mismatch(voltage_mismatch_percentage)
	return
