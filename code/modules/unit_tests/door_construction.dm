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
	var/initial_turf_type = test_turf.type
	test_turf.ChangeTurf(/turf/open/floor/plating)

	var/obj/structure/door_frame/plating_frame = allocate(/obj/structure/door_frame, test_turf)
	plating_frame.wrench_act(user, wrench)

	TEST_ASSERT(!plating_frame.anchored, "A frame on plating was secured")
	TEST_ASSERT_EQUAL(plating_frame.construction_stage, DOOR_CONSTRUCT_FRAME, "A frame on plating advanced its stage")

	// The test zone's turfs outlive a test, so leave this one as we found it.
	test_turf.ChangeTurf(initial_turf_type)

/datum/unit_test/door_frame_fittings
	name = "DOOR: Wiring and board"

/datum/unit_test/door_frame_fittings/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/wrench/wrench = allocate(/obj/item/wrench)
	user.put_in_active_hand(wrench, forced = TRUE)

	var/obj/structure/door_frame/frame = allocate(/obj/structure/door_frame)
	var/obj/item/stack/cable_coil/coils = allocate(/obj/item/stack/cable_coil, null, DOOR_WIRING_COST * 2)

	frame.attackby(coils, user)
	TEST_ASSERT_EQUAL(frame.construction_stage, DOOR_CONSTRUCT_FRAME, "Coils wired an unsecured frame")
	TEST_ASSERT_EQUAL(coils.get_amount(), DOOR_WIRING_COST * 2, "Refused coils were spent anyway")

	frame.wrench_act(user, wrench)
	TEST_ASSERT_EQUAL(frame.construction_stage, DOOR_CONSTRUCT_SECURED, "The frame did not secure")

	var/obj/item/electronics/board = allocate(/obj/item/electronics)
	frame.attackby(board, user)
	TEST_ASSERT_EQUAL(frame.fitting_stage, DOOR_FIT_NONE, "A board was seated before the frame was wired")
	TEST_ASSERT(isnull(frame.board), "A board was installed before the frame was wired")
	TEST_ASSERT(!QDELETED(board), "A refused board was consumed")

	frame.attackby(coils, user)
	TEST_ASSERT_EQUAL(frame.construction_stage, DOOR_CONSTRUCT_READY, "A wired frame with no fittings is not weldable")
	TEST_ASSERT_EQUAL(coils.get_amount(), DOOR_WIRING_COST, "Wiring did not spend exactly 5 coils")

	frame.attackby(board, user)
	TEST_ASSERT(!isnull(frame.board), "The board was not seated")
	TEST_ASSERT_EQUAL(frame.fitting_stage, DOOR_FIT_BOARD_SEATED, "The board was not seated at the seated stage")
	TEST_ASSERT_EQUAL(frame.construction_stage, DOOR_CONSTRUCT_WIRED, "A loose board did not make the frame wait for the screwdriver")

	var/obj/item/electronics/second_board = allocate(/obj/item/electronics)
	frame.attackby(second_board, user)
	TEST_ASSERT_EQUAL(frame.fitting_stage, DOOR_FIT_BOARD_SEATED, "A second board overwrote the first")
	TEST_ASSERT(!QDELETED(second_board), "A refused second board was consumed")

	var/obj/item/screwdriver/screwdriver = allocate(/obj/item/screwdriver)
	user.put_in_active_hand(screwdriver, forced = TRUE)
	frame.screwdriver_act(user, screwdriver)

	TEST_ASSERT_EQUAL(frame.fitting_stage, DOOR_FIT_BOARD_SECURED, "The board was not secured")
	TEST_ASSERT_EQUAL(frame.construction_stage, DOOR_CONSTRUCT_READY, "A secured board with nothing else installed did not make the frame ready")
