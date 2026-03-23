# minigames/snowman.rb
# Snowman (Hangman variant) adapted to the BaseMinigame interface.
#
# Difficulty scaling:
#   Level 1 — words up to 5 letters,    6 wrong guesses allowed, 90s
#   Level 2 — words up to 7 letters,    5 wrong guesses allowed, 75s
#   Level 3 — words up to 9 letters,    5 wrong guesses allowed, 60s
#   Level 4 — words up to 11 letters,   4 wrong guesses allowed, 50s
#   Level 5 — any word length,          4 wrong guesses allowed, 40s
#
# Win  → guess the full word before max_wrong is reached AND before time expires
# Fail → run out of wrong guesses OR time expires

class Snowman < BaseMinigame

  DIFFICULTY = {
    1 => { max_word_len: 5,  max_wrong: 6, time_limit: 90.0 },
    2 => { max_word_len: 7,  max_wrong: 5, time_limit: 75.0 },
    3 => { max_word_len: 9,  max_wrong: 5, time_limit: 60.0 },
    4 => { max_word_len: 11, max_wrong: 4, time_limit: 50.0 },
    5 => { max_word_len: 99, max_wrong: 4, time_limit: 40.0 },
  }.freeze

  DICTIONARY_PATH = File.join(__dir__, 'dictionary.txt')

  def initialize(difficulty_level)
    super
    cfg = DIFFICULTY[@difficulty_level]

    @max_wrong   = cfg[:max_wrong]
    @time_limit  = cfg[:time_limit]
    @game_timer  = @time_limit

    # Load word list filtered by length and valid characters
    all_words = File.readlines(DICTIONARY_PATH, chomp: true)
                    .select { |w| w.match?(/^[a-zA-Z'\-]+$/) }
                    .select { |w| w.length <= cfg[:max_word_len] }

    @secret_word     = all_words.sample.downcase
    @display         = Array.new(@secret_word.length, '_')
    @guessed_letters = []
    @wrong_guesses   = []
    @current_input   = ''
    @snowman_parts   = []   # Ruby2D objects making up the snowman drawing
    @ui_objects      = []
  end

  # ── BaseMinigame interface ────────────────────────────────────────────────

  def start
    build_ui
    draw_snowman(0)
  end

  def update(dt)
    return unless active?

    @game_timer -= dt
    if @game_timer <= 0
      @game_timer = 0
      @failed = true unless @completed
      @message_text.text  = "Time's up! Word: #{@secret_word}" if @failed
      @message_text.color = 'red'
    end

    # Keep timer display fresh
    @timer_text.text  = format('%.0fs', @game_timer.ceil)
    @timer_text.color = @game_timer <= 10 ? 'red' : 'aqua'
  end

  def handle_input(event)
    return unless active?
    return unless event.is_a?(Ruby2D::KeyEvent) && event.type == :down

    if event.key == 'backspace'
      @current_input = @current_input[0...-1]

    elsif event.key == 'return' || event.key == 'enter'
      process_guess(@current_input)
      @current_input = ''

    elsif event.key.length == 1 && event.key.match?(/[a-zA-Z'\-]/)
      @current_input += event.key if @current_input.length < 1
    end

    @input_display.text = "Input: #{@current_input}"
  end

  def cleanup
    @snowman_parts.each(&:remove)
    @snowman_parts.clear
    @ui_objects.each(&:remove)
    @ui_objects.clear
    super
  end

  # ── Private helpers ───────────────────────────────────────────────────────

  private

  def build_ui
    # Background
    bg = Rectangle.new(x: 0, y: 0, width: 800, height: 600, color: [0.04, 0.04, 0.15, 1.0])
    @ui_objects << bg

    # Title
    @ui_objects << Text.new('SNOWMAN', x: 320, y: 18, size: 38, color: 'white')

    # Instructions
    @ui_objects << Text.new(
      "Type a letter and press ENTER  |  Wrong allowed: #{@max_wrong}",
      x: 185, y: 68, size: 18, color: 'aqua'
    )

    # Word display
    @word_display = Text.new(
      @display.join(' '),
      x: word_display_x, y: 495,
      size: 32, color: 'white'
    )
    @ui_objects << @word_display

    # Wrong guesses
    @wrong_display = Text.new(
      'Wrong: ',
      x: 50, y: 548, size: 18, color: 'red'
    )
    @ui_objects << @wrong_display

    # Input display
    @input_display = Text.new(
      'Input: ',
      x: 340, y: 448, size: 24, color: 'yellow'
    )
    @ui_objects << @input_display

    # Message
    @message_text = Text.new(
      '',
      x: 240, y: 110, size: 24, color: 'lime'
    )
    @ui_objects << @message_text

    # Timer
    @ui_objects << Text.new('Time:', x: 680, y: 18, size: 18, color: [0.7, 0.7, 0.7, 1])
    @timer_text = Text.new(
      format('%.0fs', @game_timer),
      x: 680, y: 42, size: 26, color: 'aqua'
    )
    @ui_objects << @timer_text

    # Level indicator
    @ui_objects << Text.new(
      "Level #{@difficulty_level}",
      x: 30, y: 18, size: 18, color: [0.6, 0.6, 1.0, 1]
    )
  end

  def process_guess(guess)
    unless guess.length == 1 && guess.match?(/[a-zA-Z'\-]/)
      @message_text.text  = 'Enter a single letter, hyphen, or apostrophe!'
      @message_text.color = 'orange'
      return
    end

    guess = guess.downcase

    if @guessed_letters.include?(guess)
      @message_text.text  = 'Already guessed!'
      @message_text.color = 'yellow'
      return
    end

    @guessed_letters << guess

    if @secret_word.include?(guess)
      @message_text.text  = 'Correct!'
      @message_text.color = 'lime'

      # Reveal matching positions using each_with_index — classic Ruby iteration
      @secret_word.chars.each_with_index do |letter, index|
        @display[index] = guess if letter == guess
      end
      @word_display.text = @display.join(' ')
      @word_display.x    = word_display_x   # re-center if length changed visually

      if @display.join == @secret_word
        @message_text.text  = 'YOU GOT IT! 🎉'
        @message_text.color = 'gold'
        @completed = true
      end
    else
      @wrong_guesses << guess

      # Sort wrong guesses alphabetically for clean display
      @wrong_display.text = "Wrong: #{@wrong_guesses.sort.join(', ')}"

      @message_text.text  = "Wrong! (#{@wrong_guesses.length}/#{@max_wrong})"
      @message_text.color = 'red'

      draw_snowman(@wrong_guesses.length)

      if @wrong_guesses.length >= @max_wrong
        @message_text.text  = "MELTED! Word: #{@secret_word}"
        @message_text.color = 'red'
        @failed = true
      end
    end
  end

  # Center the word display based on how many characters are revealed
  def word_display_x
    chars  = @display.length
    approx = chars * 22   # rough pixel width per spaced character at size 32
    [400 - approx / 2, 50].max
  end

  # ── Snowman drawing (same logic as original, now instance-based) ──────────

  def draw_snowman(wrong_count)
    @snowman_parts.each(&:remove)
    @snowman_parts.clear

    # Use a lookup structure so each threshold adds its own parts declaratively.
    # Array of [min_wrong, lambda_that_draws_parts]
    part_layers = [
      [1, -> { [Circle.new(x: 400, y: 400, radius: 60, color: 'white')] }],
      [2, -> { [Circle.new(x: 400, y: 300, radius: 50, color: 'white')] }],
      [3, -> { [Circle.new(x: 400, y: 210, radius: 40, color: 'white')] }],
      [4, -> {
        [
          Circle.new(x: 390, y: 200, radius: 5, color: 'black'),
          Circle.new(x: 410, y: 200, radius: 5, color: 'black'),
          Circle.new(x: 400, y: 300, radius: 4, color: 'black'),
          Circle.new(x: 400, y: 320, radius: 4, color: 'black'),
        ]
      }],
      [5, -> {
        [
          Rectangle.new(x: 370, y: 150, width: 60, height: 20, color: 'black'),
          Rectangle.new(x: 380, y: 130, width: 40, height: 20, color: 'black'),
        ]
      }],
    ]

    # select_map: select layers up to current wrong count, then flatten the parts
    # Demonstrates Ruby's chained enumerable methods on a structured data list
    new_parts = part_layers
                  .select { |min_wrong, _| wrong_count >= min_wrong }
                  .flat_map { |_, draw_fn| draw_fn.call }

    @snowman_parts.concat(new_parts)

    # On the final wrong guess — dead eyes replace normal eyes
    if wrong_count >= 6
      # Arms
      @snowman_parts << Rectangle.new(x: 340, y: 310, width: 50, height: 4, color: 'brown')
      @snowman_parts << Rectangle.new(x: 410, y: 310, width: 50, height: 4, color: 'brown')

      # Remove the normal eye circles
      @snowman_parts.reject! { |part| part.is_a?(Circle) && part.radius == 5 }

      # Draw X eyes
      [
        [385, 195, 395, 205], [395, 195, 385, 205],   # left X
        [405, 195, 415, 205], [415, 195, 405, 205],   # right X
      ].each do |x1, y1, x2, y2|
        @snowman_parts << Line.new(x1: x1, y1: y1, x2: x2, y2: y2, width: 3, color: 'red')
      end
    end
  end
end
