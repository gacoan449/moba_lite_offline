# ARENA LEGENDS — MOBA 5v5 GDD v1.0

## 1. Identity
**Title options:** Arena Legends: Riftfall (recommended), Nexus War: Eternal Rift, Mythic Frontiers: Battle of Realms.

**Vision:** original, fast, readable 5v5 fantasy MOBA with 12–18 minute matches, 3 lanes, jungle objectives, responsive combat, clear counterplay and a data-driven hero system capable of scaling to hundreds of heroes.

## 2. World Lore
Aurelia is divided by the living Rift, a magical wound beneath the battlefield. Ancient Nexus Crystals stabilize the realms, but they are losing power. Six orders send champions to capture Rift energy before rival realms do. Every match is a military conflict and a race for control of the Nexus network.

## 3. Core Loop
Spawn → lane/jungle → farm → trade → level/power spike → rotate → objective → tower → teamfight → high ground → enemy Nexus.

**Laning:** Solo/EXP lane favors fighters/tanks; Mid favors mage/assassin; Gold lane is marksman + support; Jungle controls camps, ganks and objectives.

**Teamfight:** frontline creates space, control locks a priority target, damage dealers focus it, assassin cleans up, survivors convert the win into towers/objectives.

## 4. Map
- Symmetrical 5v5 arena.
- Top, Mid and Bottom lanes.
- Central river with two bridges.
- Four jungle quadrants.
- Bushes/vision pockets.
- Two opposing bases.
- Three towers per lane: outer, inner, high-ground/inhibitor.
- Nexus/core is the final win condition.

### Tide Turtle
First spawn 3:00; respawn 2:30 after defeat. Team Gold + EXP and temporary Tideguard Shield. Designed as the first major contest.

### Void Drake
First spawn 8:00; respawn 3:00. Team combat buff plus empowered minions for the next push. Designed as the siege converter.

### Jungle
Crimson Beast = Attack buff. Azure Beast = resource regeneration utility. Stone Warden = defense buff. Small camps = predictable Gold/EXP.

## 5. Economy
**Gold:** modest passive income, strong last-hit reward, smaller shared proximity reward, performance-based takedown bounty, tower rewards and team-wide epic-objective rewards.

**EXP:** solo lane gets full nearby EXP; two-player lane shares a guaranteed pool; jungle EXP is primarily local; takedowns matter but cannot replace farming; level cap 15.

### Match pacing
| Time | Goal |
|---|---|
| 0:00–2:30 | Farm and light trades |
| 2:30–5:00 | Rotations + Tide Turtle |
| 5:00–8:00 | Tower pressure and invasions |
| 8:00–11:00 | Void Drake + major fights |
| 11:00–14:00 | High-ground pressure |
| 14:00–18:00 | Final objective + Nexus siege |

Anti-snowball: stronger comeback bounties, diminishing repeated-kill bounty, objective windows instead of instant wins, gradual respawn scaling.

## 6. First Hero — Veyra, Riftblade
**Role:** Assassin | **Attack:** Melee | **Resource:** Energy | **Difficulty:** High.

**Lore:** Veyra survived a Rift collapse beneath the old capital and now carries a living shard in her twin blades. She hunts those who abuse Rift energy, striking from unexpected angles and disappearing before retaliation.

### Passive — Rift Mark
Attacks and abilities mark for 4 sec, up to 3 stacks. At 3 stacks: 70 + 0.45 Physical Attack physical damage and restore 20 Energy. Same target has a 5 sec detonation lockout.

### Skill 1 — Shadow Lunge
Dash and slash endpoint.
- Damage: 80 / 110 / 140 / 170 / 200 + 0.80 Physical Attack
- Cooldown: 8 / 7.5 / 7 / 6.5 / 6 sec
- Energy: 25
- Mana: N/A
- Range: 6m
- Applies 1 mark; champion hit grants 20% move speed for 1.5 sec.

### Skill 2 — Veilstep
Untargetable 0.35 sec, then reappear behind nearest marked enemy.
- Damage: 60 / 90 / 120 / 150 / 180 + 0.60 Physical Attack
- Cooldown: 12 / 11 / 10 / 9 / 8 sec
- Energy: 35
- Mana: N/A
- Range: 5.5m
- Applies mark; 35% slow for 1 sec; cannot cross terrain.

### Ultimate — Rift Execution
Lock onto a marked enemy, resist displacement briefly, blink through and explode.
- Damage: 180 / 280 / 380 + 1.10 Physical Attack
- Missing-HP bonus: up to 35%
- Cooldown: 55 / 45 / 35 sec
- Energy: 60
- Mana: N/A
- Applies mark; target death within 2 sec refunds 40% cooldown.

**Combo:** Basic → Skill 1 → Basic → Skill 2 → passive detonation → Ultimate. Safer: Skill 1 → Skill 2 dodge → detonation → Ultimate at low HP.

**Counters:** hard-CC tanks, peel supports, spaced marksmen, control mages; armor, tenacity, shields and anti-burst items; vision and denying isolated targets.

## 7. Mobile HUD
Left joystick; right attack + three skill buttons; large ultimate button with cooldown ring; top-right minimap; top-center score/timer/objective; bottom HP + Energy; optional smart targeting and manual aim.

## 8. Technical Direction
The existing repository is a Flutter/three_js prototype. The Unity architecture is isolated under Unity/ so C# gameplay code can become authoritative during a future migration without mixing Dart and C# runtimes.

Data flow: Hero Prefab → HeroAbilityController → AbilityExecutor → SkillData asset → Combat interfaces.

A new hero should normally require data assets and prefab configuration, not a giant hero switch statement.

## 9. Roadmap
A: movement, attacks, abilities, resources, damage/CC, minions, towers.
B: 3 lanes, jungle, Tide Turtle, Void Drake, Nexus, Gold/EXP, levels, 5v5.
C: 10 launch heroes, six roles, 20+ items, hero selection, builds, tutorial.
D: authoritative server, matchmaking, reconnect, anti-cheat, persistence, analytics, ranked.

**Scope:** a production online MOBA still requires networking, server authority, animation/VFX/audio, matchmaking, persistence, anti-cheat, QA and device optimization.
