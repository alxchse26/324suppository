# Mini Games
**Bridget Thomson, Joe Koslosky, Alexandra Chase**
`bmthom26@g.holycross.edu` · `jrkosl26@g.holycross.edu` · `amchas26@g.holycross.edu`
CSCI 324 — Programming Languages | College of the Holy Cross

A rapid-fire minigame collection built in Ruby using the Ruby2D graphics library. Players race through a sequence of four minigames across 5 escalating difficulty levels, with 3 lives shared across the entire run.

---

## Requirements

- Ruby 3.x (project was developed with rbenv 3.2.0)
- Ruby2D gem (`ruby2d-0.12.1`)

Install Ruby2D if you haven't already:
```bash
gem install ruby2d
```

> **Note:** If you see warnings about `debug` or `rbs` extensions not being built on startup, these are harmless rbenv warnings and do not affect gameplay.

---

## How to Run

Make sure all `.rb` files and `dictionary.txt` are in the same folder, then:

```bash
ruby main.rb
```

---

## Gameplay Overview

- The player starts with **3 lives**
- Four minigames are presented **back to back** in a fixed order
- Completing all four advances to the next **level** (1–5)
- Each new level replays the same sequence at **increased difficulty**
- Failing a minigame costs **1 life** and automatically moves to the next one
- Losing all 3 lives ends the run — the player can restart from the beginning
- Clearing all 5 levels triggers the **victory screen**

A **transition screen** appears between every minigame showing what's coming next and your current level progress.

---

## Minigames

### 1. Passwording
A live password-creation challenge where every keystroke is evaluated against a set of regex rules.

- A list of rules is displayed on screen (e.g. "Must contain a digit", "Must be at least 8 characters")
- The player types a password into the input box — it is evaluated **on every keystroke**
- Each rule shows a green ✓ or red ✗ depending on whether the current input satisfies it
- A **strength meter** shows how many rules are currently passing
- **Win** by satisfying all rules simultaneously before the timer runs out
- **Fail** if the timer expires

| Level | Rules Active | Time Limit |
|-------|-------------|------------|
| 1     | 2           | 30s        |
| 2     | 3           | 27s        |
| 3     | 4           | 24s        |
| 4     | 5           | 21s        |
| 5     | 6           | 18s        |

Rule progression
1. At least 8 characters
2. Contains a lowercase letter
3. Contains a digit [0-9]
4. Must NOT contain spaces
5. Two digits in a row (e.g. `42`)
6. A repeated character (e.g. `ll`, `ss`)

---

### 2. Rock Climb
A physics platformer where falling rocks are both the hazard and the solution.

- The player starts on a ledge at the bottom; a goal gem sits at the top of the screen
- Rocks fall from above at regular intervals
- **Landing on top of a rock** freezes it in place (it turns blue-grey), creating a platform
- Jump again to launch upward — all frozen rocks are cleared on each jump
- **Win** by reaching the gem at the top
- **Fail** if the timer expires or the player falls off the bottom
- Controls: Arrow keys or WASD to move, Up/W/Space to jump

| Level | Rock Speed | Spawn Interval | Time Limit |
|-------|-----------|----------------|------------|
| 1     | 1.5 px/f  | 2.2s           | 60s        |
| 2     | 2.0 px/f  | 1.8s           | 50s        |
| 3     | 2.5 px/f  | 1.5s           | 42s        |
| 4     | 3.0 px/f  | 1.2s           | 35s        |
| 5     | 3.5 px/f  | 1.0s           | 28s        |

---

### 3. Seat Scramble
A whack-a-mole style game played on a plane seating chart (13 rows × 6 columns, A–F).

- Most seats are **red (occupied)**. A few randomly flip **green (open)** for a limited time window
- Click a green seat before its timer expires to **claim it (grey)**
- Claimed seats stay grey and never reopen
- Clicking a red seat does nothing — no penalty
- **Win** by claiming enough seats before the game timer runs out
- **Fail** if the game timer expires without reaching the goal

| Level | Seats to Claim | Open Duration | Flip Interval | Time Limit |
|-------|---------------|---------------|---------------|------------|
| 1     | 3             | 2.0s          | 2.0s          | 30s        |
| 2     | 5             | 1.8s          | 1.6s          | 28s        |
| 3     | 7             | 1.5s          | 1.2s          | 25s        |
| 4     | 9             | 1.2s          | 0.9s          | 22s        |
| 5     | 11            | 1.0s          | 0.6s          | 20s        |

---

### 4. Jetski Dash
A side-scrolling survival game. Pilot your jetski through an obstacle-filled waterway.

- Rocks, buoys, and logs scroll in from the right at increasing speed
- Move up and down to dodge — controls: Arrow keys or WASD
- **Win** by surviving the full 20 seconds without a collision
- **Fail** immediately on any collision

| Level | Scroll Speed | Spawn Interval |
|-------|-------------|----------------|
| 1     | 3.5 px/f    | 2.0s           |
| 2     | 4.5 px/f    | 1.7s           |
| 3     | 5.5 px/f    | 1.4s           |
| 4     | 6.5 px/f    | 1.1s           |
| 5     | 8.0 px/f    | 0.8s           |

---

## File Structure

```
final/
├── main.rb              # Entry point — window, state machine, event routing, $keys_held
├── game_state.rb        # Shared mutable state (lives, level, minigame index/order)
├── base_minigame.rb     # Abstract base class all minigames inherit from
├── hearts.rb            # Lives HUD — 3 hearts visible throughout gameplay
├── start_screen.rb      # Title screen
├── transition_screen.rb # Instructions and status bar between minigames
├── success_screen.rb    # Shown after clearing all 5 levels 
├── failure_screen.rb    # Shown when all lives are lost
├── passwording.rb       # Minigame 1 — live regex password challenge
├── rock_climb.rb        # Minigame 2 — physics platformer
├── seat_scramble.rb     # Minigame 3 — plane seat whack-a-mole
├── jetski_dash.rb       # Minigame 4 — side-scrolling dodge game
├── directions.txt       # Directions to explain how to install language complier
├── collaboration.txt    # Discussion/Collaboration Log detailing our updates through out the term project
└── final_stats_screen.rb # Final Screen - summarizes which levels of minigame the user won and lost during your run

```

---

## Architecture

### State Machine (`main.rb`)
The game is always in exactly one of five states:

```
:start → :transition → :playing ──(win)──→ :transition → :playing → ... → :success
                            │
                         (fail, lives > 0) → :transition → next minigame
                            │
                         (fail, lives = 0) → :failure
```

A global `$keys_held` hash is maintained in `main.rb` — populated on `:key_down` and cleared on `:key_up`. `rock_climb.rb` and `jetski_dash.rb` poll this hash every frame for smooth continuous movement.

### Adding a New Minigame
1. Create a new `.rb` file with a class inheriting from `BaseMinigame`
2. Implement the four required methods: `start`, `update(dt)`, `handle_input(event)`, `cleanup`
3. Set `@completed = true` when the player wins, `@failed = true` when they lose
4. Add the class name as a symbol to `MINIGAME_CLASSES` in `game_state.rb`

### BaseMinigame Interface

| Method | Called by | Purpose |
|--------|-----------|---------|
| `start` | `main.rb` once | Build all Ruby2D objects, begin timers |
| `update(dt)` | `main.rb` every frame at 60fps | Tick timers, physics, update visuals |
| `handle_input(event)` | `main.rb` on keyboard/mouse events | Respond to player input |
| `cleanup` | `main.rb` on minigame exit | Remove every Ruby2D object from the window |

Two read-only flags on every minigame polled each frame by `main.rb`:
- `completed` — set `true` when the player wins
- `failed` — set `true` when the player loses

---

## CS Requirements — Where to Find Them

| Requirement | File(s) | Implementation |
|-------------|---------|----------------|
| **Dynamic list** | `seat_scramble.rb`, `rock_climb.rb`, `jetski_dash.rb`, `passwording.rb` | `@seats`, `@rocks`, `@obstacles`, `@active_rules` — grow with `<<`, shrink with `-=` or `delete_if` |
| **Hash table** | All four minigame files | `DIFFICULTY` hash-of-hashes keyed by level; per-object hashes for rocks/obstacles |
| **Iterative control structure** | All four minigame files | `.each`, `.select`, `.map`, `.all?`, `.any?`, `.count` used throughout every update loop |
| **Graphics** | All files | Ruby2D `Rectangle`, `Circle`, `Line`, `Square`, `Text` for all visuals |
| **Variable Parameter Structure** | `transition_screen.rb` | Accepts variable number of `@details` that will be displayed on the status bar |
