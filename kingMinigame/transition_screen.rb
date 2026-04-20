# screens/transition_screen.rb
class TransitionScreen

  INSTRUCTIONS = {
    "Passwording" => [
      "Create a password that satisfies ALL rules.",
      "Rules update live as you type.",
      "Each round adds more rules.",
      "Complete all rules before time runs out."
    ],
    "Rock Climb" => [
      "Jump onto falling rocks to freeze them.",
      "Use frozen rocks as platforms.",
      "Climb to the gem at the top.",
      "Use W, A, and D or the arrow keys to move."
    ],
    "Jetski Dash" => [
      "Move with W and S or the arrow keys to dodge obstacles.",
      "Survive until the timer ends.",
      "Avoid rocks, logs, and buoys."
    ],
    "Seat Scramble" => [
      "Click green seats to claim them.",
      "Claim enough seats before time runs out.",
      "Red seats are blocked.",
      "Grey seats are already claimed."
    ]
  }.freeze

  def initialize(minigame_name, level, minigame_number, total_minigames)
    @minigame_name   = minigame_name
    @level           = level
    @minigame_number = minigame_number
    @total_minigames = total_minigames
    @ready           = false
    @objects         = []
    draw
  end

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
    @objects << Rectangle.new(
      x: 0, y: 0, width: 800, height: 600,
      color: [0.0, 0.0, 0.1, 0.88]
    )
    @objects << Rectangle.new(
      x: 320, y: 120, width: 160, height: 40,
      color: [0.2, 0.2, 0.8, 0.9]
    )
    @objects << Text.new(
      "LEVEL #{@level}  ·  #{@minigame_number} / #{@total_minigames}",
      x: 332, y: 128, size: 18, color: 'white'
    )
    @objects << Text.new('Next Up:', x: 345, y: 185, size: 22, color: [0.6, 0.8, 1, 1])
    @objects << Text.new(@minigame_name, x: 250, y: 220, size: 36, color: 'white')
    @objects << Line.new(x1: 200, y1: 275, x2: 600, y2: 275, width: 2, color: [0.4, 0.4, 0.8, 0.6])

    instructions = INSTRUCTIONS[@minigame_name] || ['Get ready!']
    instructions.each_with_index do |line, i|
      @objects << Text.new(line, x: 200, y: 295 + i * 28, size: 18, color: [0.85, 0.85, 0.95, 1])
    end

    @objects << Text.new(
      'Press ENTER when you are ready!',
      x: 220, y: 450, size: 24, color: 'lime'
    )
  end

end
