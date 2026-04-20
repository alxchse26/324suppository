# transition_screen.rb
# Shown between minigames. Player advances at their own pace by pressing ENTER.
# Displays a status report (won/lost, reason, lives left), next minigame info,
# how to play it, and draws the current heart count.

class TransitionScreen

  # Descriptions of how to play each minigame — keyed by the exact name string
  # produced by GameState#minigame_name so no extra plumbing is needed.
  HOW_TO_PLAY = {
    'Passwording'   => 'Type a password that satisfies all rules shown. Rules are checked live on every keystroke.',
    'Rock Climb'    => 'Jump on falling rocks to freeze them into platforms. Reach the gem at the top to win. WASD or arrow keys.',
    'Seat Scramble' => 'Click the GREEN seats before they close. Claim enough seats before time runs out.',
    'Jetski Dash'   => 'Dodge rocks, buoys, and logs scrolling in from the right. Survive the full timer. WASD or arrow keys.',
    'Snowman'       => 'Guess the hidden word one letter at a time before the snowman is complete.',
  }.freeze

  # ── build_status_message — variadic method ────────────────────────────────
  # Accepts a required `won` boolean and any number of optional keyword details.
  # Demonstrates a method with variable numbers of parameters via **details splat.
  # Callers can pass: reason:, lives:, minigame: — or any subset, or none.
  # The method composes a human-readable status string from whatever it receives.
  def build_status_message(won, **details)
    reason   = details[:reason]   || (won ? 'completed the challenge' : 'time ran out')
    lives    = details[:lives]
    minigame = details[:minigame]

    if won
      lines = ["Congrats, you won this round!"]
      lines << "You completed #{minigame}." if minigame
    else
      lines = ["Sorry, you lost a life."]
      lines << "Reason: #{reason}."
    end

    lines << "You have #{lives} #{lives == 1 ? 'life' : 'lives'} left." if lives
    lines << (won ? 'Keep it up!' : 'Good luck.')
    lines
  end

  def initialize(minigame_name, level, minigame_number, total_minigames,
                 won: true, lives: 3, fail_reason: nil)
    @minigame_name   = minigame_name
    @level           = level
    @minigame_number = minigame_number
    @total_minigames = total_minigames
    @won             = won
    @lives           = lives
    @fail_reason     = fail_reason
    @ready           = false
    @objects         = []
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

    draw_status_panel unless @minigame_number == 1
    draw_hearts
    draw_divider(y: 230)
    draw_next_up
    draw_divider(y: 430)
    draw_continue_prompt
  end

  # ── Status panel (top section) ────────────────────────────────────────────
  def draw_status_panel
    # Call variadic method — passing reason and lives as keyword args
    reason = @won ? nil : (@fail_reason || 'time ran out')
    lines  = build_status_message(
      @won,
      reason:   reason,
      lives:    @lives,
      minigame: nil   # omit minigame name here; it appears in "Next Up" below
    )

    panel_color = @won ? [0.0, 0.18, 0.05, 0.85] : [0.18, 0.03, 0.03, 0.85]
    @objects << Rectangle.new(x: 40, y: 18, width: 720, height: 100, color: panel_color)

    header_color = @won ? 'lime' : 'red'
    @objects << Text.new(lines[0], x: 60, y: 26,  size: 22, color: header_color)
    @objects << Text.new(lines[1], x: 60, y: 56,  size: 17, color: 'white')   if lines[1]
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
    # Level badge
    @objects << Rectangle.new(x: 320, y: 242, width: 160, height: 36,
                               color: [0.2, 0.2, 0.8, 0.9])
    @objects << Text.new(
      "LEVEL #{@level}  ·  #{@minigame_number} / #{@total_minigames}",
      x: 332, y: 250, size: 17, color: 'white'
    )

    @objects << Text.new('Next Up:', x: 345, y: 292, size: 20, color: [0.6, 0.8, 1, 1])
    @objects << Text.new(@minigame_name, x: 250, y: 318, size: 34, color: 'white')

    # How to play description
    desc = HOW_TO_PLAY[@minigame_name] || 'Get ready!'
    draw_wrapped_text(desc, x: 60, y: 366, max_width: 680, size: 15,
                      color: [0.75, 0.85, 1.0, 1])
  end

  # ── Continue prompt (bottom) ──────────────────────────────────────────────
  def draw_continue_prompt
    @objects << Text.new(
      'Press  ENTER  when you are ready',
      x: 240, y: 448, size: 22, color: 'lime'
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
