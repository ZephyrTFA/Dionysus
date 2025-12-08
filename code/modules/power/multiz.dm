// todo: get rid of this and let wires use UP | DOWN

/obj/structure/cable/multiz //This bridges powernets betwen Z levels
	name = "multi z layer cable hub"
	desc = "A flexible, superconducting insulated multi Z layer hub for heavy-duty multi Z power transfer."
	icon = 'icons/obj/power.dmi'
	icon_state = "cable_bridge"

/obj/structure/cable/multiz/amount_of_cables_worth()
	return 1

/obj/structure/cable/multiz/update_icon_state()
	. = ..()
	icon_state = "cablerelay-on"

/obj/structure/cable/multiz/get_cable_connections(ignore_self_qdel = FALSE)
	. = ..()
	if(ignore_self_qdel && QDELETED(src))
		return .
	var/turf/T = get_turf(src)
	. += locate(/obj/structure/cable/multiz) in (GetBelow(T))
	. += locate(/obj/structure/cable/multiz) in (GetAbove(T))

/obj/structure/cable/multiz/examine(mob/user)
	. += ..()
	var/turf/T = get_turf(src)
	. += span_notice("[locate(/obj/structure/cable/multiz) in (GetBelow(T)) ? "Detected" : "Undetected"] hub UP.")
	. += span_notice("[locate(/obj/structure/cable/multiz) in (GetAbove(T)) ? "Detected" : "Undetected"] hub DOWN.")
