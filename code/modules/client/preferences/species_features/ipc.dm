#define NO_SHACKLES "None"
/datum/preference/choiced/ipc_shackles
	explanation = "Shackle Laws"
	savefile_key = "ipc_shackles"
	requires_accessible = TRUE
	savefile_identifier = PREFERENCE_SAVEFILE_CHARACTER
	priority = PREFERENCE_PRIORITY_APPEARANCE_MODS //Lowest ever priority

/datum/preference/choiced/ipc_shackles/is_accessible(datum/preferences/preferences)
	. = ..()
	return ispath(preferences.read_preference(/datum/preference/choiced/species), /datum/species/ipc)

/datum/preference/choiced/ipc_shackles/init_possible_values()
	return get_shackle_laws() + NO_SHACKLES

/datum/preference/choiced/ipc_shackles/create_default_value()
	return NO_SHACKLES

/datum/preference/choiced/ipc_shackles/apply_to_human(mob/living/carbon/human/target, value)
	if(value == NO_SHACKLES)
		value = null

	var/obj/item/organ/posibrain/P = target.getorganslot(ORGAN_SLOT_POSIBRAIN)
	if(!P)
		return
	P.set_shackles(value)

/datum/preference/choiced/ipc_screen
	explanation = "Screen"
	savefile_key = "ipc_screen"
	savefile_identifier = PREFERENCE_SAVEFILE_CHARACTER
	relevant_external_organ = /obj/item/organ/ipc_screen
	feature_identifier = PREFERENCE_FEATURE_ICON_BOX

/datum/preference/choiced/ipc_screen/init_possible_values()
	return GLOB.ipc_screens_list

/datum/preference/choiced/ipc_screen/apply_to_human(mob/living/carbon/human/target, value)
	target.dna.features["ipc_screen"] = value

/datum/preference/choiced/ipc_antenna
	explanation = "Antenna"
	savefile_key = "ipc_antenna"
	savefile_identifier = PREFERENCE_SAVEFILE_CHARACTER
	relevant_external_organ = /obj/item/organ/ipc_antenna
	sub_preference = /datum/preference/color/mutant/ipc_antenna

/datum/preference/choiced/ipc_antenna/init_possible_values()
	return GLOB.ipc_antenna_list

/datum/preference/choiced/ipc_antenna/apply_to_human(mob/living/carbon/human/target, value)
	target.dna.features["ipc_antenna"] = value

/datum/preference/color/mutant/ipc_antenna
	explanation = "Antenna Color"
	savefile_key = "ipc_antenna_color"
	savefile_identifier = PREFERENCE_SAVEFILE_CHARACTER
	relevant_external_organ = /obj/item/organ/ipc_antenna
	is_sub_preference = TRUE

/datum/preference/color/mutant/ipc_antenna/create_default_value()
	return "#b4b4b4"

/datum/preference/choiced/ipc_brand
	explanation = "Chassis Brand"
	savefile_key = "ipc_brand"
	savefile_identifier = PREFERENCE_SAVEFILE_CHARACTER
	relevant_species_trait = BRANDEDPROSTHETICS
	priority = PREFERENCE_PRIORITY_BRANDED_PROSTHETICS
	requires_accessible = TRUE
	feature_identifier = PREFERENCE_FEATURE_ICON_BOX

/datum/preference/choiced/ipc_brand/create_default_value()
	return "None"

/// Global list of player-friendly name to iconstate prefix.
GLOBAL_REAL_VAR(ipc_chassis_options) = list(
	"None" = "None",
	"Aether Mk.I" = "bsh",
	"Aether Mk.II" = "bs2",
	"Dionysus" = "hsi",
	"Sentinel" = "sgm",
	"RUST-E" = "xmg",
	"RUST-G" = "xm2",
	"Wayfarer Mk.I" = "wtm",
	"Wayfarer Mk.II" = "mcg",
	"Gamma (Gen 3)" = "zhp",
)

/datum/preference/choiced/ipc_brand/init_possible_values()
	return global.ipc_chassis_options

/datum/preference/choiced/ipc_brand/apply_to_human(mob/living/carbon/human/target, value)
	var/state = global.ipc_chassis_options[value]
	state = state == "None" ? "ipc" : "[state]ipc"
	for(var/obj/item/bodypart/BP as anything in target.bodyparts)
		if(BP.is_stump || IS_ORGANIC_LIMB(BP))
			continue

		BP.change_appearance(id = state, update_owner = FALSE)

	target.dna.species.examine_limb_id = state == "ipc" ? SPECIES_IPC : state
	target.update_body_parts()

/datum/preference/choiced/saurian_screen
	explanation = "Head"
	savefile_key = "saurian_screen"
	savefile_identifier = PREFERENCE_SAVEFILE_CHARACTER
	relevant_external_organ = /obj/item/organ/saurian_screen
	feature_identifier = PREFERENCE_FEATURE_ICON_BOX

/datum/preference/choiced/saurian_screen/init_possible_values()
	return GLOB.saurian_screens_list

/datum/preference/choiced/saurian_screen/apply_to_human(mob/living/carbon/human/target, value)
	target.dna.features["saurian_screen"] = value

/datum/preference/choiced/saurian_antenna
	explanation = "Antenna"
	savefile_key = "saurian_antenna"
	savefile_identifier = PREFERENCE_SAVEFILE_CHARACTER
	relevant_external_organ = /obj/item/organ/saurian_antenna
	sub_preference = /datum/preference/tri_color/saurian_antenna_color
	feature_identifier = PREFERENCE_FEATURE_ICON_BOX

/datum/preference/choiced/saurian_antenna/init_possible_values()
	return GLOB.saurian_antenna_list

/datum/preference/choiced/saurian_antenna/apply_to_human(mob/living/carbon/human/target, value)
	target.dna.features["saurian_antenna"] = value

/datum/preference/tri_color
	abstract_type = /datum/preference/tri_color
	///dna.features["mutcolors"][color_key] = input
	var/color_key = ""
	feature_identifier = PREFERENCE_FEATURE_TRI_COLOR

/datum/preference/tri_color/deserialize(input, datum/preferences/preferences)
	var/list/input_colors = input
	return list(sanitize_hexcolor(input_colors[1]), sanitize_hexcolor(input_colors[2]), sanitize_hexcolor(input_colors[3]))

/datum/preference/tri_color/create_default_value()
	return list("#FF0000", "#00FF00", "#0000FF")

/datum/preference/tri_color/is_valid(list/value)
	return islist(value) && value.len == 3 && (findtext(value[1], GLOB.is_color) && findtext(value[2], GLOB.is_color) && findtext(value[3], GLOB.is_color))

/datum/preference/tri_color/apply_to_human(mob/living/carbon/human/target, value)
	if (isabstract(src))
		CRASH("`apply_to_human()` was called for abstract preference [type]")

	target.dna.mutant_colors["[color_key]_1"] = sanitize_hexcolor(value[1])
	target.dna.mutant_colors["[color_key]_2"] = sanitize_hexcolor(value[2])
	target.dna.mutant_colors["[color_key]_3"] = sanitize_hexcolor(value[3])

/datum/preference/tri_color/user_edit(mob/user, datum/preferences/prefs, list/params)
	var/list/colors = prefs.read_preference(type)
	var/index = text2num(params["color"])

	if(!index)
		return

	var/default = colors[index]

	var/input = input(user, "Change [explanation]",, default) as null|color
	if(!input)
		return
	colors[index] = input
	return prefs.update_preference(src, colors)

/datum/preference/tri_color/get_button(datum/preferences/prefs)
	var/list/colors = prefs.read_preference(type)
	. = ""
	. += color_button_element(prefs, colors[1], "pref_act=[type];color=1")
	. += color_button_element(prefs, colors[2], "pref_act=[type];color=2")
	. += color_button_element(prefs, colors[3], "pref_act=[type];color=3")

/datum/preference/tri_color/saurian_antenna_color
	explanation = "Antenna Color"
	savefile_key = "saurian_antenna_color"
	savefile_identifier = PREFERENCE_SAVEFILE_CHARACTER
	relevant_external_organ = /obj/item/organ/saurian_antenna
	is_sub_preference = TRUE

	color_key = MUTCOLORS_KEY_SAURIAN_ANTENNA
	feature_identifier = PREFERENCE_FEATURE_ICON_BOX

#undef NO_SHACKLES
