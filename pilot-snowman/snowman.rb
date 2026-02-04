# Bridget Thomson, Joe Koslosky, Alexandra Chase
# bmthom26@g.holycross.edu
# jrkosl26@g.holycross.du
# amchas26@g.holycross.edu
# 04 February 2026
# CSCI 324 - Programming Languages
# Snowman Variation of Hangman

# Read all words from file into an array
words = File.readlines("words.txt", chomp: true) # reads the file and removes newlines


# After selecting secret_word
secret_word = words.sample.downcase # Sample - picks a random word from the array
display = Array.new(secret_word.length, "_")


# Arrays for guessed letters and wrong guesses
guessed_letters = []
wrong_guesses = []
max_wrong = 6
# Snowman stages
def draw_snowman(wrong_count)
 snowman = [
   # Stage 0 - empty
   [
     "        ",
     "        ",
     "        ",
     "        ",
     "        ",
     "        ",
     "        ",
     "        "
   ],
   # Stage 1 - bottom
   [
     "          ",
     "          ",
     "          ",    
     "          ",
     "          ",
     "  ______  ",
     " |      | ",
     " |______| "
   ],
   # Stage 2 - middle
   [
     "          ",
     "          ",
     "          ",    
     "   ____   ",
     "  |    |  ",
     "  |____|  ",
     " |      | ",
     " |______| "
   ],
   # Stage 3 - top
   [
     "          ",
     "    __    ",
     "   |..|   ",    
     "   |__|   ",
     "  |    |  ",
     "  |____|  ",
     " |      | ",
     " |______| "
   ],
   # Stage 4 - hat
   [
     "    __    ",
     "  _|__|_  ",
     "   |..|   ",    
     "   |__|   ",
     "  |    |  ",
     "  |____|  ",
     " |      | ",
     " |______| "
   ],
   # Stage 5 - right arm
   [
     "    __    ",
     "  _|__|_  ",
     "   |..|   ",    
     "   |__|  /",
     "  |    |/ ",
     "  |____|  ",
     " |      | ",
     " |______| "
   ],
   # Stage 6 - left arm (complete)
   [
     "    __    ",
     "  _|__|_  ",
     "   |xx|   ",    
     "\\  |__|  /",
     " \\|    |/ ",
     "  |____|  ",
     " |      | ",
     " |______| "
   ]
 ]
  puts "\n=== SNOWMAN ==="
 snowman[wrong_count].each { |line| puts line }
 puts "===============\n"
end








# Initial display
puts "Welcome to Snowman!"
puts "You have #{max_wrong} wrong guesses before the snowman is complete!\n\n"
draw_snowman(0)
puts display.join(" ")  # Shows: _ _ _ _ _




# Game loop
loop do
  puts "\nGuess a letter:"
  guess = STDIN.gets.chomp.downcase  # get user input and convert to lowercase
 
  # Check if it's a single letter and not a symbol
  if guess.length != 1 || !guess.match?(/[a-z]/)
   puts "Please enter a single letter!"
   next
  end




 # Check if already guessed
if guessed_letters.include?(guess)
  puts "You already guessed that letter!"
  next
end




# Add to guessed letters
guessed_letters << guess




# Check if correct or wrong
if secret_word.include?(guess)
  puts "Correct!"
  secret_word.chars.each_with_index do |letter, index|
    if letter == guess
      display[index] = guess
    end
  end
else
  wrong_guesses << guess  # Add THIS first
  puts "Wrong guess! (#{wrong_guesses.length}/#{max_wrong})"
  draw_snowman(wrong_guesses.length)  # Then draw (and use .length here!)
 
  # Check if they lost
  if wrong_guesses.length >= max_wrong  # Add .length here too!
    puts "\nGame Over! The snowman is complete!"
    puts "The word was: #{secret_word}"
    break
  end
end


puts display.join(" ")
puts "Wrong guesses: #{wrong_guesses.join(", ")}" if wrong_guesses.any?
 
  # Check if they won
  if display.join == secret_word
    puts "You won!"
    break
  end
end
