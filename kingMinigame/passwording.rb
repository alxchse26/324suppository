# passwording.rb
# "Password Game" — a password creation minigame.
#
# The player is shown a set of password RULES (each backed by a Regexp).
# They must type a password that satisfies ALL rules simultaneously.
# Rules are checked live on every keystroke via String#match?.
# Each round adds more rules, making a valid password harder to construct.
#
# Win  → typed string matches every rule's pattern at the same time
# Fail → timer reaches zero
#
# CS Requirements fulfilled in this file:
#   - Dynamic list:             @active_rules built each round; :passing updated each keypress
#   - Hash table:               DIFFICULTY + RULE_POOL store all data as hashes
#   - Regex mapping:            CONTROL_MAP maps key patterns to editor actions;
#                               every rule's :pattern is tested via String#match?
#   - Iterative control struct: .each / .all? / .count loops evaluate every rule each keypress
#   - Graphics:                 Ruby2D shapes and text for all visuals
 
class Passwording < BaseMinigame
 
  # ── Constants ────────────────────────────────────────────────────────────────
 
  SCREEN_W      = 800
  SCREEN_H      = 600
  INPUT_MAX_LEN = 48
 
  RULE_H        = 36
  RULE_GAP      = 5
  RULES_START_Y = 80
  RULES_X       = 40
 
  # ── Colours ──────────────────────────────────────────────────────────────────
 
  COLOR_BG           = [0.05, 0.04, 0.10, 1.0]
  COLOR_PANEL        = [0.09, 0.08, 0.18, 1.0]
  COLOR_BORDER       = [0.25, 0.20, 0.50, 1.0]
  COLOR_INPUT_ACTIVE = [0.10, 0.09, 0.22, 1.0]
  COLOR_INPUT_DONE   = [0.07, 0.25, 0.12, 1.0]
  COLOR_CURSOR       = [0.80, 0.70, 1.00, 1.0]
 
  COLOR_RULE_PASS    = [0.07, 0.22, 0.10, 1.0]
  COLOR_RULE_FAIL    = [0.18, 0.07, 0.07, 1.0]
  COLOR_CHECK        = [0.25, 1.00, 0.40, 1.0]
  COLOR_CROSS        = [1.00, 0.30, 0.30, 1.0]
 
  COLOR_WHITE        = [1.00, 1.00, 1.00, 1.0]
  COLOR_DIM          = [0.50, 0.45, 0.65, 1.0]
  COLOR_GOLD         = [1.00, 0.82, 0.20, 1.0]
  COLOR_PURPLE       = [0.70, 0.50, 1.00, 1.0]
  COLOR_FAIL_TEXT    = [1.00, 0.30, 0.30, 1.0]
  COLOR_WIN_TEXT     = [0.25, 1.00, 0.45, 1.0]
 
  COLOR_STRENGTH_LOW = [1.00, 0.30, 0.20, 1.0]
  COLOR_STRENGTH_MED = [1.00, 0.75, 0.10, 1.0]
  COLOR_STRENGTH_HI  = [0.25, 1.00, 0.45, 1.0]
 
  STRENGTH_LABELS = ['Very Weak', 'Weak', 'Fair', 'Good', 'Strong', 'Very Strong'].freeze
 
  # ── Difficulty — Hash Table ───────────────────────────────────────────────────
  DIFFICULTY = {
    1 => { game_duration: 30.0 },
    2 => { game_duration: 27.0 },
    3 => { game_duration: 24.0 },
    4 => { game_duration: 21.0 },
    5 => { game_duration: 18.0 },
  }.freeze
 
  # ── Rule pool — Hash Table ────────────────────────────────────────────────────
  # Ordered easy → hard. Round N uses the first (N+1) rules.
  # Each rule is a Hash: :label, :pattern (Regexp), :example (fragment).
RULE_POOL = [
  # ─────────────────────────────
  # BASIC STRUCTURAL RULES
  # ─────────────────────────────

  {
    label: 'Must be at least 8 characters',
    pattern: /.{8,}/,
    example: 'aaaaaaaa',
  },
  {
    label: 'Must be at least 12 characters',
    pattern: /.{12,}/,
    example: 'aaaaaaaaaaaa',
  },
  {
    label: 'Must be at least 16 characters',
    pattern: /.{16,}/,
    example: 'aaaaaaaaaaaaaaaa',
  },

  # ─────────────────────────────
  # CHARACTER TYPE RULES
  # ─────────────────────────────

  {
    label: 'Must contain a lowercase letter',
    pattern: /[a-z]/,
    example: 'a',
  },
  {
    label: 'Must contain an uppercase letter',
    pattern: /[A-Z]/,
    example: 'A',
  },
  {
    label: 'Must contain a digit',
    pattern: /[0-9]/,
    example: '1',
  },

  # ─────────────────────────────
  # STRUCTURE / POSITION RULES
  # ─────────────────────────────

  {
    label: 'Must NOT contain spaces',
    pattern: /^[^ ]+$/,
    example: '(no spaces)',
  },
  {
    label: 'Must start with a number',
    pattern: /^[0-9]/,
    example: 'a...',
  },
  {
    label: 'Must end with a digit',
    pattern: /[0-9]$/,
    example: '...1',
  },
  {
    label: 'Must start and end with the same character',
    pattern: /^(.).*\1$/,
    example: 'a...a',
  },

  # ─────────────────────────────
  # REPETITION / PATTERN RULES
  # ─────────────────────────────

  {
    label: 'Must contain two digits in a row (e.g. 42)',
    pattern: /[0-9]{2}/,
    example: '42',
  },
  {
    label: 'Must contain three identical characters in a row',
    pattern: /(.)\1\1/,
    example: 'aaa',
  },

  # ─────────────────────────────
  # POSITIONAL SUBSTRING RULES
  # ─────────────────────────────

  {
    label: 'Must contain "nailgun" somewhere',
    pattern: /ab/,
    example: '...nailgun...',
  },
  {
    label: 'Must contain "2026"',
    pattern: /2026/,
    example: '2026',
  },
  {
    label: 'Must contain "cat"',
    pattern: /cat/,
    example: 'cat',
  },

  # ─────────────────────────────
  # NEGATIVE RULES (more interesting gameplay)
  # ─────────────────────────────

  {
    label: 'Must NOT contain "a"',
    pattern: /^[^a]*$/,
    example: '(no a)',
  },
  {
    label: 'Must NOT contain digits',
    pattern: /^[^0-9]*$/,
    example: '(no numbers)',
  },
  {
    label: 'Must NOT repeat any letter twice in a row',
    pattern: /^(?!.*(.)\1).*$/,
    example: '(no aa, bb, etc)',
  },

  # ─────────────────────────────
  # ADVANCED / PUZZLE RULES
  # ─────────────────────────────

  {
    label: 'Must contain at least 2 vowels',
    pattern: /.*[aeiou].*[aeiou].*/,
    example: 'ae',
  },
  {
    label: 'Must contain a letter followed by a digit',
    pattern: /[a-zA-Z][0-9]/,
    example: 'a1',
  },
  {
    label: 'Must contain a digit followed by a letter',
    pattern: /[0-9][a-zA-Z]/,
    example: '1a',
  }
].freeze
 
  # ── Control mappings — Regex Mapping ─────────────────────────────────────────
  # Only control keys live here. Single printable chars are caught by
  # key.length == 1 in handle_input.
  CONTROL_MAP = {
    /^backspace$/i => :delete_char,
    /^space$/i     => :type_space,
    /^return$/i    => :noop,
    /^enter$/i     => :noop,
    /^tab$/i       => :noop,
    /^escape$/i    => :noop,
  }.freeze
 
  SHIFT_MAP = {
    '1' => '!', '2' => '@', '3' => '#', '4' => '$', '5' => '%',
    '6' => '^', '7' => '&', '8' => '*', '9' => '(', '0' => ')',
  }.freeze
 
  # ── Constructor ──────────────────────────────────────────────────────────────
 
  def initialize(difficulty_level)
    super
 
    cfg         = DIFFICULTY[@difficulty_level]
    @game_timer = cfg[:game_duration]
 
    num_rules = (@difficulty_level + 1).clamp(2, RULE_POOL.length)
 
    # ── Dynamic list of active rules ──────────────────────────────────────────
    @active_rules = RULE_POOL.shuffle.first(num_rules).map { |r| r.dup.merge(passing: false) }
 
    @input_str  = ''
    @all_pass   = false
    @input_top  = 0
 
    @cursor_timer = 0.0
    @cursor_on    = true
 
    @timer_text    = nil
    @input_box     = nil
    @input_label   = nil
    @cursor_rect   = nil
    @char_count    = nil
    @strength_bar  = nil
    @strength_text = nil
    @status_text   = nil
 
    # Per-rule shape references (parallel to @active_rules).
    # These are NOT tracked via track() — managed manually like jetski obstacles.
    @rule_tiles  = []
    @rule_icons  = []
    @rule_labels = []
 
    # Master list of every untracked shape, used by clear_dynamic_shapes.
    # Mirrors the pattern from jetski_dash's @obstacles list.
    @dynamic_shapes = []
  end
 
  # ── BaseMinigame interface ────────────────────────────────────────────────────
 
  def start
    draw_background
    draw_header
    draw_rules_panel
    draw_input_area
    draw_strength_meter
    draw_status_bar
  end
 
  def update(dt)
    return unless active?
    tick_cursor(dt)
    tick_game_timer(dt)
    refresh_hud
  end
 
  # ---------------------------------------------------------------------------
  # handle_input(event)
  # ---------------------------------------------------------------------------
  # BUG FIX 1 — DOUBLE INPUT:
  # The original code only checked event.respond_to?(:key), which meant the
  # method fired on BOTH :key_down and :key_up, appending each character twice.
  # The fix is the additional guard: event.type == :key_down.
  #
  # Control keys are routed via CONTROL_MAP regex matching.
  # Single printable characters are caught by key.length == 1 — no exhaustive
  # symbol pattern needed.
  # ---------------------------------------------------------------------------
  def handle_input(event)
    return unless event.respond_to?(:key) && event.type.to_s.include?('down')
    
    key    = event.key
    action = resolve_key(key)
 
    if action == :delete_char
      @input_str = @input_str[0..-2] unless @input_str.empty?
    elsif action == :type_space
      @input_str += ' ' if @input_str.length < INPUT_MAX_LEN
    elsif action.nil? && key.length == 1
      char = if event.respond_to?(:shift) && event.shift
               SHIFT_MAP.fetch(key, key.upcase)
             else
               key
             end
      @input_str += char if @input_str.length < INPUT_MAX_LEN
    end
    
    # :noop and unrecognised multi-char keys (arrows, F-keys) are ignored.

    evaluate
    redraw_input
    redraw_rules
    redraw_strength
    redraw_status
  end
 
  # ── Private helpers ──────────────────────────────────────────────────────────
  private
 
  # ---------------------------------------------------------------------------
  # dyn(shape)
  # ---------------------------------------------------------------------------
  # Registers a shape in @dynamic_shapes and returns it, mirroring how
  # track() works for tracked shapes. Every shape that needs manual cleanup
  # should be created through this helper instead of plain .new.
  # ---------------------------------------------------------------------------
  def dyn(shape)
    @dynamic_shapes << shape
    shape
  end
 
  # ---------------------------------------------------------------------------
  # clear_dynamic_shapes
  # ---------------------------------------------------------------------------
  # Removes every untracked shape from the window and empties the list.
  # Called on both win and lose so nothing lingers — same pattern as
  # clear_obstacles in jetski_dash and clear_rocks in rock_climb.
  # ---------------------------------------------------------------------------
  def clear_dynamic_shapes
    @dynamic_shapes.each(&:remove)
    @dynamic_shapes.clear
    @rule_tiles.clear
    @rule_icons.clear
    @rule_labels.clear
  end
 
  # ── Scene construction ────────────────────────────────────────────────────
 
  def draw_background
    track Rectangle.new(x: 0, y: 0, width: SCREEN_W, height: SCREEN_H,
                        color: COLOR_BG, z: 0)
    (SCREEN_H / 4).times do |i|
      track Rectangle.new(x: 0, y: i * 4, width: SCREEN_W, height: 1,
                          color: [1.0, 1.0, 1.0, 0.018], z: 1)
    end
  end
 
  def draw_header
    track Rectangle.new(x: 0, y: 0, width: SCREEN_W, height: 56,
                        color: COLOR_PANEL, z: 2)
    track Line.new(x1: 0, y1: 56, x2: SCREEN_W, y2: 56,
                   width: 2, color: COLOR_BORDER, z: 3)
 
    track Rectangle.new(x: 16, y: 18, width: 20, height: 16,
                        color: COLOR_GOLD, z: 4)
    track Line.new(x1: 21, y1: 10, x2: 21, y2: 20, width: 3, color: COLOR_GOLD, z: 4)
    track Line.new(x1: 31, y1: 10, x2: 31, y2: 20, width: 3, color: COLOR_GOLD, z: 4)
    track Line.new(x1: 21, y1: 10, x2: 31, y2: 10, width: 3, color: COLOR_GOLD, z: 4)
    track Circle.new(x: 26, y: 25, radius: 3, color: [0.0, 0.0, 0.0, 0.6], z: 5)
 
    track Text.new('CREATE YOUR PASSWORD', x: 48, y: 14,
                   size: 18, color: COLOR_GOLD, z: 4)
 
    n = @active_rules.length
    track Text.new("#{n} rule#{n == 1 ? '' : 's'} to satisfy",
                   x: 320, y: 19, size: 13, color: COLOR_DIM, z: 4)
 
    track Text.new('Time:', x: 676, y: 14, size: 16, color: COLOR_WHITE, z: 4)
    @timer_text = track Text.new(format_time(@game_timer),
                                 x: 732, y: 14, size: 16, color: COLOR_PURPLE, z: 4)
  end
 
  # ---------------------------------------------------------------------------
  # draw_rules_panel
  # ---------------------------------------------------------------------------
  # BUG FIX 2 — LINGERING SHAPES:
  # Rule tiles, icons, and labels were created with plain .new and stored only
  # in parallel arrays. BaseMinigame never knew about them, so they were never
  # removed when the game ended.
  #
  # Fix: create them through dyn() instead of .new, which registers them in
  # @dynamic_shapes. clear_dynamic_shapes then removes them all at end-of-game,
  # exactly as jetski_dash does with obstacle shapes.
  # ---------------------------------------------------------------------------
  def draw_rules_panel
    @active_rules.each_with_index do |rule, i|
      y = RULES_START_Y + i * (RULE_H + RULE_GAP)
      w = SCREEN_W - RULES_X * 2
 
      tile  = dyn Rectangle.new(x: RULES_X, y: y, width: w, height: RULE_H,
                                color: COLOR_RULE_FAIL, z: 3)
      icon  = dyn Text.new('✗', x: RULES_X + 10, y: y + 9,
                           size: 14, color: COLOR_CROSS, z: 5)
      label = dyn Text.new(rule[:label], x: RULES_X + 34, y: y + 10,
                           size: 13, color: COLOR_WHITE, z: 5)
 
      @rule_tiles  << tile
      @rule_icons  << icon
      @rule_labels << label
    end
  end
 
  def draw_input_area
    @input_top = RULES_START_Y + @active_rules.length * (RULE_H + RULE_GAP) + 16
 
    track Text.new('Password:', x: RULES_X, y: @input_top,
                   size: 12, color: COLOR_DIM, z: 4)
 
    @input_box = dyn Rectangle.new(x: RULES_X, y: @input_top + 18,
                                   width: SCREEN_W - RULES_X * 2, height: 50,
                                   color: COLOR_INPUT_ACTIVE, z: 3)
 
    track Line.new(x1: RULES_X, y1: @input_top + 18,
                   x2: SCREEN_W - RULES_X, y2: @input_top + 18,
                   width: 2, color: COLOR_BORDER, z: 4)
    track Line.new(x1: RULES_X, y1: @input_top + 68,
                   x2: SCREEN_W - RULES_X, y2: @input_top + 68,
                   width: 2, color: COLOR_BORDER, z: 4)
 
    @input_label = dyn Text.new('', x: RULES_X + 12, y: @input_top + 24,
                                size: 19, color: COLOR_WHITE, z: 5)
    @cursor_rect = dyn Rectangle.new(x: RULES_X + 14, y: @input_top + 26,
                                     width: 2, height: 24,
                                     color: COLOR_CURSOR, z: 6)
    @char_count  = dyn Text.new("0 / #{INPUT_MAX_LEN}",
                                x: SCREEN_W - RULES_X - 58, y: @input_top + 22,
                                size: 11, color: COLOR_DIM, z: 5)
  end
 
  def draw_strength_meter
    bar_y = @input_top + 80
 
    track Text.new('Strength:', x: RULES_X, y: bar_y,
                   size: 12, color: COLOR_DIM, z: 4)
    track Rectangle.new(x: RULES_X + 72, y: bar_y + 3,
                        width: 200, height: 11,
                        color: [0.15, 0.12, 0.25, 1.0], z: 4)
 
    @strength_bar  = dyn Rectangle.new(x: RULES_X + 72, y: bar_y + 3,
                                       width: 0, height: 11,
                                       color: COLOR_STRENGTH_LOW, z: 5)
    @strength_text = dyn Text.new('', x: RULES_X + 280, y: bar_y,
                                  size: 12, color: COLOR_DIM, z: 5)
  end
 
  def draw_status_bar
    track Rectangle.new(x: 0, y: SCREEN_H - 44, width: SCREEN_W, height: 44,
                        color: COLOR_PANEL, z: 2)
    track Line.new(x1: 0, y1: SCREEN_H - 44, x2: SCREEN_W, y2: SCREEN_H - 44,
                   width: 2, color: COLOR_BORDER, z: 3)
 
    @status_text = dyn Text.new('Start typing your password...', x: 22, y: SCREEN_H - 30,
                                size: 14, color: COLOR_DIM, z: 4)
  end
 
  # ── Core mechanic — Regex evaluation ─────────────────────────────────────
 
  def evaluate
    @active_rules.each do |rule|
      rule[:passing] = @input_str.match?(rule[:pattern])
    end
 
    @all_pass = @active_rules.all? { |r| r[:passing] }
    if @all_pass
      @completed = true
      clear_dynamic_shapes
    end
  end
 
  # ── Redraw helpers ────────────────────────────────────────────────────────
 
  def redraw_input
    return unless @input_label  # guard: shapes may have been cleared on win
    @input_label.text = @input_str
    @input_box.color  = @all_pass ? COLOR_INPUT_DONE : COLOR_INPUT_ACTIVE
 
    char_w = 11
    @cursor_rect.x   = RULES_X + 14 + (@input_str.length * char_w)
    @char_count.text = "#{@input_str.length} / #{INPUT_MAX_LEN}"
  end
 
  def redraw_rules
    return if @rule_tiles.empty?  # guard: shapes may have been cleared on win
    @active_rules.each_with_index do |rule, i|
      if rule[:passing]
        @rule_tiles[i].color = COLOR_RULE_PASS
        @rule_icons[i].text  = '✓'
        @rule_icons[i].color = COLOR_CHECK
      else
        @rule_tiles[i].color = COLOR_RULE_FAIL
        @rule_icons[i].text  = '✗'
        @rule_icons[i].color = COLOR_CROSS
      end
    end
  end
 
  def redraw_strength
    return unless @strength_bar && @strength_text
 
    passing = @active_rules.count { |r| r[:passing] }
    total   = @active_rules.length
    frac    = total > 0 ? passing.to_f / total : 0.0
 
    @strength_bar.width = (200 * frac).to_i
    @strength_bar.color = case frac
                          when 0.0...0.4  then COLOR_STRENGTH_LOW
                          when 0.4...0.75 then COLOR_STRENGTH_MED
                          else                 COLOR_STRENGTH_HI
                          end
 
    idx = ((frac * (STRENGTH_LABELS.length - 1)).round).clamp(0, STRENGTH_LABELS.length - 1)
    @strength_text.text  = STRENGTH_LABELS[idx]
    @strength_text.color = @strength_bar.color
  end
 
  def redraw_status
    return unless @status_text
    passing = @active_rules.count { |r| r[:passing] }
    total   = @active_rules.length
 
    if @all_pass
      @status_text.text  = "✓  All #{total} rules satisfied — password accepted!"
      @status_text.color = COLOR_WIN_TEXT
    elsif @input_str.empty?
      @status_text.text  = 'Start typing your password...'
      @status_text.color = COLOR_DIM
    else
      @status_text.text  = "#{passing} / #{total} rules satisfied"
      @status_text.color = passing.zero? ? COLOR_FAIL_TEXT : COLOR_DIM
    end
  end
 
  # ── Regex key resolver ────────────────────────────────────────────────────
 
  def resolve_key(key_string)
    CONTROL_MAP.each do |pattern, action|
      return action if key_string.match?(pattern)
    end
    nil
  end
 
  # ── Timer ─────────────────────────────────────────────────────────────────
 
  def tick_game_timer(dt)
    @game_timer -= dt
    if @game_timer <= 0
      @game_timer = 0
      unless @completed
        @failed = true
        hints = @active_rules.reject { |r| r[:passing] }.map { |r| r[:example] }.join('  ')
        @status_text&.text  = "Time's up! Missing: #{hints}"
        @status_text&.color = COLOR_FAIL_TEXT
        clear_dynamic_shapes  # remove all untracked shapes on timeout
      end
    end
  end
 
  # ── Cursor blink ──────────────────────────────────────────────────────────
 
  def tick_cursor(dt)
    @cursor_timer += dt
    if @cursor_timer >= 0.5
      @cursor_timer = 0.0
      @cursor_on    = !@cursor_on
      return unless @cursor_rect  # guard: may have been cleared
      @cursor_rect.color = @cursor_on ? COLOR_CURSOR : [0.0, 0.0, 0.0, 0.0]
    end
  end
 
  # ── HUD ───────────────────────────────────────────────────────────────────
 
  def refresh_hud
    return unless @timer_text
    @timer_text.text  = format_time(@game_timer)
    @timer_text.color = @game_timer <= 5.0 ? COLOR_FAIL_TEXT : COLOR_PURPLE
  end
 
  def format_time(seconds)
    format('%02d', seconds.ceil.clamp(0, 99))
  end
 
end  # end class Passwording
