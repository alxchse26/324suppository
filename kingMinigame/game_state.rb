# game_state.rb
# Single shared object passed around the whole game.
# Owns lives, current level (1-5), and which minigame index we are on.
# Using a plain Ruby struct keeps all mutable state in one place.

class GameState
  TOTAL_LEVELS    = 5
  MAX_LIVES       = 3

  # Minigame classes are registered here in order.
  # Add new minigame classes to this array as they are built.
  MINIGAME_CLASSES = [
    # SeatScramble is required below in main.rb after all files are loaded
    # so we reference them by name (symbol resolved at runtime via const_get)
  
    :JetskiDash,
    :SeatScramble,
    :Passwording,
    :RockClimb
  
  ].freeze

  attr_accessor :lives, :level, :minigame_index, :state, :pending_message

  def initialize
    reset!
  end

  # Full reset — used by failure screen "try again"
  def reset!
    @lives           = MAX_LIVES
    @level           = 1
    @minigame_index  = 0
    @state           = :start        # :start | :transition | :playing | :success | :failure
    @pending_message = nil
  end

  # Resolve the current minigame class from the symbol list
  def current_minigame_class
    Object.const_get(MINIGAME_CLASSES[@minigame_index])
  end

  # Advance to the next minigame; if all done, bump the level
  # Returns :next_game | :level_up | :game_won
  def advance_minigame!
    @minigame_index += 1
    if @minigame_index >= MINIGAME_CLASSES.length
      @minigame_index = 0
      @level += 1
      return @level > TOTAL_LEVELS ? :game_won : :level_up
    end
    :next_game
  end

  def lose_life!
    @lives -= 1
  end

  def alive?
    @lives > 0
  end

  def lives_remaining
    @lives
  end

  # Human-readable label for the current minigame
  def minigame_name
    MINIGAME_CLASSES[@minigame_index].to_s
      .gsub(/([A-Z])/, ' \1').strip   # CamelCase -> "Camel Case"
  end
end
