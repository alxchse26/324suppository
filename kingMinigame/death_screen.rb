# death_screen.rb
# Shown when the player loses a life. Explains why and waits for ENTER.

class DeathScreen
  def initialize(reason, lives_remaining)
    @reason = reason
    @lives  = lives_remaining
    @ready  = false
    @objects = []
    draw
  end

  def update(dt)
    return :done if @ready
    nil
  end

  def handle_input(event)
    return unless event.respond_to?(:key)
    @ready = true if event.key == 'return' || event.key == 'enter'
  end

  def cleanup
    @objects.each(&:remove)
    @objects.clear
  end

  private

  def draw
    @objects << Rectangle.new(
      x: 0, y: 0, width: 800, height: 600,
      color: [0.15, 0.0, 0.0, 0.92]
    )
    @objects << Text.new('YOU LOST A LIFE', x: 240, y: 160, size: 36, color: 'red')
    @objects << Text.new("Reason: #{@reason}", x: 200, y: 240, size: 22, color: 'white')
    @objects << Text.new(
      "Lives remaining: #{@lives}",
      x: 280, y: 290, size: 20,
      color: @lives > 1 ? 'yellow' : 'red'
    )
    @objects << Text.new(
      'Press ENTER to continue',
      x: 255, y: 400, size: 22, color: 'lime'
    )
  end
end
