# Eclipsa

A **real-time strategy (RTS) game for iPhone** that simplifies the genre's mechanics for a newer generation of players. Command troops, harvest solar energy and defend your Nexus against waves of moon soldiers. Built with SpriteKit and GameplayKit using an entity–component architecture.

## Features

- **Simplified RTS controls:** command groups of troops with on-screen buttons, and control your hero with movement and aim controls (game controller support included).
- **Solar resource economy:** Inhibitors generate **Solar Fragments** that you spend to summon troops.
- **Troops and combat:** melee and ranged attacks, health bars, attack indicators, pathfinding and target tracking.
- **Enemy hordes:** Spawns on the enemy side send groups of troops toward your base.
- **Five phases:** each one adds more Inhibitors, Spawns and larger troop groups, plus an interactive tutorial.
- **Story:** intro and ending dialogue scenes.
- **Multiplayer:** Game Center matchmaking, with a synced multiplayer game scene.
- **Achievements:** Game Center achievement for finishing the story.
- **Polish:** loading screen, settings, credits, haptics, music and sound effects.

## Architecture

| Folder | Contents |
| --- | --- |
| `ECS/Core` | Entity and component foundation, Game Center manager |
| `ECS/Entities` | Buildings (Nexus, Inhibitor, Spawn), units and troops, projectiles, camera |
| `ECS/TroopComponents` | Combat (health, melee, ranged) and movement (agents, behavior, control system) |
| `ECS/UnitComponents` | Animation, range, team, sprite rendering, player movement and aim |
| `Scenes` | `GameScene` and `MultiplayerGameScene` with setup, win, defeat and sync extensions, plus HUD, dialogue and buttons |
| `Source` | App flow and screens: home, tutorial, settings, credits, team logo |
| `Multiplayer` | Game Center match view controllers |
| `Utils`, `Resources` | Constraints, extensions, audio and font managers |

## Tech stack

![Swift](https://img.shields.io/badge/Swift-F05138?style=for-the-badge&logo=swift&logoColor=white) ![SpriteKit](https://img.shields.io/badge/SpriteKit-000000?style=for-the-badge&logo=apple&logoColor=white) ![GameplayKit](https://img.shields.io/badge/GameplayKit-FF9500?style=for-the-badge&logo=apple&logoColor=white) ![GameKit](https://img.shields.io/badge/GameKit-34C759?style=for-the-badge&logo=apple&logoColor=white) ![UIKit](https://img.shields.io/badge/UIKit-2396F3?style=for-the-badge&logo=apple&logoColor=white) ![Xcode](https://img.shields.io/badge/Xcode-147EFB?style=for-the-badge&logo=xcode&logoColor=white)

It also uses [BehindGameKit](https://github.com/victorabroum/BehindGameKit), a Swift package for SpriteKit and GameplayKit games, resolved automatically by Swift Package Manager.

## Running the project

Requirements: Xcode and an iPhone or simulator. Game Center features need a device or simulator signed in to a Game Center account.

1. Clone the repository:
   ```bash
   git clone https://github.com/Luan-Aiezza/RTSGame.git
   ```
2. Open `Eclipsa/Eclipsa.xcodeproj` in Xcode and let it resolve the Swift packages.
3. Select an iPhone and press **Run** (⌘R).

## Team

Built by [Luan Aiezza](https://github.com/Luan-Aiezza) and Joseph Bezerra.
