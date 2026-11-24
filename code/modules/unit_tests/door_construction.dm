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

/datum/unit_test/door_panelling
	name = "DOOR: Panelling is visual only"

/datum/unit_test/door_panelling/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/wrench/wrench = allocate(/obj/item/wrench)
	var/obj/item/screwdriver/screwdriver = allocate(/obj/item/screwdriver)
	var/obj/item/crowbar/crowbar = allocate(/obj/item/crowbar)
	user.put_in_active_hand(wrench, forced = TRUE)

	var/obj/item/door_panel_kit/kit = allocate(/obj/item/door_panel_kit)
	kit.attackby(allocate(/obj/item/stack/sheet/bronze), user)
	TEST_ASSERT_EQUAL(kit.uses_left, 1, "A bronze sheet did not restock the kit")
	TEST_ASSERT_EQUAL(kit.panel_material, /datum/material/bronze, "The kit did not take the bronze material")
	kit.attackby(allocate(/obj/item/stack/sheet/glass), user)
	TEST_ASSERT_EQUAL(kit.uses_left, 1, "A sheet of the wrong material restocked the kit")

	var/obj/structure/door_frame/frame = allocate(/obj/structure/door_frame)
	var/plain_integrity = frame.max_integrity

	frame.wrench_act(user, wrench)
	frame.attackby(allocate(/obj/item/stack/cable_coil, null, DOOR_WIRING_COST), user)
	frame.attackby(allocate(/obj/item/electronics), user)
	TEST_ASSERT_EQUAL(frame.fitting_stage, DOOR_FIT_BOARD_SEATED, "The board was not seated")

	kit.pre_attack(frame, user)
	TEST_ASSERT(isnull(frame.panel_material), "Panels were hung over a loose board")
	TEST_ASSERT_EQUAL(kit.uses_left, 1, "A refused panel still spent a use")

	user.put_in_active_hand(screwdriver, forced = TRUE)
	frame.screwdriver_act(user, screwdriver)
	TEST_ASSERT_EQUAL(frame.fitting_stage, DOOR_FIT_BOARD_SECURED, "The board was not secured")

	kit.pre_attack(frame, user)
	TEST_ASSERT(!isnull(frame.panel_material), "The kit did not panel the frame")
	TEST_ASSERT_EQUAL(frame.fitting_stage, DOOR_FIT_PANEL_HUNG, "Panelling did not hang at the hung stage")
	TEST_ASSERT_EQUAL(kit.uses_left, 0, "Hanging a panel did not spend a use")
	TEST_ASSERT_EQUAL(frame.max_integrity, plain_integrity, "Bronze panelling changed the frame's integrity")

	kit.pre_attack(frame, user)
	TEST_ASSERT_EQUAL(kit.uses_left, 0, "A second panel on a panelled frame spent a use")

	frame.screwdriver_act(user, screwdriver)
	TEST_ASSERT_EQUAL(frame.fitting_stage, DOOR_FIT_PANEL_SECURED, "The panels were not secured")
	frame.screwdriver_act_secondary(user, screwdriver)
	TEST_ASSERT_EQUAL(frame.fitting_stage, DOOR_FIT_PANEL_FINALIZED, "The panels were not finalized")
	TEST_ASSERT_EQUAL(frame.construction_stage, DOOR_CONSTRUCT_READY, "Finalised panels did not make the frame weldable")

	user.put_in_active_hand(crowbar, forced = TRUE)
	frame.crowbar_act(user, crowbar)
	TEST_ASSERT(isnull(frame.panel_material), "The crowbar did not strip the panels")
	TEST_ASSERT_EQUAL(frame.fitting_stage, DOOR_FIT_BOARD_SECURED, "Stripping the panels did not rewind to the secured board")

	// Review Focus 2: a material with no door art of its own draws steel's.
	var/obj/structure/door_frame/steel_frame = allocate(/obj/structure/door_frame)
	steel_frame.panel_material = /datum/material/steel
	var/obj/structure/door_frame/fallback_frame = allocate(/obj/structure/door_frame)
	fallback_frame.panel_material = /datum/material/bronze
	TEST_ASSERT_NOTNULL(fallback_frame.panel_icon(), "A material with no door_icons has no fallback")
	TEST_ASSERT_EQUAL(fallback_frame.panel_icon(), steel_frame.panel_icon(), "The fallback is not steel's art")

/datum/unit_test/door_finalization
	name = "DOOR: Welding finalizes without touching the turf"

/datum/unit_test/door_finalization/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/wrench/wrench = allocate(/obj/item/wrench)
	var/obj/item/weldingtool/welder = allocate(/obj/item/weldingtool)
	welder.set_welding(TRUE)
	user.put_in_active_hand(welder, forced = TRUE)
	var/obj/item/screwdriver/screwdriver = allocate(/obj/item/screwdriver)

	var/obj/structure/door_frame/frame = allocate(/obj/structure/door_frame)
	var/turf/test_turf = get_turf(frame)
	var/initial_turf_type = test_turf.type

	frame.wrench_act(user, wrench)
	frame.welder_act_secondary(user, welder)
	TEST_ASSERT(isnull(locate(/obj/machinery/door/airlock) in test_turf), "Welding an unwired frame made a door")
	TEST_ASSERT(!QDELETED(frame), "Welding an unwired frame took the frame apart")

	frame.attackby(allocate(/obj/item/stack/cable_coil, null, DOOR_WIRING_COST), user)
	TEST_ASSERT_EQUAL(frame.construction_stage, DOOR_CONSTRUCT_READY, "A wired frame is not weldable")

	// Review Focus 4: an unlit welder interrupts, and nothing is spent or spawned.
	var/obj/item/weldingtool/unlit = allocate(/obj/item/weldingtool)
	frame.welder_act_secondary(user, unlit)
	TEST_ASSERT(isnull(locate(/obj/machinery/door/airlock) in test_turf), "An unlit welder finalized the frame")
	TEST_ASSERT_EQUAL(frame.construction_stage, DOOR_CONSTRUCT_READY, "An unlit welder changed the stage")

	var/obj/item/electronics/board = allocate(/obj/item/electronics)
	frame.attackby(board, user)
	user.put_in_active_hand(screwdriver, forced = TRUE)
	frame.screwdriver_act(user, screwdriver)
	user.put_in_active_hand(welder, forced = TRUE)
	frame.panel_material = /datum/material/bronze
	TEST_ASSERT_EQUAL(frame.construction_stage, DOOR_CONSTRUCT_READY, "A wired and boarded frame is not weldable")

	frame.welder_act_secondary(user, welder)

	var/obj/machinery/door/airlock/door = locate(/obj/machinery/door/airlock) in test_turf
	TEST_ASSERT_NOTNULL(door, "A ready frame with a lit welder did not become a door")
	var/door_count = 0
	for(var/obj/machinery/door/airlock/welded in test_turf)
		door_count++
	TEST_ASSERT_EQUAL(door_count, 1, "Welding did not produce exactly one door")
	TEST_ASSERT(QDELETED(frame), "The frame survived being welded into a door")
	TEST_ASSERT_EQUAL(get_turf(door), test_turf, "The door is not on the frame's turf")
	TEST_ASSERT_EQUAL(test_turf.type, initial_turf_type, "Welding a door changed the turf")
	TEST_ASSERT(door.density, "The door is not dense")
	TEST_ASSERT(door.opacity, "The door is not opaque")
	TEST_ASSERT_EQUAL(door.layer, CLOSED_DOOR_LAYER, "The door is not on the closed door layer")
	TEST_ASSERT_EQUAL(door.panel_material, /datum/material/bronze, "The door did not carry the frame's panelling")
	TEST_ASSERT_EQUAL(door.board, board, "The door did not carry the frame's board")

	// Review Focus 1: a frame whose floor has gone cannot be welded into a door.
	qdel(door)
	var/obj/structure/door_frame/plating_frame = allocate(/obj/structure/door_frame, test_turf)
	plating_frame.construction_stage = DOOR_CONSTRUCT_READY
	test_turf.ChangeTurf(/turf/open/floor/plating)
	plating_frame.welder_act_secondary(user, welder)
	TEST_ASSERT(isnull(locate(/obj/machinery/door/airlock) in test_turf), "A frame on plating was welded into a door")
	test_turf.ChangeTurf(initial_turf_type)

/datum/unit_test/door_deconstruction
	name = "DOOR: The chain reverses"

/datum/unit_test/door_deconstruction/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/wrench/wrench = allocate(/obj/item/wrench)
	var/obj/item/screwdriver/screwdriver = allocate(/obj/item/screwdriver)
	var/obj/item/crowbar/crowbar = allocate(/obj/item/crowbar)
	var/obj/item/wirecutters/wirecutters = allocate(/obj/item/wirecutters)
	var/obj/item/weldingtool/welder = allocate(/obj/item/weldingtool)
	welder.set_welding(TRUE)

	var/obj/structure/door_frame/frame = allocate(/obj/structure/door_frame)
	var/turf/test_turf = get_turf(frame)
	var/initial_turf_type = test_turf.type

	frame.wrench_act(user, wrench)
	frame.attackby(allocate(/obj/item/stack/cable_coil, null, DOOR_WIRING_COST), user)
	var/obj/item/electronics/board = allocate(/obj/item/electronics)
	frame.attackby(board, user)
	frame.screwdriver_act(user, screwdriver)
	frame.panel_material = /datum/material/bronze
	frame.fitting_stage = DOOR_FIT_PANEL_HUNG
	frame.screwdriver_act(user, screwdriver)
	frame.screwdriver_act_secondary(user, screwdriver)
	TEST_ASSERT_EQUAL(frame.construction_stage, DOOR_CONSTRUCT_READY, "A fully fitted frame is not weldable")

	frame.welder_act_secondary(user, welder)
	var/obj/machinery/door/airlock/door = locate(/obj/machinery/door/airlock) in test_turf
	TEST_ASSERT_NOTNULL(door, "The full chain did not produce a door")

	door.crowbar_act(user, crowbar)
	var/obj/structure/door_frame/back = locate(/obj/structure/door_frame) in test_turf
	TEST_ASSERT_NOTNULL(back, "Crowbarring a door did not yield a frame")
	TEST_ASSERT(QDELETED(door), "The door survived being crowbarred")
	TEST_ASSERT_EQUAL(back.panel_material, /datum/material/bronze, "The frame lost the door's panelling")
	TEST_ASSERT_EQUAL(back.board, board, "The frame lost the door's board")
	TEST_ASSERT_EQUAL(test_turf.type, initial_turf_type, "Crowbarring a door changed the turf")

	back.crowbar_act(user, crowbar)
	TEST_ASSERT(isnull(back.panel_material), "The crowbar did not strip the panels")
	TEST_ASSERT(!isnull(locate(/obj/item/stack/sheet/bronze) in user) || !isnull(locate(/obj/item/stack/sheet/bronze) in test_turf), "Stripping the panels returned no sheet")

	back.screwdriver_act(user, screwdriver)
	TEST_ASSERT_EQUAL(back.fitting_stage, DOOR_FIT_BOARD_SEATED, "The board was not loosened")
	back.crowbar_act(user, crowbar)
	TEST_ASSERT(isnull(back.board), "The crowbar did not take the board out")
	TEST_ASSERT(!isnull(locate(/obj/item/electronics) in user) || !isnull(locate(/obj/item/electronics) in test_turf), "The board did not come back")

	back.wirecutter_act(user, wirecutters)
	TEST_ASSERT_EQUAL(back.construction_stage, DOOR_CONSTRUCT_SECURED, "The wiring was not cut out")
	TEST_ASSERT(!isnull(locate(/obj/item/stack/cable_coil) in user) || !isnull(locate(/obj/item/stack/cable_coil) in test_turf), "Cutting the wiring returned no coils")

	back.wrench_act(user, wrench)
	TEST_ASSERT(!back.anchored, "The frame was not unsecured")
	TEST_ASSERT_EQUAL(back.construction_stage, DOOR_CONSTRUCT_FRAME, "Unsecuring did not rewind the stage")

	back.welder_act_secondary(user, welder)
	TEST_ASSERT(QDELETED(back), "The frame survived being dismantled")
	TEST_ASSERT(!isnull(locate(/obj/item/stack/sheet/steel) in user) || !isnull(locate(/obj/item/stack/sheet/steel) in test_turf), "Dismantling the frame returned no steel")
	TEST_ASSERT_EQUAL(test_turf.type, initial_turf_type, "Deconstructing a door changed the turf")

	var/obj/machinery/door/airlock/panelled/bronze/bronze_door = allocate(/obj/machinery/door/airlock/panelled/bronze)
	var/obj/machinery/door/airlock/panelled/steel/steel_door = allocate(/obj/machinery/door/airlock/panelled/steel)
	TEST_ASSERT_EQUAL(bronze_door.panel_material, /datum/material/bronze, "A mapped bronze door has the wrong panelling")
	TEST_ASSERT_EQUAL(bronze_door.max_integrity, steel_door.max_integrity, "Bronze panelling changed a mapped door's integrity")
