# jetski_dash.rb
# "Jetski Dash" — a side-scrolling dodge game.
#
# The player pilots a jetski from left to right across the screen.
# Obstacles (rocks, buoys, logs) scroll in from the right.
# Survive for the full 10-second timer to win.
#
# Win  → survive until the timer reaches 0
# Fail → collide with any obstacle
#
# CS Requirements fulfilled in this file:
#   - Dynamic list:             @obstacles array grows on spawn, shrinks on cleanup
#   - Hash table:               DIFFICULTY constant + per-obstacle property hashes
#   - Regex mapping:            CONTROL_MAP uses regex patterns to map keys to actions
#   - Iterative control struct: .each / .select loops over obstacles every frame
#   - Graphics:                 Ruby2D shapes and text for all visuals
 
class JetskiDash < BaseMinigame
 
  # ── Constants ────────────────────────────────────────────────────────────────
 
  GAME_DURATION  = 15.0   # seconds to survive
 
  PLAYER_W       = 44
  PLAYER_H       = 20
  PLAYER_START_X = 80
  PLAYER_START_Y = 290    # vertical center of the water lane
 
  PLAY_TOP       = 100    # top boundary of the water lane
  PLAY_BOTTOM    = 480    # bottom boundary of the water lane
 
  MOVE_SPEED     = 6      # pixels per frame (vertical movement)
 
  OBS_W          = 32
  OBS_H          = 32
 
  SCREEN_W       = 800
  SCREEN_H       = 600
 
  # ── Colours ──────────────────────────────────────────────────────────────────
 
  COLOR_SKY        = [0.52, 0.80, 0.92, 1.0]   # pale blue sky
  COLOR_WATER_DEEP = [0.04, 0.28, 0.55, 1.0]   # deep ocean
  COLOR_WATER_MID  = [0.07, 0.40, 0.70, 1.0]   # mid water band
  COLOR_WATER_SURF = [0.15, 0.55, 0.82, 1.0]   # surface glint band
  COLOR_SHORE_TOP  = [0.20, 0.65, 0.25, 1.0]   # grassy shore top
  COLOR_SHORE_BOT  = [0.60, 0.50, 0.20, 1.0]   # sandy shore bottom
  COLOR_WAVE       = [0.80, 0.90, 1.00, 0.18]  # translucent wave stripe
  COLOR_JETSKI_BOD = [1.00, 0.30, 0.10, 1.0]   # red jetski hull
  COLOR_JETSKI_TOP = [1.00, 0.85, 0.20, 1.0]   # yellow windshield
  COLOR_RIDER      = [1.00, 0.75, 0.55, 1.0]   # rider skin
  COLOR_RIDER_SUIT = [0.10, 0.10, 0.60, 1.0]   # rider wetsuit
  COLOR_WAKE       = [0.85, 0.95, 1.00, 0.45]  # wake trail
  COLOR_ROCK       = [0.45, 0.35, 0.25, 1.0]
  COLOR_BUOY_BODY  = [1.00, 0.15, 0.15, 1.0]
  COLOR_BUOY_STRIPE= [1.00, 1.00, 1.00, 1.0]
  COLOR_LOG        = [0.55, 0.35, 0.10, 1.0]
  COLOR_LOG_RING   = [0.70, 0.50, 0.20, 1.0]
  COLOR_HIT        = [1.00, 1.00, 1.00, 1.0]
  COLOR_WHITE      = [1.00, 1.00, 1.00, 1.0]
  COLOR_HUD_TEXT   = [1.00, 1.00, 1.00, 1.0]
 
  # ── Difficulty scaling table — Hash Table ─────────────────────────────────
  # Key   => level (1-5)
  # Value => Hash of gameplay parameters
  #   :scroll_speed   — pixels/frame obstacles move left
  #   :spawn_interval — seconds between new obstacles
  DIFFICULTY = {
    1 => { scroll_speed: 4.0, spawn_interval: 0.8 },
    2 => { scroll_speed: 5.0, spawn_interval: 0.6 },
    3 => { scroll_speed: 6.0, spawn_interval: 0.5 },
    4 => { scroll_speed: 8.0, spawn_interval: 0.4 },
    5 => { scroll_speed: 10.0, spawn_interval: 0.3 },
  }.freeze
 
  # Obstacle type definitions — Hash Table
  # Each key is a symbol tag; value is a hash of visual/size overrides.
  OBS_TYPES = {
    rock:  { color: COLOR_ROCK,       w: 36, h: 28, label: 'rock'  },
    buoy:  { color: COLOR_BUOY_BODY,  w: 22, h: 36, label: 'buoy'  },
    log:   { color: COLOR_LOG,        w: 58, h: 18, label: 'log'   },
  }.freeze
 
  # ── Control mappings — Regular Expression Mapping ────────────────────────────
  # Patterns cover arrow keys and WASD without duplicating logic.
  CONTROL_MAP = {
    /^(up|w)$/i    => :move_up,
    /^(down|s)$/i  => :move_down,
    /^(left|a)$/i  => :move_left,
    /^(right|d)$/i => :move_right,
  }.freeze
 
  # ── Constructor ──────────────────────────────────────────────────────────────
 
  def initialize(difficulty_level)
    super
 
    cfg = DIFFICULTY[@difficulty_level]
    @scroll_speed   = cfg[:scroll_speed]
    @spawn_interval = cfg[:spawn_interval]
 
    @game_timer  = GAME_DURATION
    @timer_text  = nil
    @result_text = nil
 
    # ── Dynamic list of obstacles ─────────────────────────────────────────────
    # Each element is a Hash:
    #   :shape   => Ruby2D Rectangle (primary body)
    #   :detail  => Ruby2D shape (accent/stripe, may be nil)
    #   :type    => Symbol (:rock, :buoy, :log)
    #   :w, :h   => collision dimensions
    # List grows via << on spawn, shrinks when obstacles exit left edge.
    @obstacles = []
 
    # Wave scroll offset (cosmetic)
    @wave_offset = 0.0
 
    # Spawn timer accumulator
    @spawn_timer = 0.0
 
    # Player vertical velocity
    @vel_y = 0.0
 
    # Grace period so a mis-timed start doesn't instantly kill
    @grace_timer = 0.6
  end
 
  # ── BaseMinigame interface ────────────────────────────────────────────────────
 
  def start
    draw_background
    draw_shores
    draw_waves
    draw_player
    draw_hud
  end
 
  # ---------------------------------------------------------------------------
  # update(dt)
  # ---------------------------------------------------------------------------
  # Each frame:
  #   1. Tick grace timer
  #   2. Poll held keys → set vertical velocity
  #   3. Move player, clamp to water lane
  #   4. Scroll and spawn obstacles
  #   5. Collision check
  #   6. Tick game timer → win if it reaches 0
  #   7. Scroll wave decoration
  #   8. Refresh HUD
  # ---------------------------------------------------------------------------
  def update(dt)
    return unless active?
 
    @grace_timer -= dt if @grace_timer > 0
 
    apply_movement
    move_player
    update_obstacles(dt)
    spawn_obstacles(dt)
    check_collisions unless @grace_timer > 0
    tick_game_timer(dt)
    scroll_waves(dt)
    refresh_hud
  end
 
  # ---------------------------------------------------------------------------
  # handle_input(event)
  # ---------------------------------------------------------------------------
  # Handles key_down events; continuous movement is polled from $keys_held
  # in apply_movement, so this is mostly a hook for future one-shot actions.
  # ---------------------------------------------------------------------------
  def handle_input(event)
    return unless event.respond_to?(:key) && event.type == :key_down
    # Movement is handled via $keys_held polling; nothing extra needed here.
  end
 
  # ── Private helpers ──────────────────────────────────────────────────────────
  private
 
  # ── Scene construction ────────────────────────────────────────────────────
 
  def draw_background
    # Sky
    track Rectangle.new(x: 0, y: 0, width: SCREEN_W, height: PLAY_TOP,
                        color: COLOR_SKY, z: 0)
    # Water — three bands for depth illusion
    band_h = (PLAY_BOTTOM - PLAY_TOP) / 3
    track Rectangle.new(x: 0, y: PLAY_TOP,            width: SCREEN_W, height: band_h,
                        color: COLOR_WATER_SURF, z: 0)
    track Rectangle.new(x: 0, y: PLAY_TOP + band_h,   width: SCREEN_W, height: band_h,
                        color: COLOR_WATER_MID,  z: 0)
    track Rectangle.new(x: 0, y: PLAY_TOP + band_h*2, width: SCREEN_W, height: band_h + (PLAY_BOTTOM - PLAY_TOP) % 3,
                        color: COLOR_WATER_DEEP, z: 0)
    # Below water
    track Rectangle.new(x: 0, y: PLAY_BOTTOM, width: SCREEN_W, height: SCREEN_H - PLAY_BOTTOM,
                        color: COLOR_SHORE_BOT, z: 0)
  end
 
  def draw_shores
    # Grassy top shore strip
    track Rectangle.new(x: 0, y: PLAY_TOP - 22, width: SCREEN_W, height: 22,
                        color: COLOR_SHORE_TOP, z: 1)
    # Sandy bottom shore strip
    track Rectangle.new(x: 0, y: PLAY_BOTTOM, width: SCREEN_W, height: 22,
                        color: COLOR_SHORE_BOT, z: 1)
    # Shore edge lines
    track Line.new(x1: 0, y1: PLAY_TOP,    x2: SCREEN_W, y2: PLAY_TOP,
                   width: 3, color: COLOR_WHITE, z: 2)
    track Line.new(x1: 0, y1: PLAY_BOTTOM, x2: SCREEN_W, y2: PLAY_BOTTOM,
                   width: 3, color: COLOR_WHITE, z: 2)
  end
 
  def draw_waves
    # Iterative control structure: draw repeating wave stripes across water
    @wave_rects = []
    num_waves = 8
    gap = (PLAY_BOTTOM - PLAY_TOP) / num_waves
    num_waves.times do |i|
      wy = PLAY_TOP + i * gap + gap / 2
      r = track Rectangle.new(x: 0, y: wy, width: SCREEN_W, height: 6,
                               color: COLOR_WAVE, z: 2)
      @wave_rects << { rect: r, base_y: wy }
    end
  end
 
  def draw_player
    # Wake (drawn behind hull)
    @wake = track Rectangle.new(
      x: PLAYER_START_X - 30, y: PLAYER_START_Y + PLAYER_H / 2 - 5,
      width: 30, height: 10,
      color: COLOR_WAKE, z: 4
    )
    # Hull
    @player = track Rectangle.new(
      x: PLAYER_START_X, y: PLAYER_START_Y,
      width: PLAYER_W, height: PLAYER_H,
      color: COLOR_JETSKI_BOD, z: 5
    )
    # Windshield (front accent)
    @windshield = track Rectangle.new(
      x: PLAYER_START_X + PLAYER_W - 14, y: PLAYER_START_Y - 6,
      width: 12, height: 12,
      color: COLOR_JETSKI_TOP, z: 6
    )
    # Rider body
    @rider_body = track Rectangle.new(
      x: PLAYER_START_X + 10, y: PLAYER_START_Y - 14,
      width: 14, height: 14,
      color: COLOR_RIDER_SUIT, z: 6
    )
    # Rider head
    @rider_head = track Circle.new(
      x: PLAYER_START_X + 17, y: PLAYER_START_Y - 20,
      radius: 7, color: COLOR_RIDER, z: 7
    )
  end
 
  def draw_hud
    track Rectangle.new(x: 0, y: 0, width: SCREEN_W, height: 40,
                        color: [0.0, 0.0, 0.0, 0.55], z: 19)
    track Text.new('JETSKI DASH', x: 20,  y: 10, size: 16, color: 'white', z: 20)
    track Text.new('Survive the water!', x: 220, y: 12, size: 13,
                   color: [0.7, 0.7, 0.7, 1], z: 20)
    track Text.new('Time:', x: 560, y: 10, size: 16, color: 'white', z: 20)
    @timer_text = track Text.new(format_time(@game_timer), x: 610, y: 10, size: 16, color: 'aqua', z: 20)
  end
 
  # ── Movement ─────────────────────────────────────────────────────────────
 
  # Poll $keys_held every frame and set velocity accordingly.
  # Supports up/down/left/right (and WASD) via the CONTROL_MAP regex.
  def apply_movement
    @vel_y = 0
    # Iterative control structure: test each regex pattern in CONTROL_MAP
    CONTROL_MAP.each do |pattern, action|
      case action
      when :move_up    then @vel_y -= MOVE_SPEED if any_key_held?(pattern)
      when :move_down  then @vel_y += MOVE_SPEED if any_key_held?(pattern)
      end
    end
  end
 
  # Returns true if any key in $keys_held matches the given regex pattern.
  def any_key_held?(pattern)
    $keys_held.any? { |k, held| held && k.match?(pattern) }
  end
 
  # Move player shapes, clamped to water lane.
  def move_player
    new_y = (@player.y + @vel_y).clamp(PLAY_TOP, PLAY_BOTTOM - PLAYER_H)
    dy    = new_y - @player.y
 
    @player.y      += dy
    @windshield.y  += dy
    @rider_body.y  += dy
    @rider_head.y  += dy
    @wake.y        += dy
  end
 
  # ── Obstacle management — Dynamic List ───────────────────────────────────
 
  # ---------------------------------------------------------------------------
  # spawn_obstacles(dt)
  # ---------------------------------------------------------------------------
  # Accumulates dt into @spawn_timer. When the interval is reached, picks a
  # random obstacle type and appends a new hash to @obstacles (list grows <<).
  # ---------------------------------------------------------------------------
  def spawn_obstacles(dt)
    @spawn_timer += dt
    return unless @spawn_timer >= @spawn_interval
 
    @spawn_timer = 0.0
 
    type_key = OBS_TYPES.keys.sample
    cfg      = OBS_TYPES[type_key]
    ow, oh   = cfg[:w], cfg[:h]
 
    # Random Y within the water lane
    spawn_y = rand((PLAY_TOP + 4)..(PLAY_BOTTOM - oh - 4))
 
    body = Rectangle.new(
      x: SCREEN_W, y: spawn_y,
      width: ow, height: oh,
      color: cfg[:color], z: 8
    )
 
    # Type-specific detail shape
    detail = case type_key
             when :buoy
               Rectangle.new(x: SCREEN_W + ow / 2 - 4, y: spawn_y,
                              width: 8, height: oh / 3,
                              color: COLOR_BUOY_STRIPE, z: 9)
             when :log
               Line.new(x1: SCREEN_W + ow / 3, y1: spawn_y,
                        x2: SCREEN_W + ow / 3, y2: spawn_y + oh,
                        width: 3, color: COLOR_LOG_RING, z: 9)
             else
               nil
             end
 
    # Append new obstacle hash to the dynamic list (list grows here)
    @obstacles << {
      shape:  body,
      detail: detail,
      type:   type_key,
      w:      ow,
      h:      oh,
    }
  end
 
  # ---------------------------------------------------------------------------
  # update_obstacles(dt)
  # ---------------------------------------------------------------------------
  # Moves every obstacle left by @scroll_speed each frame.
  # Removes obstacles that have fully scrolled off the left edge.
  # The removal step shrinks the dynamic list.
  # ---------------------------------------------------------------------------
  def update_obstacles(dt)
    # Iterative control structure: move every obstacle left
    @obstacles.each do |obs|
      obs[:shape].x -= @scroll_speed
      obs[:detail].x -= @scroll_speed if obs[:detail].respond_to?(:x=)
      if obs[:detail].respond_to?(:x1=)
        obs[:detail].x1 -= @scroll_speed
        obs[:detail].x2 -= @scroll_speed
      end
    end
 
    # Remove off-screen obstacles (dynamic list shrinks here)
    offscreen = @obstacles.select { |obs| obs[:shape].x + obs[:w] < 0 }
    offscreen.each do |obs|
      obs[:shape].remove
      obs[:detail]&.remove
    end
    @obstacles -= offscreen
  end
 
  # ── Collision detection ───────────────────────────────────────────────────
 
  # ---------------------------------------------------------------------------
  # check_collisions
  # ---------------------------------------------------------------------------
  # Iterates over all obstacles each frame using AABB.
  # A small inset margin (4 px) prevents hair-trigger edges from feeling unfair.
  # ---------------------------------------------------------------------------
  def check_collisions
    margin = 4
    px = @player.x + margin
    py = @player.y + margin
    pw = PLAYER_W  - margin * 2
    ph = PLAYER_H  - margin * 2
 
    # Iterative control structure: test every obstacle
    @obstacles.each do |obs|
      ox = obs[:shape].x + margin
      oy = obs[:shape].y + margin
      ow = obs[:w] - margin * 2
      oh = obs[:h] - margin * 2
 
      next unless px < ox + ow && px + pw > ox &&
                  py < oy + oh && py + ph > oy
 
      take_hit
      return
    end
  end
 
  # ── Damage ────────────────────────────────────────────────────────────────
 
  def take_hit
    @failed       = true
    @player.color = COLOR_HIT
    clear_obstacles
  end
 
  # ── Timer ─────────────────────────────────────────────────────────────────
 
  def tick_game_timer(dt)
    @game_timer -= dt
    if @game_timer <= 0
      @game_timer = 0
      unless @failed
        @completed = true
        clear_obstacles
      end
    end
  end
 
  # Removes every active obstacle's Ruby2D shapes from the window and empties
  # the dynamic list. Called on both win and lose so nothing lingers on screen.
  def clear_obstacles
    @obstacles.each do |obs|
      obs[:shape].remove
      obs[:detail]&.remove
    end
    @obstacles.clear
  end
 
  # ── Cosmetic scrolling waves ──────────────────────────────────────────────
 
  def scroll_waves(dt)
    @wave_offset = (@wave_offset + @scroll_speed * 0.4) % SCREEN_W
    @wave_rects&.each do |w|
      w[:rect].x = -@wave_offset % SCREEN_W - SCREEN_W / 2
    end
  end
 
  # ── Regex key resolver ────────────────────────────────────────────────────
 
  # ---------------------------------------------------------------------------
  # resolve_key(key_string)
  # ---------------------------------------------------------------------------
  # Matches a key name string against CONTROL_MAP regex patterns.
  # Returns the action symbol or nil. Mirrors rock_climb.rb's implementation.
  # ---------------------------------------------------------------------------
  def resolve_key(key_string)
    # Iterative control structure: test each regex pattern in turn
    CONTROL_MAP.each do |pattern, action|
      return action if key_string.match?(pattern)
    end
    nil
  end
 
  # ── HUD ───────────────────────────────────────────────────────────────────
 
  def refresh_hud
    return unless @timer_text
    @timer_text.text  = format_time(@game_timer)
    @timer_text.color = @game_timer <= 3.0 ? 'red' : 'aqua'
  end
 
  def format_time(seconds)
    format('%02d', seconds.ceil.clamp(0, 99))
  end
 
end  # end class JetskiDash
