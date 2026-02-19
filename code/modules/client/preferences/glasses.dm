/datum/preference/choiced/glasses
	explanation = "Glasses"
	savefile_key = "glasses"
	savefile_identifier = PREFERENCE_SAVEFILE_CHARACTER
	priority = PREFERENCE_PRIORITY_QUIRKS
	feature_identifier = PREFERENCE_FEATURE_DROPDOWN_SWITCHER

/datum/preference/choiced/glasses/init_possible_values()
	return GLOB.nearsighted_glasses

/datum/preference/choiced/glasses/is_accessible(datum/preferences/preferences)
	if (!..(preferences))
		return FALSE

	return "Nearsighted" in preferences.read_preference(/datum/preference/blob/quirks)

/datum/preference/choiced/glasses/apply_to_human(mob/living/carbon/human/target, value)
	return

/datum/preference/choiced/glasses/create_default_value()
	return "Regular"
