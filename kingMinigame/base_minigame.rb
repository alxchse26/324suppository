# base_minigame.rb
# Abstract base class that all minigames inherit from.
# Every minigame must implement: start, update(dt), handle_input(event), cleanup
# main.rb only ever calls these four methods + reads the two flag attributes.

class BaseMinigame
  attr_reader :completed, :failed

  def initialize(difficulty_level)
    @difficulty_level = difficulty_level.clamp(1, 5)
    @completed = false
    @failed    = false
    @objects   = []   # all Ruby2D objects — subclasses push into this for easy cleanup
  end

 # Called once when the minigame becomes active
def start
  raise NotImplementedError, "#{self.class} must implement #start"
end
# Called every frame by the Ruby2D update block. dt = seconds since last frame.
def update(dt)
  raise NotImplementedError, "#{self.class} must implement #update"
end
# Called for every Ruby2D input event while this minigame is active
def handle_input(event)
  raise NotImplementedError, "#{self.class} must implement #handle_input"
end
# Called when transitioning away — must remove every Ruby2D object created
def cleanup
  raise NotImplementedError, "#{self.class} must implement #cleanup"
end

  # Called when transitioning away — must remove every Ruby2D object created
  def cleanup
    @objects.each(&:remove)
    @objects.clear
  end

  # Convenience: is the minigame still running?
  def active?
    !@completed && !@failed
  end

  private

  # Subclasses call this to register Ruby2D objects for automatic cleanup
  def track(*ruby2d_objects)
    @objects.concat(ruby2d_objects.flatten)
    ruby2d_objects.flatten.first   # return the object so callers can assign + track in one line
  end
end
