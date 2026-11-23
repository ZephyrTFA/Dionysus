# Door Construction Boilerplate — Design

Date: 2026-11-23
Status: approved in chat, awaiting written review
Scope: the construction skeleton for normal airlocks. No door behaviour.

## Context

Commit `a998f7e3ebf` ("Door Smokes", #64) deleted the entire door stack —
`airlock.dm`, `door.dm`, `door_assembly.dm`, `windoor_assembly.dm`,
`airlock_electronics.dm`, the wiremod shell and every door variant — with the
note that doors would be redone from scratch. Nothing named `door` survives in
the maps, `/obj/machinery/door` no longer exists, and the only leftovers are a
0-byte `code/modules/construction/door/door_frame.dm`, an empty
`icons/construction/doors/`, and `cutter_templates/door/door_32x32.toml` for the
spriter pipeline.

The wall system is the reference implementation, and the one we are told to
follow:

- `/obj/structure/girder` (`code/modules/construction/girder.dm`) — built from a
  steel stack recipe, then wrench-anchored, plated, reinforced, secured and
  finished, ending in `ChangeTurf(/turf/closed/constructed_wall)`.
- `/turf/closed/constructed_wall` (`code/modules/construction/wall/wall_actual.dm`)
  — material-driven icons, integrity, name and heat resistance; staged
  deconstruction via `deconstruction_stage` plus the optional
  `deconstruction_r_step` branch; `examine()` naming the next tool.
- `code/__DEFINES/construction_walls.dm` — stage and step-time defines.
- `code/modules/construction/wall/trim_kit.dm` — `/obj/item/wall_trim_kit`,
  restocked by being hit with sheets, consumed one use at a time.

The design brief for doors, from the operator's sketch:

> Construction goes: Door frame / Link frames for multi-frame / Secure frame(s) /
> Add wiring to frame(s) / Add AC board (if required) / Add panelling? / Secure
> panelling by tool / Finalize panelling by tool / Weld to finalize door(?)
>
> Building a door should be abt as many steps as building a wall and should
> follow a similar, intuitive order for consistency.

## Decisions

| Question | Decision |
|---|---|
| What is a finished airlock? | An object on a floor turf: `/obj/machinery/door/airlock`. Not a turf. |
| Machinery or structure? | `/obj/machinery/door/airlock` — it will use power. |
| Materials | Steel only structurally. Visual variety comes from finishing kits. |
| Reinforced doors | Later. Normal doors only in this slice. |
| Variants | Basic airlock only. Standard / Centcom / Firedoor / Bulkhead / Hazmat later. |
| Multi-frame linking | Out. Single tile only. `linked_frames` list reserved on the frame. |
| Panelling model | Material-backed, as `wall_trim_kit` is. `/datum/material` gains `door_icons`. |
| Chain representation | Two stored stage ints, mirroring the wall's `deconstruction_stage` + `deconstruction_r_step`. |
| Deliverable | A skeleton that compiles and can be built up and stripped back down. The door does not open. |

## Section 1 — Types and files

```
code/__DEFINES/construction_doors.dm           stage and step-time defines
code/modules/construction/door/door_frame.dm   /obj/structure/door_frame      (girder analogue)
code/modules/construction/door/airlock.dm      /obj/machinery/door            (base, no behaviour)
                                               /obj/machinery/door/airlock    (normal door)
code/modules/construction/door/panel_kit.dm    /obj/item/door_panel_kit       (trim kit analogue)
code/modules/construction/door/mappables.dm    prebuilt doors for mappers
```

Five `#include` lines in `dionysus.dme`, kept alphabetically beside the existing
`code\modules\construction\wall\*` includes. Two stack recipes in
`code/game/objects/items/stacks/sheets/sheet_types.dm`, beside `"wall girders"`
and `"wall trim kit"`:

- `"door frame"` — 2 steel, `one_per_turf = TRUE`, `on_floor = TRUE`
- `"door panel kit"` — 2 steel

## Section 2 — The chain

Against the wall's, step for step, because parity of feel is the stated goal:

| # | step | tool | wall's equivalent |
|---|---|---|---|
| 1 | place frame (2 steel) | stack recipe | "wall girders" |
| 2 | secure frame | `wrench_act` | wrench anchors girder |
| 3 | add wiring (5 coils) | `attackby` cable coil | sheet adds plating |
| 4 | add AC board | `attackby` `/obj/item/electronics` | sheet adds reinforcement |
| 5 | secure board | `screwdriver_act` | screwdriver secures rods |
| 6 | hang panelling (1 use) | `/obj/item/door_panel_kit` | trim kit on wall |
| 7 | secure panelling | `screwdriver_act`, next stage | — |
| 8 | finalize panelling | `screwdriver_act_secondary` | screwdriver-secondary finishes |
| 9 | weld to finalize door | `welder_act_secondary` | screwdriver-secondary finishes |

Minimum chain with no board and no panelling is 4 steps, the same as the wall's
minimum. The full chain is 9 against the wall's 6, and the two extra steps are
precisely the sketch's two optional ones.

Every stage has an `examine()` line naming the next tool, as both the girder and
the wall do. Every step is `tool.use_tool(src, user, DOOR_CONSTRUCT_STEP_TIME,
volume = 50)` behind a `balloon_alert_to_viewers("...")`, and every step checks
`Adjacent()` first.

## Section 3 — Panelling

`/datum/material` gains `var/list/icon/door_icons` beside `wall_icons`, same
destroyed-to-max ordering. Steel gets one pointing at existing station art.

A material with no `door_icons` falls back to steel's rather than `stack_trace`
ing, because 109 of 112 materials have no door art and will not for a while. The
trace is reserved for the case where steel's own entry is missing, which is a
genuine bug.

`panel_material` is **visual only**. It never enters
`update_material_resistances()`. That is what keeps "steel only" true: bronze
panelling changes what a door looks like and nothing else. Crowbar on a frame
removes the panel and returns a sheet, as `crowbar_act` does for wall trims.

`/obj/item/door_panel_kit` mirrors `/obj/item/wall_trim_kit`: a `panel_material`
var, `uses_left`, restocked one sheet at a time by `attackby` (or all sheets at
once on `attackby_secondary`), refusing a sheet whose material differs from the
one already loaded.

## Section 4 — Deconstruction, and the turf rule

**Finalizing never touches the turf.** `welder_act_secondary` spawns the airlock
at the frame's loc and `qdel`s the frame. No `ChangeTurf`, no `ScrapeAway`: the
floor tile under a door stays whatever it was.

**The floor requirement is a check, not a mutation.** Placement is already
gated by the stack recipe's `on_floor = TRUE`. Mirroring the girder's
`if(!istype(my_loc, /turf/open/floor))` → `"how?"` guard, the frame re-checks on
secure and on weld, so a door cannot be finished on plating or in space after the
floor tile under it is pried up.

Two different crowbar uses, on two different objects: on a **frame** it strips
panelling and returns a sheet; on a finished **door** it pops the whole door back
into a frame. Applying a kit to an already-finished door — re-paneling in play —
is out of scope for this slice, so the kit only ever targets a frame here.

Reverse chain on the frame:

1. crowbar strips panelling, returns 1 sheet
2. screwdriver unsecures then unseats the board, returns the `/obj/item/electronics`
3. wirecutters pull the coils, returns 5 coils
4. wrench unsecures the frame
5. `welder_act_secondary` dismantles the frame for 2 steel, the same return the
   girder's `welder_act_secondary` gives

Door back to frame: crowbar on the finished airlock pops it into a
`/obj/structure/door_frame` carrying its board and panel state —
`deconstruct_to_girder()`'s idea, minus the `ScrapeAway()`.

`atom_destruction` drops to a frame with parts scattered, mirroring the wall's
small-hit-to-girder / big-hit-to-nothing split.

## Section 5 — Defines

```
DOOR_CONSTRUCT_FRAME 0   just placed
DOOR_CONSTRUCT_SECURED 1 wrench-anchored
DOOR_CONSTRUCT_WIRED 2   coils run, fittings may begin
DOOR_CONSTRUCT_READY 3   every installed fitting is finalized, awaiting the weld

DOOR_FIT_NONE 0
DOOR_FIT_BOARD_SEATED 1
DOOR_FIT_BOARD_SECURED 2
DOOR_FIT_PANEL_HUNG 3
DOOR_FIT_PANEL_SECURED 4
DOOR_FIT_PANEL_FINALIZED 5

DOOR_CONSTRUCT_STEP_TIME      2 SECONDS
DOOR_CONSTRUCT_FIT_STEP_TIME  5 SECONDS
```

Two ints, a main stage plus an optional branch, because that is the shape of the
wall's `deconstruction_stage` + `deconstruction_r_step`. The main stage advances
to `_READY` once the fitting branch has gone as far as the installed fittings
allow: with no board and no panelling, `_WIRED` is already `_READY` on the next
check, which is how the optional steps stay optional without a second code path.
The 5-second fitting time mirrors the wall's 5-second reinforced branch.

Costs follow the wall's `#define PLATING_COST 2` style — frame 2 steel, wiring 5
coils, board 1 electronics, panelling 1 sheet per kit use — and deconstruction
returns exactly those.

## Section 6 — Testing

`/datum/unit_test/door_construction_chain` in
`code/modules/unit_tests/door_construction.dm`, added to `__unit_tests.dm`,
using `allocate()` and `TEST_ASSERT`. It walks the chain forward and asserts the
stage transitions, asserts the weld yields an `/obj/machinery/door/airlock` whose
`panel_material` is the material it was panelled with and whose `max_integrity`
that material did not change, then reverses the chain and asserts the parts come
back and the frame is gone.

Verification for the slice is the repo's compile path, `tools/build/build`, plus
the unit test run.

## Out of scope

- Door behaviour: opening, closing, auto-close, animation, bump-to-open.
- Power, wiring networks, ID access, bolts, the maintenance panel UI.
- Reinforced doors, and the Standard / Centcom / Firedoor / Bulkhead / Hazmat
  variants from the sketch.
- Multi-frame doors and the link step.
- New sprites. The skeleton reuses `icons/obj/doors/airlocks/station/airlock.dmi`
  and existing frame art so it compiles without drawing anything; the real door
  art goes through `cutter_templates/door/door_32x32.toml` later.
- Re-paneling a finished door in play.
- Windoors, shutters, firelocks, hatches.

## Consequences for later slices

- `linked_frames` exists and stays empty until multi-frame lands, so the link
  step is additive.
- `/obj/machinery/door` as the base type is where power, access and the C4
  `airlock_access` controller will attach.
- `door_icons` on the material datum is the hook the per-material door art will
  fill in, one material at a time, with no code change required.
