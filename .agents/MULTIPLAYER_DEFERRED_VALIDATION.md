# Multiplayer Deferred Validation Backlog

This file records multiplayer work intentionally deferred while production is
focused on the solo game. It is a validation backlog, not permission to remove
or ignore multiplayer implementation paths.

## Active Production Rule

Decision date: 2026-10-29.

Multiplayer validation was explicitly resumed by the user on 2026-10-29 for
the release following 2.0.60. The evidence below records the completed local
multi-process pass; it does not convert local ENet into physical-device proof.

- Build and validate the solo behavior first.
- When a changed system already participates in multiplayer, keep its authority,
  serialization, RPC, snapshot, legacy/default, and remote-presentation paths
  compatible as part of the implementation.
- Do not run multiplayer-specific validation unless the user explicitly asks to
  resume it. This includes dedicated server, host/client, relay, lobby/online,
  multi-process, public-network, and physical multi-device tests.
- Solo smokes, solo visual QA, parsing, and project validation remain available;
  they must not be described as multiplayer proof.
- Add one compact item below for every new feature whose multiplayer behavior
  was implemented or may have been affected but was not actually validated.
- A pending item is cleared only with explicit multiplayer validation evidence.

During normal solo work, append the new item without auditing the entire list.
Read and execute the complete backlog only when the user asks to focus on
multiplayer again.

## Frozen Reproducible Baseline

- Branch: `runtime-refactor-next`
- Remote commit: `068448a20c2513ea84233b5e8dd023c26e802600`
- Commit title: `release: publish 2.0.60 update manifests`
- Game version: `2.0.60`
- Android version code: `26000`
- Freeze date: 2026-10-29

This commit is the durable Git reference for the multiplayer version considered
stable at the start of solo-first production. Dirty worktree changes are not
part of that reproducible baseline.

## Evidence Recorded Before the Freeze

### MP-000 - Henry Incendiario traveling spin

Status: multiplayer validated locally before the freeze; not pending unless the
feature changes again.

- Henry travels to the selected teleport destination, remains protected, allows
  movement after arrival, explodes after 2.45 seconds, and transports the full
  destination in its ability visual event.
- Evidence: focused gameplay smoke, desktop/mobile visual smoke, and local
  dedicated relay plus host plus client all passed on 2026-10-29.
- Git note: this delta was still uncommitted when the freeze was recorded, so the
  frozen remote commit above remains the only reproducible baseline.

## Pending Multiplayer Validation

### MP-001 - Suturador de Ambar combat and card economy

Status: local multi-process validation completed on 2026-10-29.

Solo/local evidence already available:

- Four-attack rotation, movement, hook telegraph/pull, visible card theft,
  rewards, cleanup, save behavior, presentation captures, and deep project
  validation passed.
- Local contract checks exist, but they are not dedicated server plus host plus
  client proof.

Multiplayer evidence completed in the resumed pass:

- Dedicated server, host and client completed the authority battery; the target
  client alone received Suturador card mutation through request, relay and
  client-apply paths.
- The four-process match (server, host, client and client2) proved target-only
  theft/restoration while the non-target client retained its card.
- Duplicate steal and restore RPCs were injected in both duo and trio runs.
  Client apply is now idempotent per encounter/card, and a restore without a
  matching theft cannot grant a card.
- The authoritative snapshot transported encounter identity and hook visual
  state before cleanup; the existing room lifecycle battery covered orderly
  leave/shutdown after the feature pass.
- Focused gameplay and visual smokes still cover clamp, pull, named feedback,
  cleanup, rewards and desktop/mobile-profile presentation.

Not represented as proof: a physical two-device Android session during an
active theft. The public relay is validated again as part of release activation.

Suggested entry points when multiplayer validation resumes:

- `tests/phase6_amber_suturer_smoke.gd`
- `tests/phase6_amber_suturer_visual_smoke.gd`
- The project multiplayer runner with `server`, `host`, and `client` roles; do
  not invoke a role-based smoke without its role arguments.

### MP-002 - Boss 6 Matriarca three-stage rework

Status: local multi-process validation completed on 2026-10-29.

Solo scope currently represented in the worktree:

- Three health stages, stage-specific movement, Foices Vertebrais, Florada
  Acida, Mare de Carnificina, authored attack frames, and living-team target
  batches capped at three players.
- Boss visual snapshots now carry `boss6_stage`.

Multiplayer evidence completed in the resumed pass:

- Dedicated server relayed the authoritative phase-6 identity while host,
  client and client2 all received stage 3 and the same active ability.
- The focused team-pressure smoke proved living-only target selection, dead
  exclusion and a three-player cap; the trio transport pass preserved those
  player identities without local boss simulation on the relay.
- Snapshot pack/apply transported `boss6_stage`, ability and Suturador state in
  refreshed snapshots; legacy/default behavior remains covered by the focused
  Boss 6 contract smoke.
- General multiplayer lifecycle, ability visual and authority batteries passed
  after the Boss 6 transport pass, including leave/shutdown cleanup.
- Six real-render captures cover all three forms on desktop and mobile
  landscape with the segmented bar and team target markers.

Not represented as proof: a physical mobile client observing a live internet
Boss 6 fight. The public host/client transport is validated at release time.

Suggested entry points when multiplayer validation resumes:

- `tests/boss6_three_stage_rework_smoke.gd`
- `tests/boss6_team_pressure_smoke.gd`
- `tests/boss6_three_stage_visual_smoke.gd`
- `tests/multiplayer_gameplay_authority_smoke.gd` through a runner that supplies
  `--role=server|host|client`
- `tests/multiplayer_visual_fidelity_visual_smoke.gd`

### MP-003 - Hidden unpolished manifestations and specters

Status: local multi-process validation completed on 2026-10-29.

Solo scope represented in the worktree:

- Cartografica, Mnesica, Ressonante, Acorrentada, Necronada, Eclipsada, and
  Contratual remain in canonical data but are omitted from public selection and
  catalog surfaces.
- Nula, Abissal, Crepuscular, and Equilibrista follow the same rule.
- Carousel slots stay dense, canonical IDs stay stable, and legacy hidden
  selections fall back to public defaults before a new run.
- Focused selection, catalog, icon, specter-upgrade, and existing selector
  smokes passed; desktop 1280x720 and Android-profile landscape 960x540
  captures were rendered and inspected on 2026-10-29.

Multiplayer evidence completed in the resumed pass:

- Server, host, client and client2 completed selection using the same dense
  public lists while retaining canonical indices in transport state.
- Every non-Henry remote identity is now asserted public during the two- and
  three-player integration flow; duplicate-choice rejection/retry remained
  operational and the match started only after public selections were ready.
- The reconciliation battery covered reconnect-adjacent lobby state, spectator,
  shop, selection and final match startup without exposing a hidden identity.
- Focused selector/catalog tests and inspected desktop/mobile-profile captures
  contain no hidden cards, dots, gaps, notifications or catalog entries.

Not represented as proof: a physical-device reconnect while the selector is
open. Canonical fallback and delayed-packet guards remain covered locally.

Suggested entry points when multiplayer validation resumes:

- `tests/hidden_manifestations_specters_smoke.gd`
- `tests/hidden_selection_visual_smoke.gd`
- `tests/multiplayer_manifest_flow_smoke.gd` through the complete role-based
  multiplayer runner.

## Template for Future Items

Copy this block for each solo-first feature with deferred multiplayer proof:

```text
### MP-XXX - Feature name

Status: pending multiplayer validation.
Solo evidence: tests or captures that actually ran.
Affected contract: authority, payload/snapshot/RPC, remote presentation, or state cleanup.
Multiplayer scenarios still owed:
- Server/host/client behavior.
- Two- and three-player ownership/targeting.
- Duplicate, late, disconnect, retry, and cleanup behavior as applicable.
- Remote desktop/mobile visual parity as applicable.
Suggested tests/runners: exact paths or commands to use later.
```
