# Bridget Thomson, Joe Koslosky, Alexandra Chase
# bmthom26@g.holycross.edu
# jrkosl26@g.holycross.du
# amchas26@g.holycross.edu
# Last Modified: 16 February 2026
# CSCI 324 - Programming Languages
# Snowman Variation of Hangman

require 'ruby2d'

# Window setup
set title: "Snowman Game"
set width: 800
set height: 600
set background: 'navy'

# Game variables - CHANGED to instance variables (@)
words = File.readlines("words.txt", chomp: true)
@secret_word = words.sample.downcase
@display = Array.new(@secret_word.length, "_")
@guessed_letters = []
@wrong_guesses = []
@max_wrong = 6
@game_over = false
@won = false
@words = words  # Store for reset

# Input buffer
@current_input = ""

# Track snowman parts so we can remove them
@snowman_parts = []

# Title
title = Text.new(
  @secret_word,
  x: 260, y: 20,
  size: 40,
  color: 'white'
)

# Instructions
instructions = Text.new(
  'Type a letter and press ENTER to submit your guess!',
  x: 165, y: 70,
  size: 20,
  color: 'aqua'
)

# Display word
@word_display = Text.new(
  @display.join(" "),
  x: 300, y: 500,
  size: 30,
  color: 'white'
)

# Wrong guesses display
@wrong_display = Text.new(
  "All Guesses: #{@wrong_guesses.join(', ')}",
  x: 50, y: 550,
  size: 20,
  color: 'red'
)

# Victory/Game Over screen elements (hidden initially)
@victory_overlay = Rectangle.new(
  x: 0, y: 0,
  width: 800, height: 600,
  color: [0, 0, 0, 0.8],
  z: 10
)
@victory_overlay.remove

@victory_text = Text.new(
  '',
  x: 200, y: 250,
  size: 60,
  color: 'white',
  z: 11
)
@victory_text.remove

@play_again_text = Text.new(
  'Press SPACE to play again or ESC to quit',
  x: 180, y: 350,
  size: 20,
  color: 'white',
  z: 11
)
@play_again_text.remove

# Draw snowman with circles
def draw_snowman(wrong_count)
  # Remove previous snowman parts
  @snowman_parts.each(&:remove)
  @snowman_parts.clear
  
  # Draw based on wrong count
  if wrong_count >= 1
    # Bottom circle (body)
    @snowman_parts << Circle.new(x: 400, y: 400, radius: 60, color: 'white')
  end
  
  if wrong_count >= 2
    # Middle circle (body)
    @snowman_parts << Circle.new(x: 400, y: 300, radius: 50, color: 'white')
  end
  
  if wrong_count >= 3
    # Top circle (head)
    @snowman_parts << Circle.new(x: 400, y: 210, radius: 40, color: 'white')
  end
  
  if wrong_count >= 4
    # Eyes
    @snowman_parts << Circle.new(x: 390, y: 200, radius: 5, color: 'black')
    @snowman_parts << Circle.new(x: 410, y: 200, radius: 5, color: 'black')
    # Buttons
    @snowman_parts << Circle.new(x: 400, y: 300, radius: 4, color: 'black')
    @snowman_parts << Circle.new(x: 400, y: 320, radius: 4, color: 'black')
  end
  
  if wrong_count >= 5
    # Hat (using rectangles)
    @snowman_parts << Rectangle.new(x: 370, y: 150, width: 60, height: 20, color: 'black')
    @snowman_parts << Rectangle.new(x: 380, y: 130, width: 40, height: 20, color: 'black')
  end
  
  if wrong_count >= 6
    # Arms (using rectangles as lines)
    @snowman_parts << Rectangle.new(x: 340, y: 310, width: 50, height: 4, color: 'brown')
    @snowman_parts << Rectangle.new(x: 410, y: 310, width: 50, height: 4, color: 'brown')
    
    # Replace eyes with X's (dead)
    @snowman_parts.delete_if { |part| part.is_a?(Circle) && part.radius == 5 }
    
    # Draw X eyes (using small lines/rectangles)
    # Left eye X
    @snowman_parts << Line.new(x1: 385, y1: 195, x2: 395, y2: 205, width: 3, color: 'red')
    @snowman_parts << Line.new(x1: 395, y1: 195, x2: 385, y2: 205, width: 3, color: 'red')
    # Right eye X
    @snowman_parts << Line.new(x1: 405, y1: 195, x2: 415, y2: 205, width: 3, color: 'red')
    @snowman_parts << Line.new(x1: 415, y1: 195, x2: 405, y2: 205, width: 3, color: 'red')
  end
end

# Function to reset the game
def reset_game
  @snowman_parts.each(&:remove)
  @snowman_parts.clear
  
  @secret_word = @words.sample.downcase
  @display = Array.new(@secret_word.length, "_")
  @guessed_letters = []
  @wrong_guesses = []
  @game_over = false
  @won = false
end

# Input display
@input_display = Text.new(
  "Input: #{@current_input}",
  x: 350, y: 450,
  size: 25,
  color: 'yellow'
)

# Message display
@message = Text.new(
  '',
  x: 250, y: 100,
  size: 25,
  color: 'lime'
)

# Initial snowman (empty)
draw_snowman(0)

# Handle keyboard input
on :key_down do |event|
  # Check for quit
  if event.key == 'escape'
    close
  end
  
  # Check for restart after game over
  if @game_over && event.key == 'space'
    # Reset game
    reset_game
    
    # Reset displays
    @word_display.text = @display.join(" ")
    @wrong_display.text = "Wrong: "
    @message.text = ''
    @current_input = ""
    @input_display.text = "Input: "
    
    # Hide victory screen
    @victory_overlay.remove
    @victory_text.remove
    @play_again_text.remove
    
    draw_snowman(0)
  end
  
  unless @game_over
    if event.key == 'backspace'
      @current_input = @current_input[0...-1]
    elsif event.key == 'return' || event.key == 'enter'
      # Process the guess
      guess = @current_input.downcase
      
      # Now accepts letters, hyphens, and apostrophes
      if guess.length == 1 && guess.match?(/[a-z'\-]/)
        if @guessed_letters.include?(guess)
          @message.text = "Already guessed!"
          @message.color = 'yellow'
        elsif @secret_word.include?(guess)
          @message.text = "Correct!"
          @message.color = 'lime'
          @guessed_letters << guess
          
          # Update display
          @secret_word.chars.each_with_index do |letter, index|
            @display[index] = guess if letter == guess
          end
          @word_display.text = @display.join(" ")
          
          # Check win
          if @display.join == @secret_word
            # Show victory screen instead of closing
            @game_over = true
            @won = true
            
            # Show victory overlay
            @victory_overlay.add
            @victory_text.text = "YOU WON! 🎉"
            @victory_text.color = 'white'
            @victory_text.add
            @play_again_text.add
            
            @message.text = "The word was: #{@secret_word}"
            @message.color = 'white'
          end
        else
          @wrong_guesses << guess
          @guessed_letters << guess
          @message.text = "Wrong! (#{@wrong_guesses.length}/#{@max_wrong})"
          @message.color = 'red'
          @wrong_display.text = "Wrong: #{@wrong_guesses.join(', ')}"
          
          draw_snowman(@wrong_guesses.length)
          
          # Check loss
          if @wrong_guesses.length >= @max_wrong
            # Show game over screen
            @game_over = true
            
            # Show game over overlay
            @victory_overlay.add
            @victory_text.text = "GAME OVER!"
            @victory_text.color = 'red'
            @victory_text.add
            @play_again_text.add
            
            @message.text = "The word was: #{@secret_word}"
            @message.color = 'red'
          end
        end
      else
        @message.text = "Enter a letter, hyphen, or apostrophe!"
        @message.color = 'orange'
      end
      
      @current_input = ""
    # Now accepts hyphens and apostrophes as input
    elsif event.key.length == 1 && event.key.match?(/[a-z'\-]/i)
      @current_input += event.key if @current_input.length < 1
    end
    
    @input_display.text = "Input: #{@current_input}"
  end
end

# Show the window
show
