# transition_screen.rb
# Shown between minigames. Player advances at their own pace by pressing ENTER.
# Displays a status report (won/lost, reason, lives left), next minigame info,
# how to play it, and draws the current heart count.

class TransitionScreen

  # Descriptions of how to play each minigame — keyed by the exact name string
  # produced by GameState#minigame_name so no extra plumbing is needed.
  HOW_TO_PLAY = {
  'Passwording' => [
    "You're a hacker trying to crack the ultimate password!",
    "Type into the box and watch the rules on screen.",
    "Each rule gets a green checkmark when satisfied.",
    "Satisfy ALL rules at the same time to win!",
    "Tip: Your password is checked automatically as you type."
  ],
  'Rock Climb' => [
    "You're a PL student practicing for your rock climbing adventure with your classmates and Professor King.", 
    "Your goal is to reach the gold star at the top! (Maybe you will get a extra credit on the final)",
    "Rocks fall from above — jump ON TOP of them to freeze them in place.",
    "Use frozen rocks as stepping stones to climb higher.",
    "Move left and right with A/D or arrow keys.",
    "Press SPACE, W, or UP arrow to jump.",
    "Tip: Once you land on a platform, it freezes and you can move horizontally off the rock!"
  ],
  'Seat Scramble' => [
    "You just boarded the airplane trying to grab the best seats, in first class of course!",
    "GREEN seats are available — click them fast before they disappear!",
    "RED seats are already taken — clicking them does nothing.",
    "GREY seats are ones you have already claimed.",
    "Claim enough seats before the timer runs out to win!",
    "Tip: Seats flip between available and taken quickly, stay alert!"
  ],
  'Jetski Dash' => [
    "You're racing a jetski through dangerous waters!",
    "Rocks, buoys, and logs scroll in fast from the right.",
    "Move UP and DOWN with W/S or the arrow keys to dodge them.",
    "Survive until the timer hits zero to win!",
    "Tip: The obstacles get faster every level, keep your eyes on the ocean!"
  ],
  'Snowman' => [
    "Guess the hidden word one letter at a time.",
    "Before the snowman is complete!"
  ]
}.freeze

  # Loss reasons for each minigame
  LOSS_REASONS = {
    'Passwording'   => "You didn't come up with an appropriate password in time.",
    'Rock Climb'    => "You didn't reach the gem.",
    'Seat Scramble' => "You didn't select enough seats.",
    'Jetski Dash'   => "You hit an object.",
    'Snowman'       => "The snowman was completed.",
  }.freeze

  # ── build_status_message — variadic method ────────────────────────────────
  # Accepts a required `won` boolean and any number of optional keyword details.
  # Demonstrates a method with variable numbers of parameters via **details splat.
  # Callers can pass: reason:, lives:, minigame: — or any subset, or none.
  # The method composes a human-readable status string from whatever it receives.
  def build_status_message(won, **details)
    minigame = details[:minigame]
    lives    = details[:lives]
    
    # For losses, use minigame-specific reason if available; otherwise use provided reason
    if !won
      reason = LOSS_REASONS[minigame] || details[:reason]
    end

    if won
      lines = ["Congrats, you won this round!"]
    else
      lines = ["Sorry, you lost a life."]
      lines << "Reason: #{reason}."
    end

    lines << "You have #{lives} #{lives == 1 ? 'life' : 'lives'} left." if lives
    lines << (won ? 'Keep it up!' : 'Good luck.')
    lines
  end

  def initialize(minigame_name, level, minigame_number, total_minigames,
                 won: true, lives: 3, fail_reason: nil, previous_minigame: nil)
    @minigame_name    = minigame_name
    @level            = level
    @minigame_number  = minigame_number
    @total_minigames  = total_minigames
    @won              = won
    @lives            = lives
    @fail_reason      = fail_reason
    @previous_minigame = previous_minigame
    @ready            = false
    @objects          = []
    draw
  end

  # update is called every frame by main.rb while in :transition state.
  # Timer-based auto-advance is removed — we wait for handle_input to set @ready.
  def update(dt)
    return :done if @ready
    nil
  end

  def handle_input(event)
    return unless event.respond_to?(:key)
    if event.key == 'return' || event.key == 'enter'
      @ready = true
    end
  end

  def cleanup
    @objects.each(&:remove)
    @objects.clear
  end

  private

  def draw
    # Background overlay
    @objects << Rectangle.new(
      x: 0, y: 0, width: 800, height: 600,
      color: [0.0, 0.0, 0.1, 0.92]
    )

    draw_status_panel unless @minigame_number == 1 && @won
    draw_hearts
    draw_divider(y: 130)
    draw_next_up
    draw_divider(y: 500)
    draw_continue_prompt
  end

  # ── Status panel (top section) ────────────────────────────────────────────
  def draw_status_panel
    # Call variadic method — passing reason and lives as keyword args
    reason = @won ? nil : (@fail_reason || 'time ran out')
    # For loss reasons, use the previous minigame (the one they just lost)
    loss_minigame = @won ? @minigame_name : (@previous_minigame || @minigame_name)
    lines  = build_status_message(
      @won,
      reason:   reason,
      lives:    @lives,
      minigame: loss_minigame
    )

    panel_color = @won ? [0.0, 0.18, 0.05, 0.85] : [0.18, 0.03, 0.03, 0.85]
    @objects << Rectangle.new(x: 40, y: 18, width: 720, height: 100, color: panel_color)

    header_color = @won ? 'lime' : 'red'
    @objects << Text.new(lines[0], x: 60, y: 26,  size: 22, color: header_color)
    @objects << Text.new(lines[1], x: 60, y: 56,  size: 14, color: 'white')   if lines[1]
    @objects << Text.new(lines[2], x: 60, y: 80,  size: 17, color: [0.8, 0.8, 0.8, 1]) if lines[2]
    @objects << Text.new(lines[3], x: 60, y: 100, size: 15, color: [0.6, 0.6, 1.0, 1]) if lines[3]
  end

  # ── Heart display on transition screen ────────────────────────────────────
  def draw_hearts
    label_x = 530
    heart_x  = 620
    @objects << Text.new('Lives:', x: label_x, y: 50, size: 18, color: [0.7, 0.7, 0.7, 1])

    3.times do |i|
      cx = heart_x + i * 38
      cy = 62
      color = i < @lives ? 'red' : [0.25, 0.25, 0.25, 0.5]
      @objects << Circle.new(x: cx - 7,  y: cy - 4, radius: 9,  color: color)
      @objects << Circle.new(x: cx + 7,  y: cy - 4, radius: 9,  color: color)
      @objects << Square.new(x: cx - 9,  y: cy - 2, size: 13,   color: color)
    end
  end

  # ── Next up section (middle) ──────────────────────────────────────────────
  def draw_next_up
  # Level badge — moved up
  @objects << Rectangle.new(x: 320, y: 140, width: 160, height: 36,
                             color: [0.2, 0.2, 0.8, 0.9])
  @objects << Text.new(
    "LEVEL #{@level}  ·  #{@minigame_number} / #{@total_minigames}",
    x: 332, y: 148, size: 17, color: 'white'
  )
  @objects << Text.new('Next Up:', x: 345, y: 188, size: 20, color: [0.6, 0.8, 1, 1])
  @objects << Text.new(@minigame_name, x: 250, y: 210, size: 34, color: 'white')

  # Draw each instruction line separately starting lower
  lines = HOW_TO_PLAY[@minigame_name] || ['Get ready!']
  lines.each_with_index do |line, i|
    @objects << Text.new(
      line,
      x: 60, y: 265 + i * 24,
      size: 14,
      color: i == lines.length - 1 ? [1.0, 0.9, 0.4, 1] : [0.75, 0.85, 1.0, 1]
    )
  end
end

  # ── Continue prompt (bottom) ──────────────────────────────────────────────
  def draw_continue_prompt
    @objects << Text.new(
      'Press  ENTER  when you are ready',
      x: 240, y: 520, size: 22, color: 'lime'
    )
  end

  # ── Horizontal divider helper ─────────────────────────────────────────────
  def draw_divider(y:)
    @objects << Line.new(x1: 40, y1: y, x2: 760, y2: y,
                         width: 1, color: [0.35, 0.35, 0.65, 0.7])
  end

  # ── Simple word-wrap for the how-to-play description ─────────────────────
  # Splits the description into lines of roughly max_width pixels and draws each.
  # Approximates character width at ~7px per char at size 15.
  def draw_wrapped_text(text, x:, y:, max_width:, size:, color:)
    chars_per_line = (max_width / 7).to_i
    words          = text.split(' ')
    lines          = []
    current        = ''

    words.each do |word|
      test = current.empty? ? word : "#{current} #{word}"
      if test.length <= chars_per_line
        current = test
      else
        lines << current unless current.empty?
        current = word
      end
    end
    lines << current unless current.empty?

    lines.each_with_index do |line, i|
      @objects << Text.new(line, x: x, y: y + i * (size + 4), size: size, color: color)
    end
  end

end
