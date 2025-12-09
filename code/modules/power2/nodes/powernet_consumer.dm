/datum/powernet_consumer
	var/amperage = 0 //! The amperage this consumer can draw.
	var/voltage = LOW_VOLTAGE //! The voltage of this producer.
	var/voltage_tolerance = 0.05 //! The percentage the line voltage can vary by before it causes problems.

/datum/powernet_consumer/proc/handle_voltage_mismatch(voltage_mismatch_percentage)
	return

/**
 * Consume power from the network.
 *
 * @param line_voltage The voltage of the network.
 * @param amperage The amperage available for this consumer.
 * @return The amount of amperage 'consumed'.
 */
/datum/powernet_consumer/proc/consume_power(line_voltage, amperage)
	return amperage

/**
 * Handle excess amperage on the network after all consumers have 'consumed' their share.
 * 
 * @param line_voltage The voltage of the network.
 * @param excess_amperage The excess amperage available for this consumer.
 * @return The amount of amperage 'consumed'.
 */
/datum/powernet_consumer/proc/handle_excess_amperage(line_voltage, excess_amperage)
	return 0
