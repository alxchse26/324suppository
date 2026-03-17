# screens/transition_screen.rb
# Shown between minigames for exactly 3 seconds.
# Displays the upcoming minigame name, level, and a live countdown.
# update(dt) must be called every frame; returns :done when countdown hits 0.

class TransitionScreen
  COUNTDOWN_SECONDS = 3.0

  def initialize(minigame_name, level, minigame_number, total_minigames)
    @minigame_name    = minigame_name
    @level            = level
    @minigame_number  = minigame_number
    @total_minigames  = total_minigames
    @elapsed          = 0.0
    @objects          = []
    @countdown_text   = nil
    draw
  end

  # dt in seconds. Returns :done when the countdown reaches 0.
  def update(dt)
    @elapsed += dt
    remaining = [COUNTDOWN_SECONDS - @elapsed, 0].max

    # Update the big countdown number
    display_num = (remaining.ceil).clamp(1, 3)
    @countdown_text.text = display_num.to_s if @countdown_text

    return :done if @elapsed >= COUNTDOWN_SECONDS
    nil
  end

  def cleanup
    @objects.each(&:remove)
    @objects.clear
  end

  private

  def draw
    # Semi-transparent overlay
    @objects << Rectangle.new(
      x: 0, y: 0,
      width: 800, height: 600,
      color: [0.0, 0.0, 0.1, 0.88]
    )

    # Level badge
    @objects << Rectangle.new(
      x: 320, y: 120,
      width: 160, height: 40,
      color: [0.2, 0.2, 0.8, 0.9]
    )
    @objects << Text.new(
      "LEVEL #{@level}  ·  #{@minigame_number} / #{@total_minigames}",
      x: 332, y: 128,
      size: 18,
      color: 'white'
    )

    # Minigame title
    @objects << Text.new(
      'Next Up:',
      x: 345, y: 185,
      size: 22,
      color: [0.6, 0.8, 1, 1]
    )
    @objects << Text.new(
      @minigame_name,
      x: 250, y: 220,
      size: 36,
      color: 'white'
    )

    # Divider line
    @objects << Line.new(
      x1: 200, y1: 275,
      x2: 600, y2: 275,
      width: 2,
      color: [0.4, 0.4, 0.8, 0.6]
    )

    # "Get Ready" prompt
    @objects << Text.new(
      'Get Ready...',
      x: 305, y: 295,
      size: 26,
      color: [0.9, 0.9, 0.4, 1]
    )

    # Big countdown number — stored so update() can mutate it
    @countdown_text = Text.new(
      '3',
      x: 375, y: 350,
      size: 80,
      color: 'white'
    )
    @objects << @countdown_text
  end
end
