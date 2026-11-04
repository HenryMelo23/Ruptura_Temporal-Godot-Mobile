# Left HUD to character feedback — 2026-11-02

Scope: remove noninteractive left-side combat panels in desktop, landscape mobile
and lightweight HUD. Preserve health, anti-heal wire, XP, controls, points/shop,
boss information, central pickup notice and bottom coagulum control. Presentation
only: no card potency, cooldown, authority or snapshot changes.

XP now queries the progression owner's `xp_to_next()`, not the obsolete
40/65/... table. Label and fill have their own space below health. Maximum level
shows MAX and full fill; the progression owner remains the source of thresholds.

## Indicator-by-indicator review

| Removed left panel | Character/world replacement |
| --- | --- |
| Lastro / Marcha Total | Up to five metal fragments at the feet; partial next fragment follows points, full stacks brighten. |
| Tension / combo / overtension | Three chain links and tightening partial chain; red at full tension. Existing worn chains remain. |
| Estopim | Fuses beside character show each charge's recharge; ready fuse spark animates. Existing bombs and powder marks remain on targets. |
| Jardim Ossuario | Existing physical roses show vestiges; six rotating petals show horde progress. |
| Aura | Short fan at the feet, driven by existing aura ratio. Flames for heat/frenzy, shield chevrons for Devota/Avarento, cuts for Nula/Abissal, blood shards for hunger, temporal fragments for others. Existing aura world effects remain. |
| Sacrifice | Health-bar barbed wire retained; red stitches on character while anti-heal applies. |
| Mercenary contract | Up to four gold notches follow kills modulo five; existing payout feedback remains. |
| Collector | Red hook on execution pulse; passive thresholds stay in card descriptions, not an always-on overlay. |
| Truce | Green stem grows during preparation; existing healing aura when active. |
| Reserve | Cyan stored-energy shard scales with stored HP; flow points inward while releasing. |
| Stasis | Green preparation stem; existing repair area when active. |
| Mantle | Existing shield around character, proportional to shield capacity. |
| Suture | Existing animated stitches around character while healing remains pending. |
| Aegis | Existing shield with strength proportional to capacity. |
| Cocoon | Existing active shell; subtle shell segment reforms during cooldown. |
| Passage | Existing intangibility visual during active timer. |
| Vital Anchor | Existing world anchor and life-fading area. |
| Commandment | Gold marks above character for skill uses; existing invulnerability feedback. |
| Impulse | Up to three cyan attack streaks beside character while charges remain. |
| Zone | Existing charging field and activation effect. |
| Breath | Warm streaks at feet grow with charge. |
| Margin | Broken flank marks: gold during window, red while debt is owed. |
| Resonance | Up to four converging fragments, all four when ready. |
| Paradox | Charging fracture; existing ready/active temporal rupture effects. |
| Zero Card | Passive numeric multiplier no longer occupies combat space; card information/acquisition feedback retained. |
| Necrochronism | Growing pre-summon mote; actual specters remain visible. |
| Antimatter | Existing charging/armed energy around character. |
| Excess Vault | Existing stored-energy field and discharge feedback. |
| Contract order | Central first-reading reveal retained; objective/progress/time become outlined text above character, no corner paper. |
| Contract blessings/confiscations | Gold seal / red cancellation marks beside character; no stacked text boxes. |

Legacy drawing methods remain callable for compatibility, but no active HUD path
calls the removed left panels. New local signals are owned by
`scripts/presentation/player_status_vfx_presentation.gd`, called from the local
player renderer after the sprite. They follow camera/leap position, skip dead or
spectating players and do not create persistent nodes, particles, timers or queues.
Loops are bounded by small charge caps, not enemy count or accumulated score.

Validation: `tests/player_status_vfx_visual_smoke.gd` captures four manifestations,
animation samples, death, lightweight mode and XP levels 1–10 at 1280x720 and
960x540. This is locally rendered llvmpipe evidence, not physical Android
performance or multiplayer validation. Isolated gameplay correctness for every
listed card is not implied by this presentation smoke.

Results: visual smoke, barbed-wire regression, changed-script parsing, Main scene
120-frame validation and architecture budget passed. The progression smoke
reported functional PASS but also four ObjectDB instances and two resources
still in use at shutdown; the visual smoke did not emit that cleanup error.
