# rock_climb.rb
# "Rock Climb" — a platformer where falling rocks ARE the platforms.
#
# The player starts on a static ledge at the bottom. Rocks fall from the top
# of the screen. The player must jump up and land ON TOP of rocks to freeze
# them in place, then use them as stepping stones to reach the gem at the top.
#
# Win  → player reaches the gem at the top of the screen
# Fail → player falls off the bottom OR a rock lands on the player from above

class RockClimb < BaseMinigame

  # ── Constants ────────────────────────────────────────────────────────────────

  PLAYER_W       = 28
  PLAYER_H       = 36
  PLAYER_START_X = 386
  PLAYER_START_Y = 490    # sits on top of the starting platform

  ROCK_W         = 70     # rocks are wide enough to land on
  ROCK_H         = 20
  JUMP_FORCE     = -12    # initial upward velocity on jump (negative = up)
  GRAVITY        = 0.5    # downward acceleration per frame
  MOVE_SPEED     = 5      # horizontal pixels per frame

  GROUND_Y       = 526    # top of the starting platform
  DEATH_Y        = 610    # fall below this = lose a life

  GEM_W          = 30
  GEM_H          = 30
  GEM_X          = 385
  GEM_Y          = 40

  PLAY_LEFT      = 10
  PLAY_RIGHT     = 790

  # ── Colours ──────────────────────────────────────────────────────────────────

  COLOR_SKY        = [0.05, 0.03, 0.12, 1.0]
  COLOR_CLIFF      = [0.10, 0.05, 0.01, 1.0]
  COLOR_PLAYER     = [1.0,  0.42, 0.21, 1.0]
  COLOR_HEAD       = [1.0,  0.80, 0.65, 1.0]
  COLOR_ROCK       = [0.55, 0.41, 0.08, 1.0]
  COLOR_FROZEN     = [0.40, 0.55, 0.65, 1.0]   # rock turns blue-grey when frozen
  COLOR_PLATFORM   = [0.35, 0.25, 0.10, 1.0]   # starting platform
  COLOR_GEM        = [1.0,  0.82, 0.0, 1.0]
  COLOR_WHITE      = [1.0,  1.0,  1.0,  1.0]
  COLOR_WALL_LINE  = [1.0,  1.0,  1.0,  0.04]

  # ── Difficulty scaling table — Built-in Hash Table ───────────────────────────
  # Key   => level (1-5)
  # Value => Hash of gameplay parameters
  #   :rock_speed     — pixels per frame rocks fall (before freezing)
  #   :spawn_interval — seconds between new rocks appearing
  #   :game_duration  — seconds the player has to reach the gem
  DIFFICULTY = {
    1 => { rock_speed: 1.5, spawn_interval: 2.2, game_duration: 60.0 },
    2 => { rock_speed: 2.0, spawn_interval: 1.8, game_duration: 50.0 },
    3 => { rock_speed: 2.5, spawn_interval: 1.5, game_duration: 42.0 },
    4 => { rock_speed: 3.0, spawn_interval: 1.2, game_duration: 35.0 },
    5 => { rock_speed: 3.5, spawn_interval: 1.0, game_duration: 28.0 },
  }.freeze

  # ── Control mappings — Regular Expression Mapping ────────────────────────────
  # Regex patterns map key name strings to action symbols.
  # One pattern covers multiple equivalent keys (arrow + WASD) without duplication.
  CONTROL_MAP = {
    /^(up|w|space)$/i => :jump,
    /^(left|a)$/i     => :move_left,
    /^(right|d)$/i    => :move_right,
  }.freeze

  # ── Constructor ──────────────────────────────────────────────────────────────

  def initialize(difficulty_level)
    super
    
    @all_rock_shapes = []
    cfg = DIFFICULTY[@difficulty_level]
    @rock_speed     = cfg[:rock_speed]
    @spawn_interval = cfg[:spawn_interval]
    @game_timer     = cfg[:game_duration]

    # ── Dynamic list of rocks ─────────────────────────────────────────────────
    # Each element is a Hash:
    #   :shape   => Ruby2D Rectangle
    #   :speed   => Float (pixels/frame downward, 0 if frozen)
    #   :frozen  => Boolean (true once player lands on top)
    #   :type    => 'rock' (tag for future extensibility)
    # Grows on spawn (<<), shrinks when rocks exit the screen (-=)
    @rocks = []

    # Player physics state
    @vel_x      = 0.0    # horizontal velocity (set per frame from held keys)
    @vel_y      = 0.0    # vertical velocity (affected by gravity and jumps)
    @on_ground  = false  # true when standing on a platform or frozen rock

    # Timers
    @spawn_timer      = 0.0
    @invincible       = false
    @invincible_timer = 0.0
    @grace_timer      = 1.5   # brief immunity at game start

    @timer_text = nil
  end

  # ── BaseMinigame interface ────────────────────────────────────────────────────

  def start
    draw_background
    draw_wall_texture
    draw_gem
    draw_starting_platform
    draw_player
    draw_hud
  end

  # ---------------------------------------------------------------------------
  # update(dt)
  # ---------------------------------------------------------------------------
  # Physics-based update. Each frame:
  #   1. Tick grace timer
  #   2. Apply horizontal movement from $keys_held
  #   3. Apply gravity to vertical velocity
  #   4. Move player by velocity
  #   5. Resolve collisions with platform and rocks
  #   6. Check fall death
  #   7. Move / spawn / clean up rocks
  #   8. Check gem collision (win)
  #   9. Refresh HUD
  # ---------------------------------------------------------------------------
    def update(dt)
    return unless active?
    @grace_timer -= dt if @grace_timer > 0

    if ($keys_held['up'] || $keys_held['w'] || $keys_held['space'] || $keys_held[' ']) && @on_ground
        # Remove ALL frozen rocks when player jumps
        @rocks.each { |r| r[:shape].remove if r[:frozen] }
        @rocks.delete_if { |r| r[:frozen] }

        @vel_y     = JUMP_FORCE
        @on_ground = false
    end

    apply_horizontal_movement
    apply_gravity
    move_player
    resolve_platform_collision
    resolve_rock_collisions
    check_fall_death
    update_rocks(dt)
    spawn_rocks(dt)
    update_invincibility(dt)
    tick_game_timer(dt)
    check_gem_collision
    refresh_hud
    end

  # ---------------------------------------------------------------------------
  # handle_input(event)
  # ---------------------------------------------------------------------------
  # Only handles jumping — horizontal movement is polled from $keys_held in update.
  # Jump is only allowed when the player is standing on something (@on_ground).
  # ---------------------------------------------------------------------------
  def handle_input(event)
    return unless event.respond_to?(:key) && event.type.to_s.include?('down')
    
    
    
    action = resolve_key(event.key)
    return unless action == :jump
    return unless @on_ground

    if ($keys_held['up'] || $keys_held['w'] || $keys_held['space'] || $keys_held[' ']) && @on_ground
  # Remove all frozen rocks when player jumps off
  @rocks.each { |r| r[:shape].remove if r[:frozen] }
  @rocks.delete_if { |r| r[:frozen] }

  @vel_y     = JUMP_FORCE
  @on_ground = false
    end 
  end

  def cleanup
    @all_rock_shapes.each(&:remove)
    @all_rock_shapes.clear
    @rocks.clear
    super
  end

  # ── Private helpers ──────────────────────────────────────────────────────────
  private

  # ── Scene construction ────────────────────────────────────────────────────

  def draw_background
    track Rectangle.new(x: 0, y: 0, width: 800, height: 300,
                        color: COLOR_SKY, z: 0)
    track Rectangle.new(x: 0, y: 300, width: 800, height: 300,
                        color: COLOR_CLIFF, z: 0)
  end

  def draw_wall_texture
    # Iterative control structure: vertical crack lines
    (800 / 40).ceil.times do |i|
      track Line.new(x1: i * 40 + 20, y1: 0, x2: i * 40 + 18, y2: 600,
                     width: 1, color: COLOR_WALL_LINE, z: 1)
    end
    # Iterative control structure: horizontal ledge lines
    8.times do |i|
      track Line.new(x1: 0, y1: i * 75, x2: 800, y2: i * 75,
                     width: 1, color: COLOR_WALL_LINE, z: 1)
    end
  end

 def draw_gem
  cx = GEM_X + 15  # center x
  cy = GEM_Y + 15  # center y
  outer = 20       # outer point radius
  inner = 8        # inner point radius

  # Calculate the 10 points of a 5-pointed star
  points = []
  10.times do |i|
    angle = Math::PI / 5 * i - Math::PI / 2  # start at top
    r = i.even? ? outer : inner
    points << [cx + r * Math.cos(angle), cy + r * Math.sin(angle)]
  end

  # Draw as 5 triangles from center to each outer point
  5.times do |i|
    p1 = points[i * 2]
    p2 = points[i * 2 + 1]
    p3 = points[(i * 2 + 2) % 10]

    track Triangle.new(
      x1: cx,   y1: cy,
      x2: p1[0], y2: p1[1],
      x3: p2[0], y3: p2[1],
      color: COLOR_GEM, z: 5
    )
    track Triangle.new(
      x1: cx,   y1: cy,
      x2: p2[0], y2: p2[1],
      x3: p3[0], y3: p3[1],
      color: COLOR_GEM, z: 5
    )
  end

  # Store center for collision detection
  @gem_cx = cx
  @gem_cy = cy

  track Text.new(
    'GOLD STAR (REACH ME)',
    x: cx - 28, y: cy - 38,
    size: 11,
    color: COLOR_GEM,
    z: 6
  )
 end

  # The solid starting platform the player stands on at game start.
  # Drawn as a wide brown rectangle near the bottom of the screen.
  def draw_starting_platform
    track Rectangle.new(
      x: 0, y: GROUND_Y,
      width: 800, height: 20,
      color: COLOR_PLATFORM, z: 4
    )
  end

  def draw_player
    @player = track Rectangle.new(
      x: PLAYER_START_X, y: PLAYER_START_Y,
      width: PLAYER_W, height: PLAYER_H,
      color: COLOR_PLAYER, z: 10
    )
    @player_head = track Circle.new(
      x: PLAYER_START_X + PLAYER_W / 2,
      y: PLAYER_START_Y - 8,
      radius: 9, color: COLOR_HEAD, z: 11
    )
  end

  def draw_hud #
    track Text.new('ROCK CLIMB', x: 20,  y: 14, size: 16, color: 'white', z: 20)
    track Text.new('Jump on rocks to climb up!',
                   x: 145, y: 14, size: 13, color: [0.7, 0.7, 0.7, 1], z: 20)
    track Text.new('Time:', x: 560, y: 14, size: 16, color: 'white', z: 20)
    @timer_text = track Text.new(format_time(@game_timer), x: 610, y: 14, size: 16, color: 'aqua', z: 20)
  end

  # ── Physics ───────────────────────────────────────────────────────────────

  # Read left/right keys from global $keys_held and set horizontal velocity.
  # $keys_held is populated by main.rb's on :key_down / on :key_up blocks.
  def apply_horizontal_movement
    @vel_x = 0
    @vel_x -= MOVE_SPEED if $keys_held['left']  || $keys_held['a']
    @vel_x += MOVE_SPEED if $keys_held['right'] || $keys_held['d']
  end

  # Pull the player downward each frame unless on the ground.
  def apply_gravity
    return if @on_ground
    @vel_y += GRAVITY
  end

  # Move the player by current velocity, clamped to horizontal boundaries.
  def move_player
    new_x = (@player.x + @vel_x).clamp(PLAY_LEFT, PLAY_RIGHT - PLAYER_W)
    @player.x = new_x
    @player.y += @vel_y

    # Sync head position
    @player_head.x = @player.x + PLAYER_W / 2
    @player_head.y = @player.y - 8
  end

  # ── Collision resolution ─────────────────────────────────────────────────

  # Check if the player is landing on the static ground platform.
  # Sets @on_ground and stops downward velocity when touching the platform top.
  def resolve_platform_collision
    player_bottom = @player.y + PLAYER_H

    if player_bottom >= GROUND_Y && @vel_y >= 0
      @player.y  = GROUND_Y - PLAYER_H
      @vel_y     = 0
      @on_ground = true
      @player_head.y = @player.y - 8
    end
  end

  # ---------------------------------------------------------------------------
  # resolve_rock_collisions
  # ---------------------------------------------------------------------------
  # Iterates over every rock each frame and handles two cases:
  #
  #   LANDING (player falls onto the top of a rock):
  #     - Player bottom overlaps the rock top, player was moving downward
  #     - Freeze the rock (speed = 0, color changes to blue-grey)
  #     - Snap player to sit on top, set @on_ground = true
  #
  #   HIT FROM ABOVE (rock falls onto the player's head):
  #     - Rock bottom overlaps player top, player is NOT landing on it
  #     - Player loses a life (take_hit sets @failed = true)
  # ---------------------------------------------------------------------------
  def resolve_rock_collisions
    @on_ground = false if @vel_y > 0   # reset ground flag while falling

    # ITERATIVE CONTROL STRUCTURE: horizantal overlap check is shared between landing and head hit cases
    @rocks.each do |rock|
      rx = rock[:shape].x
      ry = rock[:shape].y
      rw = ROCK_W
      rh = ROCK_H

      px = @player.x
      py = @player.y
      pw = PLAYER_W
      ph = PLAYER_H

      # Check horizontal overlap (needed for both landing and head hit)
      h_overlap = px < rx + rw && px + pw > rx

      next unless h_overlap

      player_bottom = py + ph
      player_top    = py
      rock_top      = ry
      rock_bottom   = ry + rh

      # ── Landing on top of rock ──
      # Player bottom is near the rock top and player is moving downward
      if @vel_y >= 0 &&
        player_bottom >= rock_top &&
        player_bottom <= rock_top + 15 &&
        player_top < rock_top

        unless rock[:frozen]
            rock[:frozen]      = true
            rock[:speed]       = 0
            rock[:shape].color = COLOR_FROZEN
        end

        @player.y  = rock_top - ph
        @vel_y     = 0
        @on_ground = true
        @player_head.y = @player.y - 8

        # Remove all other frozen rocks when player lands on a new one
        @rocks.each do |r|
            next if r == rock
            next unless r[:frozen]
            r[:shape].remove
        end
        @rocks.delete_if { |r| r[:frozen] && r != rock }
        end
    end
  end

  # If the player falls below the death line, they lose a life.
  def check_fall_death
    return if @invincible
    return if @grace_timer > 0
    return unless @player.y > DEATH_Y

    take_hit
  end

  # ── Regex key resolver ────────────────────────────────────────────────────

  # ---------------------------------------------------------------------------
  # resolve_key(key_string)
  # ---------------------------------------------------------------------------
  # Iterates over CONTROL_MAP regex patterns to match the key name string.
  # Returns the action symbol (:jump, :move_left, :move_right) or nil.
  # This is the Regular Expression Mapping requirement — one pattern like
  # /^(up|w|space)$/i covers three keys without any duplicated logic.
  # ---------------------------------------------------------------------------
  def resolve_key(key_string)
    # Iterative control structure: test each regex pattern in turn
    CONTROL_MAP.each do |pattern, action|
      return action if key_string.match?(pattern)
    end
    nil
  end

  # ── Rock management — Dynamic List ───────────────────────────────────────

  # ---------------------------------------------------------------------------
  # spawn_rocks(dt)
  # ---------------------------------------------------------------------------
  # Accumulates dt into @spawn_timer. When it crosses @spawn_interval, a new
  # rock is appended (<<) to the @rocks dynamic list. The list grows here.
  #
  # Each rock hash: { shape:, speed:, frozen:, type: }
  # Rocks are NOT tracked via track() — managed manually because they are
  # added and removed dynamically throughout gameplay.
  # ---------------------------------------------------------------------------
  def spawn_rocks(dt)
    @spawn_timer += dt
    return unless @spawn_timer >= @spawn_interval

    @spawn_timer = 0.0

    x = rand(PLAY_LEFT..(PLAY_RIGHT - ROCK_W))
    rock_shape = Rectangle.new(
      x: x, y: -ROCK_H,
      width: ROCK_W, height: ROCK_H,
      color: COLOR_ROCK, z: 8
    )

    @all_rock_shapes << rock_shape  
    
    # Append new rock hash to the dynamic list (list grows here)
    @rocks << {
      shape:  rock_shape,
      speed:  @rock_speed + rand(-0.3..0.3),
      frozen: false,
      type:   'rock'
    }
  end

  # ---------------------------------------------------------------------------
  # update_rocks(dt)
  # ---------------------------------------------------------------------------
  # Moves every unfrozen rock downward. Removes rocks that exit the screen.
  # The removal step shrinks the dynamic list each frame.
  # ---------------------------------------------------------------------------
  def update_rocks(dt)
    # Iterative control structure: move every unfrozen rock downward
    @rocks.each do |rock|
      rock[:shape].y += rock[:speed] unless rock[:frozen]
    end

    # Remove rocks that have fallen off the bottom of the screen
    offscreen = @rocks.select { |rock| rock[:shape].y > 620 }
    offscreen.each { |rock| rock[:shape].remove }
    @rocks -= offscreen   # dynamic list shrinks here
  end

  # ── Timer ─────────────────────────────────────────────────────────────────

  def tick_game_timer(dt)
    @game_timer -= dt
    if @game_timer <= 0
      @game_timer = 0
      @failed = true unless @completed
    end
  end

  # ── Win condition ─────────────────────────────────────────────────────────

  # Player wins by reaching the gold star (old rectangle gem) at the top.
  def check_gem_collision
    px_center = @player.x + PLAYER_W / 2
    py_center = @player.y + PLAYER_H / 2
    dist = Math.sqrt((@gem_cx - px_center)**2 + (@gem_cy - py_center)**2)
    return unless dist < 25
    @completed = true
  end

  # ── Damage ────────────────────────────────────────────────────────────────

  # Called on a rock hit or fall death.
  # Sets @failed so main.rb ends the minigame and deducts a life.
  def take_hit
    @failed      = true
    @fail_reason = 'Hit by a rock'
    @failed           = true
    @invincible       = true
    @invincible_timer = 0.0
    @player.color     = COLOR_WHITE
  end

  def update_invincibility(dt)
    return unless @invincible

    @invincible_timer += dt
    @player.color = (@invincible_timer * 10).to_i.odd? ? COLOR_WHITE : COLOR_PLAYER

    if @invincible_timer >= 0.5
      @invincible   = false
      @player.color = COLOR_PLAYER
    end
  end

  # ── HUD ───────────────────────────────────────────────────────────────────

  def refresh_hud
    return unless @timer_text
    @timer_text.text  = format_time(@game_timer)
    @timer_text.color = @game_timer <= 5.0 ? 'red' : 'aqua'
  end

  def format_time(seconds)
    format('%02d', seconds.ceil.clamp(0, 99))
  end

end  # end class RockClimb
