# main.rb
# Entry point and state machine for the Mini Games collection.
#
# Game states:
#   :start       — title screen, waiting for ENTER
#   :transition  — 3-second countdown between minigames
#   :playing     — a minigame is active
#   :success     — player cleared all 5 levels
#   :failure     — player ran out of lives
#
# Flow:
#   :start → :transition → :playing → (win) → :transition → :playing → ...
#                                   → (fail, lives > 0) → :transition → next
#                                   → (fail, lives == 0) → :failure

require 'ruby2d'
require 'set'

# ── Load all game files ───────────────────────────────────────────────────────
require_relative 'game_state'
require_relative 'hearts'
require_relative 'start_screen'
require_relative 'transition_screen'
require_relative 'success_screen'
require_relative 'failure_screen'
require_relative 'base_minigame'
require_relative 'seat_scramble'
#require_relative 'snowman'
require_relative 'rock_climb'

# ── Window ────────────────────────────────────────────────────────────────────
set title:      'Mini Games'
set width:      800
set height:     600
set background: 'black'
set fps_cap:    60

# ── Shared state & screen references ─────────────────────────────────────────
$gs             = GameState.new
$current_screen = nil
$current_game   = nil
$hearts         = nil
$last_time      = Time.now.to_f

# Global hash tracking which keys are currently held down.
# Populated by on :key_down, cleared by on :key_up.
# rock_climb.rb reads this every frame inside update to move the player.
$keys_held = {}

# ── State machine helpers ─────────────────────────────────────────────────────

def enter_start
  $gs.state       = :start
  $current_screen = StartScreen.new
end

def enter_transition
  $gs.state       = :transition
  $current_screen = TransitionScreen.new(
    $gs.minigame_name,
    $gs.level,
    $gs.minigame_index + 1,
    GameState::MINIGAME_CLASSES.length
  )
end

def enter_playing
  $gs.state     = :playing
  $current_screen = nil
  $current_game = $gs.current_minigame_class.new($gs.level)
  $current_game.start
end

def enter_success
  $gs.state       = :success
  $current_game   = nil
  $current_screen = SuccessScreen.new
end

def enter_failure
  $gs.state       = :failure
  $current_game   = nil
  $current_screen = FailureScreen.new
end

def handle_minigame_end(won:)
  $current_game.cleanup
  $current_game = nil

  unless won
    $gs.lose_life!
    $hearts.update($gs.lives_remaining)
    unless $gs.alive?
      enter_failure
      return
    end
  end

  result = $gs.advance_minigame!

  case result
  when :game_won  then enter_success
  when :level_up  then enter_transition
  when :next_game then enter_transition
  end
end

# ── Boot ─────────────────────────────────────────────────────────────────────
enter_start

# ── Update loop ───────────────────────────────────────────────────────────────
update do
  now = Time.now.to_f
  dt  = (now - $last_time).clamp(0.0, 0.1)
  $last_time = now

  case $gs.state

  when :transition
    result = $current_screen.update(dt)
    if result == :done
      $current_screen.cleanup
      $current_screen = nil
      $hearts ||= Hearts.new($gs.lives_remaining)
      enter_playing
    end

  when :playing
    $current_game.update(dt)

    if $current_game.completed
      handle_minigame_end(won: true)
    elsif $current_game.failed
      handle_minigame_end(won: false)
    end

  end
end

# ── Input routing ─────────────────────────────────────────────────────────────
on :key_down do |event|
  $keys_held[event.key] = true   # track held keys for rock_climb movement polling

  case $gs.state

  when :start
    result = $current_screen.handle_input(event)
    if result == :start_game
      $current_screen.cleanup
      $current_screen = nil
      $gs.reset!
      enter_transition
    end

  when :playing
    $current_game.handle_input(event)

  when :success, :failure
    result = $current_screen.handle_input(event)
    if result == :restart
      $current_screen.cleanup
      $current_screen = nil
      $hearts&.remove
      $hearts = nil
      $gs.reset!
      enter_start
    end

  end
end

on :key_up do |event|
  $keys_held.delete(event.key)   # clear held key so movement stops
  $current_game.handle_input(event) if $gs.state == :playing && $current_game
end

on :mouse_down do |event|
  $current_game.handle_input(event) if $gs.state == :playing && $current_game
end

# ── Show ──────────────────────────────────────────────────────────────────────
show