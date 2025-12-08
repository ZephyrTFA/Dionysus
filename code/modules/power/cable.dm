///////////////////////////////
//CABLE STRUCTURE
///////////////////////////////
////////////////////////////////
// Definitions
////////////////////////////////
/obj/structure/cable
	name = "power cable"
	desc = "A flexible, superconducting insulated cable for heavy-duty power transfer."
	icon = 'icons/obj/power_cond/cable.dmi'
	icon_state = "0"
	color = "yellow"
	layer = WIRE_LAYER //Above hidden pipes, GAS_PIPE_HIDDEN_LAYER
	anchored = TRUE
	obj_flags = CAN_BE_HIT
	var/cable_connection_1 //! The primary cable connection.
	var/cable_connection_2 //! The secondary cable connection; can be NONE (cable node).
	var/datum/powernet/powernet //! The powernet the cable is connected to

/obj/structure/cable/Initialize(mapload, d1, d2)
	. = ..()
	AddElement(/datum/element/undertile, TRAIT_T_RAY_VISIBLE)
	RegisterSignal(src, COMSIG_RAT_INTERACT, PROC_REF(on_rat_eat))
	if(isturf(loc))
		var/turf/turf_loc = loc
		turf_loc.add_blueprints_preround(src)
	if(!mapload)
		if(isnull(d1) || isnull(d2))
			stack_trace("cable created without a direction!")
			return INITIALIZE_HINT_QDEL
		if(d1 > d2)
			cable_connection_1 = d2
			cable_connection_2 = d1
		else
			cable_connection_1 = d1
			cable_connection_2 = d2
	else
		var/cable_dirs = splittext(icon_state, "-")
		cable_connection_1 = text2num(cable_dirs[1])
		cable_connection_2 = text2num(cable_dirs[2])
	if(isnull(powernet_n))
		for(var/obj/structure/cable/connected_cable in get_cable_connections())
			if(!isnull(connected_cable.powernet_n))
				connected_cable.powernet_n.add_cable(src)
				break
		if(isnull(powernet_n))
			powernet_n = new
			powernet_n.add_cable(src)
	update_appearance()

/obj/structure/cable/Destroy()
	powernet_n?.remove_cable(src)
	return ..()

/obj/structure/cable/proc/amount_of_cables_worth()
	if(cable_connection_2 == NONE) // cable node
		return 1
	return 2

/obj/structure/cable/proc/on_rat_eat(datum/source, mob/living/simple_animal/hostile/regalrat/king)
	SIGNAL_HANDLER
	if(avail())
		king.apply_damage(10)
		playsound(king, 'sound/effects/sparks2.ogg', 100, TRUE)
	deconstruct()

/obj/structure/cable/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		var/obj/item/stack/cable_coil/coil = new /obj/item/stack/cable_coil(drop_location(), amount_of_cables_worth())
		coil.color = color
	qdel(src)

///////////////////////////////////
// General procedures
///////////////////////////////////

/obj/structure/cable/update_icon_state()
	..()
	icon_state = "[cable_connection_1]-[cable_connection_2]"
	layer = (cable_connection_2 == NONE) ? WIRE_KNOT_LAYER : WIRE_LAYER

/obj/structure/cable/examine(mob/user)
	. = ..()
	if(isobserver(user))
		. += get_power_info()

/obj/structure/cable/proc/handlecable(obj/item/W, mob/user, params)
	var/turf/T = get_turf(src)
	if(T.underfloor_accessibility < UNDERFLOOR_INTERACTABLE)
		return
	if(W.tool_behaviour == TOOL_WIRECUTTER)
		if (shock(user, 50))
			return
		user.visible_message(span_notice("[user] cuts the cable."), span_notice("You cut the cable."))
		investigate_log("was cut by [key_name(usr)] in [AREACOORD(src)]", INVESTIGATE_WIRES)
		deconstruct()
		return
	else if(W.tool_behaviour == TOOL_MULTITOOL)
		to_chat(user, get_power_info())
		shock(user, 5, 0.2)
	W.leave_evidence(user, src)

/obj/structure/cable/proc/get_power_info()
	if(powernet?.avail > 0)
		return span_danger("Total power: [display_power(powernet.avail)]\nLoad: [display_power(powernet.load)]\nExcess power: [display_power(surplus())]")
	else
		return span_danger("The cable is not powered.")

// Items usable on a cable :
//   - Wirecutters : cut it duh !
//   - Multitool : get the power currently passing through the cable
//
/obj/structure/cable/attackby(obj/item/W, mob/user, params)
	handlecable(W, user, params)

// shock the user with probability prb
/obj/structure/cable/proc/shock(mob/user, prb, siemens_coeff = 1)
	if(!prob(prb))
		return FALSE
	if(electrocute_mob(user, powernet, src, siemens_coeff))
		do_sparks(5, TRUE, src)
		return TRUE
	else
		return FALSE

/obj/structure/cable/singularity_pull(S, current_size)
	..()
	if(current_size >= STAGE_FIVE)
		deconstruct()

////////////////////////////////////////////
// Power related
///////////////////////////////////////////

// All power generation handled in add_avail()
// Machines should use add_load(), surplus(), avail()
// Non-machines should use add_delayedload(), delayed_surplus(), newavail()

/// Adds power to the power net next tick.
/obj/structure/cable/proc/add_avail(amount)
	if(powernet)
		powernet.newavail += amount

/// Adds load to the power net this tick.
/obj/structure/cable/proc/add_load(amount)
	if(powernet)
		powernet.load += amount

/// How much extra power is in the power net this tick
/obj/structure/cable/proc/surplus()
	if(powernet)
		return clamp(powernet.avail-powernet.load, 0, powernet.avail)
	else
		return 0

/// How much power is available this tick.
/obj/structure/cable/proc/avail(amount)
	if(powernet)
		return amount ? powernet.avail >= amount : powernet.avail
	else
		return 0

/// Add delayed load to the power net. This should be used outside of machine/process()
/obj/structure/cable/proc/add_delayedload(amount)
	if(powernet)
		powernet.delayedload += amount

/// How much surpless is in the network next tick.
/obj/structure/cable/proc/delayed_surplus()
	if(powernet)
		return clamp(powernet.newavail - powernet.delayedload, 0, powernet.newavail)
	else
		return 0

/// How much power the network will contain next tick.
/obj/structure/cable/proc/newavail()
	if(powernet)
		return powernet.newavail
	else
		return 0

//////////////////////////////////////////////
// Powernets handling helpers
//////////////////////////////////////////////

/obj/structure/cable/proc/get_all_connected_cables()
	var/list/obj/structure/cable/to_process = list(src)
	var/list/obj/structure/cable/all_connections = list()
	while(to_process.len)
		var/obj/structure/cable/current_cable = to_process[to_process.len]
		to_process.len--
		all_connections[current_cable] = TRUE
		for(var/obj/structure/cable/connected_cable in current_cable.get_cable_connections())
			if(all_connections[connected_cable])
				continue
			to_process += connected_cable
	return all_connections

/obj/structure/cable/proc/get_cable_connections(ignore_self_qdel = FALSE)
	if(!ignore_self_qdel && QDELETED(src))
		return list()
	. = list()
	for(var/cable_dir in list(cable_connection_1, cable_connection_2))
		if(cable_dir == NONE)
			continue
		var/reverse = reverse_dir[cable_dir]
		for(var/obj/structure/cable/potentional_connection in get_step(src, cable_dir))
			if(potentional_connection.cable_connection_1 == reverse || potentional_connection.cable_connection_2 == reverse)
				. += potentional_connection
		if(cable_dir & (cable_dir - 1)) // Diagonal, check for /\/\/\ style cables along cardinal directions
			for(var/pair in list(NORTH|SOUTH, EAST|WEST))
				var/req_dir = cable_dir ^ pair
				for(var/obj/structure/cable/potentional_connection in get_step(src, cable_dir & pair))
					if(potentional_connection.cable_connection_1 == req_dir || potentional_connection.cable_connection_2 == req_dir)
						. += potentional_connection
	for(var/obj/structure/cable/other_cable in loc)
		if(other_cable == src)
			continue
		if(other_cable.cable_connection_1 == cable_connection_1 || \
			other_cable.cable_connection_2 == cable_connection_1 || \
			other_cable.cable_connection_1 == cable_connection_2 || \
			other_cable.cable_connection_2 == cable_connection_2)
			. += other_cable

/obj/structure/cable/proc/get_machine_connections(powernetless_only = FALSE)
	. = list()
	if(cable_connection_2 != NONE)
		return
	for(var/obj/machinery/power/P in get_turf(src))
		if(powernetless_only && P.powernet)
			continue
		if(P.anchored)
			. += P

///////////////////////////////////////////////
// Cable variants for mapping
///////////////////////////////////////////////

/obj/structure/cable/red
	color = COLOR_RED

/obj/structure/cable/yellow
	color = COLOR_YELLOW

/obj/structure/cable/blue
	color = COLOR_STRONG_BLUE

/obj/structure/cable/green
	color = COLOR_DARK_LIME

/obj/structure/cable/pink
	color = COLOR_LIGHT_PINK

/obj/structure/cable/orange
	color = COLOR_MOSTLY_PURE_ORANGE

/obj/structure/cable/cyan
	color = COLOR_CYAN

/obj/structure/cable/white
	color = COLOR_WHITE

///////////////////////////////////////////////
// The cable coil object, used for laying cable
///////////////////////////////////////////////

////////////////////////////////
// Definitions
////////////////////////////////

#define CABLE_RESTRAINTS_COST 15

/obj/item/stack/cable_coil
	name = "cable coil"
	custom_price = PAYCHECK_ASSISTANT * 0.8
	multiple_gender = NEUTER //That's a cable coil sounds better than that's some cable coils
	icon = 'icons/obj/power.dmi'
	icon_state = "coil"
	inhand_icon_state = "coil"
	base_icon_state = "coil"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	max_amount = MAXCOIL
	amount = MAXCOIL
	merge_type = /obj/item/stack/cable_coil // This is here to let its children merge between themselves
	color = "yellow"
	desc = "A coil of insulated power cable."
	throwforce = 0
	w_class = WEIGHT_CLASS_SMALL

	throw_range = 5

	stamina_damage = 5
	stamina_cost = 5
	stamina_critical_chance = 10

	mats_per_unit = list(/datum/material/iron=10, /datum/material/glass=5)
	flags_1 = CONDUCT_1
	slot_flags = ITEM_SLOT_BELT
	attack_verb_continuous = list("whips", "lashes", "disciplines", "flogs")
	attack_verb_simple = list("whip", "lash", "discipline", "flog")
	singular_name = "cable piece"
	full_w_class = WEIGHT_CLASS_SMALL
	grind_results = list(/datum/reagent/copper = 2) //2 copper per cable in the coil
	usesound = 'sound/items/deconstruct.ogg'
	cost = 1
	source = /datum/robot_energy_storage/wire
	/// Handles the click foo.
	var/datum/cable_click_manager/click_manager

/obj/item/stack/cable_coil/Initialize(mapload, new_amount, merge = TRUE, list/mat_override=null, mat_amt=1)
	. = ..()
	pixel_x = base_pixel_x + rand(-2, 2)
	pixel_y = base_pixel_y + rand(-2, 2)
	update_appearance()

/obj/item/stack/cable_coil/Destroy(force)
	QDEL_NULL(click_manager)
	return ..()

/obj/item/stack/cable_coil/examine(mob/user)
	. = ..()
	. += "<b>Right Click</b> on the floor to enable Advanced Placement."
	. += "<b>Ctrl+Click</b> to change the layer you are placing on."

/obj/item/stack/cable_coil/update_name()
	. = ..()
	name = "cable [(amount < 3) ? "piece" : "coil"]"

/obj/item/stack/cable_coil/update_desc()
	. = ..()
	desc = "A [(amount < 3) ? "piece" : "coil"] of insulated power cable."

/obj/item/stack/cable_coil/update_icon_state()
	. = ..()
	icon_state = "[base_icon_state][amount < 3 ? amount : ""]"


/obj/item/stack/cable_coil/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_HANDS)
		if(isnull(click_manager))
			click_manager = new(src)

		click_manager.set_user(user)

/obj/item/stack/cable_coil/unequipped()
	. = ..()
	click_manager?.set_user(null)

/obj/item/stack/cable_coil/use(used, transfer, check)
	. = ..()
	update_appearance()

/obj/item/stack/cable_coil/suicide_act(mob/user)
	if(locate(/obj/structure/chair/stool) in get_turf(user))
		user.visible_message(span_suicide("[user] is making a noose with [src]! It looks like [user.p_theyre()] trying to commit suicide!"))
	else
		user.visible_message(span_suicide("[user] is strangling [user.p_them()]self with [src]! It looks like [user.p_theyre()] trying to commit suicide!"))
	return(OXYLOSS)

/obj/item/stack/cable_coil/proc/check_menu(mob/living/user)
	if(!istype(user))
		return FALSE
	if(!ISADVANCEDTOOLUSER(user))
		to_chat(user, span_warning("You don't have the dexterity to do this!"))
		return FALSE
	if(user.incapacitated() || !user.Adjacent(src))
		return FALSE
	return TRUE

/obj/item/stack/cable_coil/attack_self(mob/living/user)
	if(!user)
		return

	var/image/restraints_icon = image(icon = 'icons/obj/restraints.dmi', icon_state = "cuff")
	restraints_icon.maptext = MAPTEXT("<span [amount >= CABLE_RESTRAINTS_COST ? "" : "style='color: red'"]>[CABLE_RESTRAINTS_COST]</span>")

	var/list/radial_menu = list(
	"Multi Z layer cable hub" = image(icon = 'icons/obj/power.dmi', icon_state = "cablerelay-broken-cable"),
	"Cable restraints" = restraints_icon
	)

	var/layer_result = show_radial_menu(user, src, radial_menu, custom_check = CALLBACK(src, PROC_REF(check_menu), user), require_near = TRUE, tooltips = TRUE)
	if(!check_menu(user))
		return
	switch(layer_result)
		if("Multi Z layer cable hub")
			try_construct_multiz_hub(user)
			return
		if("Cable restraints")
			if (amount < CABLE_RESTRAINTS_COST)
				return
			if(!use(CABLE_RESTRAINTS_COST))
				return
			var/obj/item/restraints/handcuffs/cable/restraints = new
			restraints.color = color
			user.put_in_hands(restraints)
	update_appearance()

/obj/item/stack/cable_coil/proc/try_construct_multiz_hub(mob/user)
	if(!use(1))
		return
	new /obj/structure/cable/multiz(get_turf(user))
	to_chat(user, span_notice("You construct the multi Z layer cable hub."))

///////////////////////////////////
// General procedures
///////////////////////////////////
//you can use wires to heal robotics
/obj/item/stack/cable_coil/attack(mob/living/carbon/human/H, mob/user)
	if(!istype(H))
		return ..()

	var/obj/item/bodypart/affecting = H.get_bodypart(deprecise_zone(user.zone_selected))
	if(affecting && !IS_ORGANIC_LIMB(affecting))
		if(user == H)
			user.visible_message(span_notice("[user] starts to fix some of the wires in [H]'s [affecting.name]."), span_notice("You start fixing some of the wires in [H == user ? "your" : "[H]'s"] [affecting.name]."))
			if(!do_after(user, H, 50))
				return
		if(item_heal_robotic(H, user, 0, 15))
			use(1)
		return
	else
		return ..()

/obj/item/stack/cable_coil/five
	amount = 5

/obj/item/stack/cable_coil/ten
	amount = 10

/obj/item/stack/cable_coil/cut
	amount = null
	icon_state = "coil2"
	worn_icon_state = "coil"
	base_icon_state = "coil2"

/obj/item/stack/cable_coil/cut/Initialize(mapload, new_amount, merge = TRUE, list/mat_override=null, mat_amt=1)
	if(!amount)
		amount = rand(1,2)
	. = ..()
	pixel_x = base_pixel_x + rand(-2, 2)
	pixel_y = base_pixel_y + rand(-2, 2)
	update_appearance()

/obj/item/stack/cable_coil/random

/obj/item/stack/cable_coil/random/Initialize(mapload, new_amount, merge, list/mat_override, mat_amt)
	var/list/cable_colors_list = GLOB.cable_colors
	var/random_color = pick(cable_colors_list)
	color = cable_colors_list[random_color]
	. = ..()

/obj/item/stack/cable_coil/red
	color = COLOR_RED

/obj/item/stack/cable_coil/yellow
	color = COLOR_YELLOW

/obj/item/stack/cable_coil/blue
	color = COLOR_STRONG_BLUE

/obj/item/stack/cable_coil/green
	color = COLOR_DARK_LIME

/obj/item/stack/cable_coil/pink
	color = COLOR_LIGHT_PINK

/obj/item/stack/cable_coil/orange
	color = COLOR_MOSTLY_PURE_ORANGE

/obj/item/stack/cable_coil/cyan
	color = COLOR_CYAN

/obj/item/stack/cable_coil/white
	color = COLOR_WHITE

#undef CABLE_RESTRAINTS_COST
