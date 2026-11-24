/datum/unit_test/door_frame_placement
	name = "DOOR: Frame placement and securing"

/datum/unit_test/door_frame_placement/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/wrench/wrench = allocate(/obj/item/wrench)
	user.put_in_active_hand(wrench, forced = TRUE)

	var/obj/structure/door_frame/frame = allocate(/obj/structure/door_frame)
	TEST_ASSERT(istype(frame), "A door frame could not be placed on the floor")
	TEST_ASSERT_EQUAL(frame.construction_stage, DOOR_CONSTRUCT_FRAME, "A fresh frame is not at the frame stage")
	TEST_ASSERT(!frame.anchored, "A fresh frame starts anchored")
	TEST_ASSERT(!(frame.smoothing_flags & (SMOOTH_BITMASK | SMOOTH_OBJ)), "A bare frame joins the wall line before it is secured")

	frame.wrench_act(user, wrench)

	TEST_ASSERT(frame.anchored, "Wrenching a frame on a floor did not anchor it")
	TEST_ASSERT_EQUAL(frame.construction_stage, DOOR_CONSTRUCT_SECURED, "Wrenching a frame did not secure it")
	TEST_ASSERT((frame.smoothing_flags & (SMOOTH_BITMASK | SMOOTH_OBJ)) == (SMOOTH_BITMASK | SMOOTH_OBJ), "A secured frame did not join the wall line")

	frame.wrench_act(user, wrench)

	TEST_ASSERT(!frame.anchored, "Wrenching a secured frame did not loose it")
	TEST_ASSERT_EQUAL(frame.construction_stage, DOOR_CONSTRUCT_FRAME, "Wrenching a secured frame did not undo its stage")
	TEST_ASSERT(!(frame.smoothing_flags & (SMOOTH_BITMASK | SMOOTH_OBJ)), "An unsecured frame is still smoothing")

	// Review Focus 1: a frame whose floor is gone refuses to be secured, and the
	// refusal must not touch the stage or the anchor.
	var/turf/test_turf = get_turf(frame)
	test_turf.ChangeTurf(/turf/open/floor/plating)

	var/obj/structure/door_frame/plating_frame = allocate(/obj/structure/door_frame, test_turf)
	plating_frame.wrench_act(user, wrench)

	TEST_ASSERT(!plating_frame.anchored, "A frame on plating was secured")
	TEST_ASSERT_EQUAL(plating_frame.construction_stage, DOOR_CONSTRUCT_FRAME, "A frame on plating advanced its stage")
