# Door Construction Boilerplate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give Dionysus a buildable normal airlock — a steel frame that is secured, wired, boarded, panelled and welded into `/obj/machinery/door/airlock` — with no door behaviour.

**Architecture:** Three new types modelled one-for-one on the wall chain: `/obj/structure/door_frame` is the girder, `/obj/item/door_panel_kit` is the `wall_trim_kit`, and `/obj/machinery/door/airlock` is what the frame finishes into. Stage progress is two stored ints, exactly as the wall stores `deconstruction_stage` plus the optional `deconstruction_r_step`. Panelling is a `datum/material` on the door that changes only which `door_icons` entry is drawn.

**Tech Stack:** BYOND DreamMaker 516 (DM language), the repo's `/datum/unit_test` suite, Juke Build (`tools/build/build.js`).

**Spec:** `docs/superpowers/specs/2026-11-23-door-construction-boilerplate-design.md`

## Global Constraints

- The finished door is `/obj/machinery/door/airlock`. It is an object on a floor turf, never a turf.
- Building, finishing and deconstructing a door never calls `ChangeTurf` or `ScrapeAway`. The floor under a door is a precondition, checked, not a thing we mutate.
- Steel only structurally. `panel_material` is visual: it must never enter `update_material_resistances()` or touch `max_integrity`.
- Normal doors only. No reinforced doors, no Standard / Centcom / Firedoor / Bulkhead / Hazmat variants.
- Single tile. `linked_frames` exists on the frame and stays empty; nothing reads it.
- The door does not open, close, animate, take power or check access in this slice.
- Every tool step is `tool.use_tool(src, user, DOOR_CONSTRUCT_STEP_TIME, volume = 50)` behind a `balloon_alert_to_viewers()`, and checks `Adjacent()` first, as the girder does.
- Every stage has an `examine()` line naming the next tool, as the girder and the wall both do.
- Costs, both directions: frame 2 steel, wiring 5 coils, board 1 electronics, panelling 1 sheet per kit use.
- Step times: `DOOR_CONSTRUCT_STEP_TIME` is `2 SECONDS`, `DOOR_CONSTRUCT_FIT_STEP_TIME` is `5 SECONDS`, mirroring the wall's 2s / 5s split.
- Integrity comes from steel and from nothing else: the frame takes the girder's half (`/datum/material/steel::wall_integrity * 0.5`), the finished door takes the whole (`/datum/material/steel::wall_integrity`). `panel_material` never enters either figure.
- Layer for a closed door: `CLOSED_DOOR_LAYER` (`code/__DEFINES/layers.dm:85`).
- Keep `dionysus.dme` and `code/modules/unit_tests/__unit_tests.dm` includes alphabetically sorted, as both files ask at their top.

## Review Focus

The spec is silent on these and they are where this skeleton will actually break on someone:

1. **The floor stops being a floor mid-build** — someone pries up the tile under a half-built frame. Expected: the next secure or weld attempt refuses with a balloon alert, the frame stays where it is, and no turf is changed.
2. **A material with no `door_icons`** — 109 of 112 materials have no door art. Expected: the door draws steel's art, with no runtime error and no `stack_trace` per panelled door.
3. **Icon work before `SSmaterials.initialized`** — mapload runs `update_icon` before materials exist, which is why `constructed_wall/update_icon()` returns early. Expected: the door's icon update returns early the same way rather than `stack_trace`-ing on a null material instance. No unit test can reach this state — materials are always initialized by the time the test zone runs — so it is pinned by the guard in Task 4 Step 4 and by `runtime.log` staying empty, not by an assertion.
4. **An interrupted tool action** — welder runs out of fuel, or the user walks off. Expected: `use_tool` returning false leaves the stage unchanged and the item unconsumed, as the girder's steps do.
5. **A second application of a finished fitting** — a board onto a boarded frame, a kit onto a panelled frame. Expected: refused with a balloon alert, and the held item is not eaten.

## File Structure

```
code/__DEFINES/construction_doors.dm             new   stage + fitting + step-time defines
code/modules/construction/door/door_frame.dm     exists, 0 bytes   /obj/structure/door_frame
code/modules/construction/door/airlock.dm        new   /obj/machinery/door, /obj/machinery/door/airlock
code/modules/construction/door/panel_kit.dm      new   /obj/item/door_panel_kit
code/modules/construction/door/mappables.dm      new   prebuilt panelled doors for mappers
dionysus.dme                                     modify 5 include lines
code/datums/materials/_material.dm               modify +door_icons
code/datums/materials/basemats.dm                modify steel gets door_icons
code/game/objects/items/stacks/sheets/sheet_types.dm  modify +2 stack recipes
code/modules/unit_tests/door_construction.dm     new   the chain tests
code/modules/unit_tests/__unit_tests.dm          modify +1 include
```

`code/modules/construction/door/door_frame.dm` already exists at 0 bytes and is untracked; it is the file the operator started, not a stray.

## Verification commands

Run from the repo root. On this NixOS box the `tools/bootstrap/node` and
`tools/bootstrap/python` shims do not find nix's binaries, so:

```sh
# fast gate, ~25s: compile only, no test files
nix shell nixpkgs#nodejs_22 nixpkgs#python3 -c sh -c \
  'PATH=$(dirname $(readlink -f $(which node))):$PATH; node tools/build/build.js dm -Werror'

# real gate, ~155s: compile with tests and run them under DreamDaemon
nix shell nixpkgs#nodejs_22 nixpkgs#python3 -c sh -c \
  'PATH=$(dirname $(readlink -f $(which node))):$PATH; node tools/build/build.js dm-test'
```

Both were confirmed working on this checkout at `44d78476d86`: `dm` reports
`dionysus.dmb - 0 errors, 0 warnings`, and `dm-test` ends `Success!`. CI runs the
same compile as `tools/build/build --ci dm -DCIBUILDING -DANSICOLORS -Werror` and
then `bash tools/ci/run_server.sh start`.

`dm-test` is the only target that compiles the test files: `CIBUILDING` implies
`UNIT_TESTS` at `code/_compile_options.dm:200-201`, and `__unit_tests.dm` is
wrapped in `#if defined(UNIT_TESTS) || defined(SPACEMAN_DMM)`. A plain `dm`
compile will happily ignore a test file that does not parse. Note also that `dm`
is an output-cached target and can report `Skipping 'dm' (up to date)`; `dm-test`
has no outputs and always runs.

What a failing test looks like, in this order:

- `data/logs/ci/tests.log` gains `FAIL: /datum/unit_test/<name> <reason>` where a
  passing one reads `PASS: /datum/unit_test/<name> 0.1s`
- `data/logs/ci/clean_run.lk` is not written, and the target exits 1 with
  `Test run was not clean, exiting`
- a runtime anywhere in the round fails the run on its own
  (`world/FinishTestRun()` checks `GLOB.total_runtimes`), so a null `door_icons`
  index that only `stack_trace`s still turns the build red. Check
  `data/logs/ci/runtime.log`.

---

## Task 1: Types, defines and includes that compile

**Files:**
- Create: `code/__DEFINES/construction_doors.dm`
- Create: `code/modules/construction/door/airlock.dm`
- Create: `code/modules/construction/door/panel_kit.dm`
- Create: `code/modules/construction/door/mappables.dm`
- Modify: `code/modules/construction/door/door_frame.dm` (exists at 0 bytes)
- Modify: `dionysus.dme` (beside the `code\modules\construction\wall\*` includes at 2877-2883)

**Interfaces:**
- Consumes: nothing.
- Produces: `/obj/structure/door_frame` with vars `construction_stage`, `fitting_stage`, `datum/board`, `panel_material`, `linked_frames`; `/obj/machinery/door` and `/obj/machinery/door/airlock`; `/obj/item/door_panel_kit` with vars `panel_material`, `uses_left`; the `DOOR_CONSTRUCT_*`, `DOOR_FIT_*`, `DOOR_CONSTRUCT_STEP_TIME`, `DOOR_CONSTRUCT_FIT_STEP_TIME` defines.

- [ ] **Step 1: Write the defines file**

`code/__DEFINES/construction_doors.dm`, values exactly as the spec's Section 5:

```
DOOR_CONSTRUCT_FRAME 0, DOOR_CONSTRUCT_SECURED 1, DOOR_CONSTRUCT_WIRED 2, DOOR_CONSTRUCT_READY 3
DOOR_FIT_NONE 0, DOOR_FIT_BOARD_SEATED 1, DOOR_FIT_BOARD_SECURED 2,
DOOR_FIT_PANEL_HUNG 3, DOOR_FIT_PANEL_SECURED 4, DOOR_FIT_PANEL_FINALIZED 5
DOOR_CONSTRUCT_STEP_TIME 2 SECONDS, DOOR_CONSTRUCT_FIT_STEP_TIME 5 SECONDS
```

- [ ] **Step 2: Declare the four types with their static vars and no logic**

`/obj/structure/door_frame` (`door_frame.dm`) mirrors `/obj/structure/girder`'s
header: `name = "door frame"`, `desc`, `density = FALSE`,
`can_atmos_pass = CANPASS_ALWAYS`, `anchored = FALSE`,
`max_integrity = /datum/material/steel::wall_integrity * 0.5` (the girder's
half-integrity frame), the four vars from the Interfaces block, and
`icon = 'icons/obj/doors/airlocks/station/airlock.dmi'` with an `icon_state` that
exists in it — a missing icon *file* is a DreamMaker error, a missing state is
only an invisible object, and the real frame art is out of scope.
`/obj/machinery/door` (`airlock.dm`) is the bare base: `abstract_type`,
`density = TRUE`, `opacity = TRUE`, `anchored = TRUE`,
`layer = CLOSED_DOOR_LAYER`, `can_atmos_pass = CANPASS_DENSITY`,
`max_integrity = /datum/material/steel::wall_integrity`.
`/obj/machinery/door/airlock` is `/obj/machinery/door` with `name = "airlock"`
and the same station airlock icon. `/obj/item/door_panel_kit` and the mappables
are likewise declarations only at this point.

- [ ] **Step 3: Add the five `#include` lines to `dionysus.dme`**

One for the defines file (alphabetically after `construction_walls.dm` at line
80) and four for the module files (alphabetically before
`code\modules\construction\girder.dm` at line 2877).

- [ ] **Step 4: Compile**

Run the fast gate. Expected: succeeds. Nothing references the new types yet, so
this task's whole result is "the skeleton is in the compile".

- [ ] **Step 5: Commit**

```sh
git add code/__DEFINES/construction_doors.dm code/modules/construction/door dionysus.dme
git commit -m "Add door construction type skeleton"
```

---

## Task 2: Place and secure the frame

**Files:**
- Modify: `code/modules/construction/door/door_frame.dm`
- Modify: `code/game/objects/items/stacks/sheets/sheet_types.dm` (beside `"wall girders"` at :74)
- Create: `code/modules/unit_tests/door_construction.dm`
- Modify: `code/modules/unit_tests/__unit_tests.dm`

**Interfaces:**
- Consumes: `/obj/structure/door_frame` and `DOOR_CONSTRUCT_*` from Task 1.
- Produces: `/obj/structure/door_frame/proc/can_finish(mob/user) -> bool` (the floor check every later step reuses), `wrench_act` advancing `_FRAME` to `_SECURED`, the `"door frame"` stack recipe.

- [ ] **Step 1: Write the failing test**

`/datum/unit_test/door_frame_placement` in `code/modules/unit_tests/door_construction.dm`,
`name = "DOOR: Frame placement and securing"`. Using `allocate()` (which defaults
loc to `run_loc_floor_bottom_left`) and a `allocate(/mob/living/carbon/human)`:

- `ASSERT(istype(allocate(/obj/structure/door_frame)))`
- frame starts `construction_stage == DOOR_CONSTRUCT_FRAME` and `!anchored`
- after `frame.wrench_act(user, allocate(/obj/item/wrench))`: `anchored` is
  `TRUE` and `construction_stage == DOOR_CONSTRUCT_SECURED`
- a frame allocated on a `/turf/open/floor/plating` refuses to secure: stage and
  `anchored` unchanged (Review Focus 1)

- [ ] **Step 2: Run the test gate to see it fail**

Expected: `FAIL: /datum/unit_test/door_frame_placement` in
`data/logs/ci/tests.log` and the target exiting 1. The compile itself is clean —
in DM a test that asserts unimplemented behaviour compiles fine and fails at
run time, which is why this plan's red step is always `dm-test` and never `dm`.

- [ ] **Step 3: Implement `can_finish`, `wrench_act` and `examine`**

`can_finish(mob/user)` holds the girder's `if(!istype(my_loc,
/turf/open/floor))` → `balloon_alert(user, "how?")` guard and returns FALSE.
`wrench_act` follows `/obj/structure/girder/wrench_act`: `Adjacent` check,
balloon alert, `use_tool`, flip `anchored`, advance the stage. `examine` names
the next tool for each of the two stages.

- [ ] **Step 4: Add the `"door frame"` stack recipe**

Beside `"wall girders"` in `sheet_types.dm`: 2 steel, `time = 2 SECONDS`,
`one_per_turf = TRUE`, `on_floor = TRUE`, and the same `trait_booster =
TRAIT_QUICK_BUILD, trait_modifier = 0.75` the girder's recipe carries.

- [ ] **Step 5: Compile**

Run the test gate. Expected: `PASS: /datum/unit_test/...` for this task's test in `data/logs/ci/tests.log`, and `Success!` written to `clean_run.lk`.

- [ ] **Step 6: Commit**

```sh
git add code/modules/construction/door/door_frame.dm code/game/objects/items/stacks/sheets/sheet_types.dm code/modules/unit_tests
git commit -m "Add door frame placement and securing"
```

---

## Task 3: Wiring and the AC board

**Files:**
- Modify: `code/modules/construction/door/door_frame.dm`
- Modify: `code/modules/unit_tests/door_construction.dm`

**Interfaces:**
- Consumes: `can_finish`, `construction_stage`, `fitting_stage` from Tasks 1-2; `/obj/item/stack/cable_coil` (`code/modules/power/cable.dm:446`); `/obj/item/electronics` (`code/game/objects/items/wall_mounted.dm:94`).
- Produces: `construction_stage == DOOR_CONSTRUCT_WIRED` once 5 coils are spent, `frame.board` holding an `/obj/item/electronics` with `fitting_stage` at `DOOR_FIT_BOARD_SEATED` then `DOOR_FIT_BOARD_SECURED`, and `/obj/structure/door_frame/proc/advance_fitting()` which recomputes `DOOR_CONSTRUCT_READY` from what is installed.

- [ ] **Step 1: Write the failing test**

`/datum/unit_test/door_frame_fittings`, `name = "DOOR: Wiring and board"`. Assert:

- coil applied to an unsecured frame is refused; to a secured frame it consumes 5
  coils and sets `construction_stage == DOOR_CONSTRUCT_WIRED`
- `/obj/item/electronics` applied next sets `board` non-null and
  `fitting_stage == DOOR_FIT_BOARD_SEATED`
- `screwdriver_act` next sets `fitting_stage == DOOR_FIT_BOARD_SECURED` and
  `construction_stage == DOOR_CONSTRUCT_READY` (nothing else installed, so the
  optional branch is complete)
- a second board onto a boarded frame is refused and the held board survives
  (Review Focus 5)
- a board applied before wiring is refused
- coils applied with the welder/tool step interrupted leave
  `construction_stage` at `DOOR_CONSTRUCT_SECURED` and the coil stack's amount
  unchanged (Review Focus 4)

- [ ] **Step 2: Run the test gate to see it fail**

Expected: `FAIL: /datum/unit_test/door_frame_fittings` in `data/logs/ci/tests.log`, target exits 1.


- [ ] **Step 3: Implement `attackby` for coils and board, `screwdriver_act`, and `advance_fitting`**

`attackby` mirrors `/obj/structure/girder/attackby`: dispatch on item type,
`use_tool` with `DOOR_CONSTRUCT_STEP_TIME` for the coils and
`DOOR_CONSTRUCT_FIT_STEP_TIME` for the board, `use(n)` on the stack only after
the tool succeeds (Review Focus 4). `advance_fitting()` is the one place that
sets `DOOR_CONSTRUCT_READY`, so the optionality of board and panelling lives in
exactly one proc.

- [ ] **Step 4: Extend `examine`**

One line per new stage naming the next tool, in the girder's voice ("The wiring
can be <b>welded</b>..." style).

- [ ] **Step 5: Compile**

Run the test gate. Expected: `PASS: /datum/unit_test/...` for this task's test in `data/logs/ci/tests.log`, and `Success!` written to `clean_run.lk`.

- [ ] **Step 6: Commit**

```sh
git add code/modules/construction/door/door_frame.dm code/modules/unit_tests/door_construction.dm
git commit -m "Add door frame wiring and AC board steps"
```

---

## Task 4: Panelling, the kit item and the material hook

**Files:**
- Modify: `code/modules/construction/door/panel_kit.dm`
- Modify: `code/modules/construction/door/door_frame.dm`
- Modify: `code/datums/materials/_material.dm` (beside `wall_icons` at :54)
- Modify: `code/datums/materials/basemats.dm` (`/datum/material/steel` at :2)
- Modify: `code/game/objects/items/stacks/sheets/sheet_types.dm` (beside `"wall trim kit"` at :75)
- Modify: `code/modules/unit_tests/door_construction.dm`

**Interfaces:**
- Consumes: `fitting_stage`, `advance_fitting` from Task 3; the `wall_trim_kit` pattern.
- Produces: `/datum/material::door_icons` (a `list/icon`, destroyed-to-max order), `/datum/material/steel::door_icons`, `/obj/item/door_panel_kit` with `panel_material` and `uses_left`, `door_frame.panel_material`, and `/obj/structure/door_frame/proc/panel_icon_state() -> icon` which resolves a material's `door_icons` with the steel fallback.

- [ ] **Step 1: Write the failing test**

`/datum/unit_test/door_panelling`, `name = "DOOR: Panelling is visual only"`. Assert:

- a kit with no `panel_material` refuses; a bronze sheet hit against the kit sets
  `panel_material` and `uses_left` 0 → 1; a steel sheet against a bronze kit is
  refused and leaves `uses_left` alone
- kit use on a frame at `DOOR_FIT_BOARD_SECURED` sets `panel_material` and
  `fitting_stage == DOOR_FIT_PANEL_HUNG`, and decrements `uses_left`
- `screwdriver_act` → `DOOR_FIT_PANEL_SECURED`; `screwdriver_act_secondary` →
  `DOOR_FIT_PANEL_FINALIZED`
- crowbar on the frame at `DOOR_FIT_PANEL_HUNG` clears `panel_material`, returns
  1 sheet to the user, and drops `fitting_stage` back
- a kit used on a frame already at `DOOR_FIT_PANEL_HUNG` or later is refused and
  `uses_left` is not spent (Review Focus 5)
- **the integrity assertion that keeps "steel only" honest:** a bronze-panelled
  frame's `max_integrity` equals the same frame unpanelled (Review Focus 2's
  sibling: bronze changes the picture, not the numbers)
- `panel_icon_state()` on a material with no `door_icons` returns steel's list
  rather than null, and does not `stack_trace`

- [ ] **Step 2: Run the test gate to see it fail**

Expected: `FAIL: /datum/unit_test/door_panelling` in `data/logs/ci/tests.log`, target exits 1.


- [ ] **Step 3: Add `door_icons` to `/datum/material` and give steel a value**

`var/list/icon/door_icons` beside `wall_icons` with the same
destroyed-to-max-durability comment. Steel's entry points at the existing
station airlock art so no new sprites are needed.

- [ ] **Step 4: Implement `panel_icon_state()` with the steel fallback**

Resolve through `GET_MATERIAL_REF(panel_material)`, index by integrity as
`constructed_wall/update_icon()` does with `MAP(integrity_pct, 0, 1, 1,
total_states)`, and fall back to `/datum/material/steel::door_icons` when the
material's own list is null. `stack_trace` only when steel's is missing too.
Return early when `!SSmaterials.initialized`, as the wall does (Review Focus 3).

- [ ] **Step 5: Implement the kit and the three panel stages**

`/obj/item/door_panel_kit` is `/obj/item/wall_trim_kit` with the turf swapped for
the frame: `pre_attack` applies, `attackby` restocks one sheet,
`attackby_secondary` restocks all with `SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN`.
On the frame, `screwdriver_act` and `screwdriver_act_secondary` gain the two new
fitting stages, and `crowbar_act` gains the panel-removal branch.

- [ ] **Step 6: Add the `"door panel kit"` stack recipe**

2 steel, `time = 2 SECONDS`, beside `"wall trim kit"`, no `one_per_turf`.

- [ ] **Step 7: Compile**

Run the test gate. Expected: `PASS: /datum/unit_test/...` for this task's test in `data/logs/ci/tests.log`, and `Success!` written to `clean_run.lk`.

- [ ] **Step 8: Commit**

```sh
git add code/modules/construction/door code/datums/materials code/game/objects/items/stacks/sheets/sheet_types.dm code/modules/unit_tests/door_construction.dm
git commit -m "Add door panelling kits and the door_icons material hook"
```

---

## Task 5: Weld the door into existence

**Files:**
- Modify: `code/modules/construction/door/door_frame.dm`
- Modify: `code/modules/construction/door/airlock.dm`
- Modify: `code/modules/unit_tests/door_construction.dm`

**Interfaces:**
- Consumes: `DOOR_CONSTRUCT_READY`, `board`, `panel_material`, `can_finish` from Tasks 1-4.
- Produces: `/obj/structure/door_frame/proc/finalize_door() -> /obj/machinery/door/airlock`, `/obj/machinery/door/airlock/proc/apply_from_frame(frame)`, and `welder_act_secondary` on the frame.

- [ ] **Step 1: Write the failing test**

`/datum/unit_test/door_finalization`, `name = "DOOR: Welding finalizes without touching the turf"`. Assert:

- welding a frame below `DOOR_CONSTRUCT_READY` does not produce a door
- welding a ready frame leaves exactly one `/obj/machinery/door/airlock` on the
  turf, `qdel`ed the frame, and the door's `panel_material` and `board` match the
  frame's
- **the turf is the same turf object before and after** — no `ChangeTurf`, no
  `ScrapeAway` (Review Focus 1)
- the door is `density` and `opacity` and on `CLOSED_DOOR_LAYER`
- welding a frame whose floor was pried to plating refuses (Review Focus 1)
- an interrupted weld — `use_tool` returning FALSE — leaves the frame at
  `DOOR_CONSTRUCT_READY` with no door spawned (Review Focus 4)

- [ ] **Step 2: Run the test gate to see it fail**

Expected: `FAIL: /datum/unit_test/door_finalization` in `data/logs/ci/tests.log`, target exits 1.


- [ ] **Step 3: Implement `finalize_door()` and `apply_from_frame()`**

`finalize_door()` spawns the airlock at `src.loc`, hands it the frame's `board`
and `panel_material` through `apply_from_frame()`, then `qdel(src)`. No turf
call anywhere. `apply_from_frame()` is the only place a door's initial state is
set, so the later behaviour slice has one seam to grow.

- [ ] **Step 4: Implement `welder_act_secondary` on the frame**

`Adjacent` check, `can_finish`, balloon alert, `use_tool` at
`DOOR_CONSTRUCT_STEP_TIME`, then `finalize_door()`.

- [ ] **Step 5: Compile**

Run the test gate. Expected: `PASS: /datum/unit_test/...` for this task's test in `data/logs/ci/tests.log`, and `Success!` written to `clean_run.lk`.

- [ ] **Step 6: Commit**

```sh
git add code/modules/construction/door code/modules/unit_tests/door_construction.dm
git commit -m "Weld a ready door frame into an airlock"
```

---

## Task 6: Strip it back down, and prebuilt doors for mappers

**Files:**
- Modify: `code/modules/construction/door/door_frame.dm`
- Modify: `code/modules/construction/door/airlock.dm`
- Modify: `code/modules/construction/door/mappables.dm`
- Modify: `code/modules/unit_tests/door_construction.dm`

**Interfaces:**
- Consumes: everything from Tasks 1-5.
- Produces: `/obj/machinery/door/airlock/crowbar_act` returning a frame, the frame's reverse chain, `/obj/machinery/door/airlock/atom_destruction`, and `/obj/machinery/door/airlock/panelled` with `/panelled/steel` and `/panelled/bronze`.

- [ ] **Step 1: Write the failing test**

`/datum/unit_test/door_deconstruction`, `name = "DOOR: The chain reverses"`. Assert:

- crowbar on the finished door yields a `/obj/structure/door_frame` on the same
  turf carrying the same `panel_material` and `board`, and the door is gone
- the frame in reverse order — crowbar panel (1 sheet back), screwdriver board
  twice (board back), wirecutters (5 coils back), wrench (unanchor), welder
  secondary (2 steel back) — ends with no frame and no turf change
- `atom_destruction` on a door yields a frame plus parts, not a bare floor
- `/obj/machinery/door/airlock/panelled/bronze` places with
  `panel_material == /datum/material/bronze` and the same `max_integrity` as
  `/panelled/steel`

- [ ] **Step 2: Run the test gate to see it fail**

Expected: `FAIL: /datum/unit_test/door_deconstruction` in `data/logs/ci/tests.log`, target exits 1.


- [ ] **Step 3: Implement the door's `crowbar_act` and `atom_destruction`**

`crowbar_act` builds the frame from the door the way
`constructed_wall/deconstruct_to_girder()` builds a girder — copy the fittings,
`anchored = TRUE`, then `qdel` the door — minus the `ScrapeAway()`.

- [ ] **Step 4: Implement the frame's reverse chain**

Each step reverses the tool that installed it, in the order the test asserts,
returning exactly the costs in Global Constraints. Follow
`girder/welder_act_secondary`'s shape, including its final
`user.put_in_hands(new /obj/item/stack/sheet/steel(loc, 2))`.

- [ ] **Step 5: Write the mappables**

`/obj/machinery/door/airlock/panelled` as the abstract parent holding
`panel_material`, with `/panelled/steel` and `/panelled/bronze` concrete. This is
where the deferred variants will hang.

- [ ] **Step 6: Compile**

Run the test gate. Expected: `PASS: /datum/unit_test/...` for this task's test in `data/logs/ci/tests.log`, and `Success!` written to `clean_run.lk`.

- [ ] **Step 7: Commit**

```sh
git add code/modules/construction/door code/modules/unit_tests/door_construction.dm
git commit -m "Reverse the door construction chain and add mappable doors"
```

---

## After the last task

Run both gates one more time and confirm the tree is clean:

```sh
nix shell nixpkgs#nodejs_22 nixpkgs#python3 -c sh -c \
  'PATH=$(dirname $(readlink -f $(which node))):$PATH; node tools/build/build.js dm -Werror'
nix shell nixpkgs#nodejs_22 nixpkgs#python3 -c sh -c \
  'PATH=$(dirname $(readlink -f $(which node))):$PATH; node tools/build/build.js dm-test'
git status --short
```

Expected: `0 errors, 0 warnings`, then `Success!` in `clean_run.lk`, and a
`git status` showing nothing but the generated `dionysus.dmb` / `dionysus.rsc`
artifacts, which are gitignored. Also confirm `data/logs/ci/runtime.log` gained no
door entries — a runtime fails CI even when every test passes.
