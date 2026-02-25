/obj/item/organ/hair
	name = "hair"
	///Unremovable is until the features are completely finished
	organ_flags = ORGAN_UNREMOVABLE
	visual = TRUE
	cosmetic_only = TRUE

	zone = BODY_ZONE_HEAD
	slot = ORGAN_SLOT_EXTERNAL_HAIR
	layers = list(BODY_ADJ_LAYER)

	dna_block = DNA_HAIRSTYLE_BLOCK

	feature_key = "hair"
	preference = "feature_hair"

	color_source = ORGAN_COLOR_DNA

/obj/item/organ/hair/can_draw_on_bodypart(mob/living/carbon/human/human)
	if(!(human.obscured_slots & HIDEHAIR))
		return TRUE
	return FALSE

/obj/item/organ/hair/get_global_feature_list()
	return GLOB.hairstyles_list

/obj/item/organ/hair/facial
	name = "facial hair"

	zone = BODY_ZONE_HEAD
	slot = ORGAN_SLOT_EXTERNAL_FACIAL_HAIR
	layers = list(BODY_ADJ_LAYER)

	dna_block = DNA_FACIAL_HAIRSTYLE_BLOCK

	feature_key = "facial_hair"
	preference = "feature_facial_hair"

/obj/item/organ/hair/facial/get_global_feature_list()
	return GLOB.facial_hairstyles_list

/obj/item/organ/hair/facial/can_draw_on_bodypart(mob/living/carbon/human/human)
	if(!(human.obscured_slots & HIDEFACIALHAIR))
		return TRUE
	return FALSE
