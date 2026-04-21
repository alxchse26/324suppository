# minigames/seat_scramble.rb
# "Seat Scramble" — a Whack-a-Mole variant played on a plane seating chart.
#
# Seat states:
#   :occupied  — red,  clicking does nothing
#   :open      — green, clicking claims it within the time window
#   :owned     — grey, frozen for the rest of the minigame (player claimed it)
#
# Win  → player claims SEATS_TO_WIN seats before the minigame timer expires
# Fail → timer expires without enough claimed seats (lose one life, move on)

class SeatScramble < BaseMinigame

  # ── Layout constants ──────────────────────────────────────────────────────
  ROWS         = 13
  COLS         = 6           # A B C  |aisle|  D E F
  SEAT_W       = 46
  SEAT_H       = 42
  SEAT_RADIUS  = 8           # corner rounding (drawn as Rectangle + overlapping circles trick)
  H_GAP        = 6           # gap between seats horizontally
  V_GAP        = 5           # gap between seats vertically
  AISLE_W      = 28          # gap between C and D columns

  # Top-left origin of the entire grid
  GRID_X       = 90
  GRID_Y       = 100

  # Column header labels
  COL_LABELS   = %w[A B C D E F].freeze

  # ── Colour palette (Ruby2D RGBA arrays for precise control) ───────────────
  COLOR_OCCUPIED = [0.78, 0.1,  0.1,  1.0]   # red
  COLOR_OPEN     = [0.1,  0.75, 0.25, 1.0]   # green
  COLOR_OWNED    = [0.45, 0.45, 0.5,  1.0]   # grey
  COLOR_BLOCKED  = [0.3,  0.3,  0.35, 0.7]   # dark grey — seats that never open (row 1 gaps etc.)
  COLOR_BG       = [0.08, 0.08, 0.18, 1.0]   # window background

  # ── Difficulty scaling table ──────────────────────────────────────────────
  # [ flip_interval, max_open, open_duration, seats_to_win, game_duration ]
  DIFFICULTY = {
    1 => { flip_interval: 2.0, max_open: 3, open_duration: 2.0, seats_to_win: 3,  game_duration: 30.0 },
    2 => { flip_interval: 1.6, max_open: 4, open_duration: 1.8, seats_to_win: 5,  game_duration: 28.0 },
    3 => { flip_interval: 1.2, max_open: 5, open_duration: 1.5, seats_to_win: 7,  game_duration: 25.0 },
    4 => { flip_interval: 0.9, max_open: 5, open_duration: 1.2, seats_to_win: 9,  game_duration: 22.0 },
    5 => { flip_interval: 0.6, max_open: 5, open_duration: 1.0, seats_to_win: 11, game_duration: 20.0 },
  }.freeze

  # ── Inner Seat class ──────────────────────────────────────────────────────
  # Each seat is fully self-contained: it knows its pixel bounds, its state,
  # and owns its own Ruby2D Rectangle. Colour changes happen right here.

  class Seat
    attr_reader :row, :col, :x, :y, :state
    attr_accessor :open_timer   # seconds remaining while :open

    def initialize(row, col, x, y, blocked: false)
      @row     = row
      @col     = col
      @x       = x
      @y       = y
      @blocked = blocked
      @state   = blocked ? :blocked : :occupied
      @open_timer = 0.0

      # The Ruby2D rectangle for this seat
      @rect = Rectangle.new(
        x: @x, y: @y,
        width: SEAT_W, height: SEAT_H,
        color: current_color
      )
      # Small rounded-corner illusion: four tiny corner squares painted BG color
      @corners = draw_corners
    end

    # Change state and immediately recolor the rectangle
    def state=(new_state)
      @state = new_state
      @rect.color = current_color
    end

    # Hit-test: is the pixel (mx, my) inside this seat?
    def contains?(mx, my)
      mx.between?(@x, @x + SEAT_W) && my.between?(@y, @y + SEAT_H)
    end

    def remove_all
      @rect.remove
      @corners.each(&:remove)
    end

    def blocked? = @blocked

    private

    def current_color
      case @state
      when :occupied then COLOR_OCCUPIED
      when :open     then COLOR_OPEN
      when :owned    then COLOR_OWNED
      when :blocked  then COLOR_BLOCKED
      else                COLOR_OCCUPIED
      end
    end

    # Fake rounded corners: paint four 8×8 background-coloured squares
    # over the rectangle's corners so they look rounded.
    def draw_corners
      offsets = [[0, 0], [SEAT_W - SEAT_RADIUS, 0],
                 [0, SEAT_H - SEAT_RADIUS], [SEAT_W - SEAT_RADIUS, SEAT_H - SEAT_RADIUS]]
      offsets.map do |dx, dy|
        Square.new(x: @x + dx, y: @y + dy, size: SEAT_RADIUS, color: COLOR_BG)
      end
    end
  end
  # ── End Seat class ────────────────────────────────────────────────────────

  def initialize(difficulty_level)
    super
    cfg = DIFFICULTY[@difficulty_level]

    # Difficulty parameters
    @flip_interval  = cfg[:flip_interval]
    @max_open       = cfg[:max_open]
    @open_duration  = cfg[:open_duration]
    @seats_to_win   = cfg[:seats_to_win]
    @game_duration  = cfg[:game_duration]

    # Runtime counters
    @flip_timer     = 0.0    # counts up; flips seats when it crosses @flip_interval
    @game_timer     = @game_duration
    @owned_count    = 0

    @seats          = []     # flat Array of all Seat objects
    @ui_objects     = []     # Text/Rectangle HUD elements

    # Which seats are structurally "blocked" (gaps in real plane layouts)?
    # Row 1 has no A/B/C seats on this layout; row 7 has no B/C.
    @blocked_positions = Set.new([
      [1, 0], [1, 1], [1, 2],   # row 1, columns A B C
      [7, 1], [7, 2],            # row 7, columns B C (aisle side is empty)
    ])
  end

  # ── Public BaseMinigame interface ─────────────────────────────────────────

  def start
    build_grid
    build_hud
    # Immediately open a couple of seats so the player isn't staring at all red
    open_random_seats
  end

  def update(dt)
    return unless active?

    tick_open_seats(dt)
    tick_flip_timer(dt)
    tick_game_timer(dt)
    refresh_hud
  end

  def handle_input(event)
    return unless active?
    return unless event.respond_to?(:button) && event.button == :left

    clicked = @seats.find { |s| s.contains?(event.x, event.y) }
    return unless clicked
    return unless clicked.state == :open

    # Claim the seat!
    clicked.state     = :owned
    clicked.open_timer = 0.0
    @owned_count      += 1

    @completed = true if @owned_count >= @seats_to_win
  end

  def cleanup
    @seats.each(&:remove_all)
    @seats.clear
    @ui_objects.each(&:remove)
    @ui_objects.clear
    # Also clean up the @objects array from BaseMinigame (for background etc.)
    super
  end

  # ── Private helpers ───────────────────────────────────────────────────────

  private

  # Build the 13×6 grid of Seat objects
  def build_grid
    # Background panel
    bg = Rectangle.new(
      x: GRID_X - 10, y: GRID_Y - 35,
      width: grid_total_width + 20,
      height: ROWS * (SEAT_H + V_GAP) + 50,
      color: [0.05, 0.05, 0.15, 1.0]
    )
    @ui_objects << bg

    # Column header labels
    COL_LABELS.each_with_index do |label, col_idx|
      lx = seat_x(col_idx) + SEAT_W / 2 - 6
      @ui_objects << Text.new(label, x: lx, y: GRID_Y - 28, size: 18, color: 'white')
    end

    # Build every seat
    ROWS.times do |row|
      COLS.times do |col|
        sx       = seat_x(col)
        sy       = seat_y(row)
        blocked  = @blocked_positions.include?([row, col])

        seat = Seat.new(row, col, sx, sy, blocked: blocked)
        @seats << seat

        # Row number labels — printed once per row in the aisle gap
        if col == 2
          row_label_x = sx + SEAT_W + AISLE_W / 2 - 8
          @ui_objects << Text.new(
            (row + 1).to_s,
            x: row_label_x, y: sy + SEAT_H / 2 - 9,
            size: 16, color: [0.7, 0.7, 0.7, 1]
          )
        end
      end
    end
  end

  def build_hud
    # Game title
    @ui_objects << Text.new(
      'SEAT SCRAMBLE',
      x: 490, y: 108,
      size: 26,
      color: 'white'
    )

    # Instructions
    @ui_objects << Text.new(
      'Click GREEN seats to claim them!',
      x: 465, y: 145,
      size: 16,
      color: [0.5, 1.0, 0.5, 1]
    )

    # Claimed counter label
    @ui_objects << Text.new('Claimed:', x: 490, y: 210, size: 18, color: 'white')
    @claimed_text = Text.new(
      "0 / #{@seats_to_win}",
      x: 490, y: 235, size: 28, color: 'lime'
    )
    @ui_objects << @claimed_text

    # Timer label
    @ui_objects << Text.new('Time:', x: 490, y: 295, size: 18, color: 'white')
    @timer_text = Text.new(
      format_time(@game_timer),
      x: 490, y: 320, size: 28, color: 'aqua'
    )
    @ui_objects << @timer_text

    # Legend
    legend_y = 420
    @ui_objects << Text.new('Legend:', x: 490, y: legend_y, size: 16, color: [0.7,0.7,0.7,1])
    [
      [COLOR_OPEN,     'Open — click me!',  legend_y + 28],
      [COLOR_OCCUPIED, 'Occupied',           legend_y + 56],
      [COLOR_OWNED,    'Claimed ✓',          legend_y + 84],
    ].each do |color, label, ly|
      @ui_objects << Square.new(x: 490, y: ly, size: 18, color: color)
      @ui_objects << Text.new(label, x: 518, y: ly, size: 16, color: 'white')
    end
  end

  # ── Tick methods (called every frame from update) ─────────────────────────

  # Decrement each open seat's timer; flip back to :occupied when it expires
  def tick_open_seats(dt)
    @seats.each do |seat|
      next unless seat.state == :open

      seat.open_timer -= dt
      if seat.open_timer <= 0
        seat.state = :occupied
      end
    end
  end

  # Periodically open a random batch of currently-occupied seats
  def tick_flip_timer(dt)
    @flip_timer += dt
    return unless @flip_timer >= @flip_interval

    @flip_timer = 0.0
    open_random_seats
  end

  def tick_game_timer(dt)
    @game_timer -= dt
    if @game_timer <= 0
      @game_timer = 0
      @failed     = true unless @completed
      @fail_reason = 'Not enough seats claimed'
    end
  end

  # ── Seat selection logic ──────────────────────────────────────────────────

  # Open up to @max_open occupied seats at random.
  # Never opens blocked or already-owned seats.
  def open_random_seats
    # How many seats are already open right now?
    currently_open = @seats.count { |s| s.state == :open }
    slots_available = @max_open - currently_open
    return if slots_available <= 0

    # Candidate pool: only :occupied (not :blocked, :owned, :open)
    candidates = @seats.select { |s| s.state == :occupied }
    return if candidates.empty?

    # Pick randomly; Ruby's Array#sample with a count is perfect here
    to_open = candidates.sample([slots_available, candidates.length].min)
    to_open.each do |seat|
      seat.state      = :open
      seat.open_timer = @open_duration
    end
  end

  # ── HUD refresh ──────────────────────────────────────────────────────────

  def refresh_hud
    @claimed_text.text  = "#{@owned_count} / #{@seats_to_win}"
    @timer_text.text    = format_time(@game_timer)

    # Timer turns red when under 5 seconds
    @timer_text.color   = @game_timer <= 5.0 ? 'red' : 'aqua'

    # Claimed counter turns gold when goal is met
    @claimed_text.color = @owned_count >= @seats_to_win ? 'gold' : 'lime'
  end

  # ── Geometry helpers ─────────────────────────────────────────────────────

  # Pixel x position for a given column index (0–5)
  def seat_x(col_idx)
    base = GRID_X + col_idx * (SEAT_W + H_GAP)
    # Add aisle gap for columns D, E, F (indices 3, 4, 5)
    col_idx >= 3 ? base + AISLE_W : base
  end

  # Pixel y position for a given row index (0–12)
  def seat_y(row_idx)
    GRID_Y + row_idx * (SEAT_H + V_GAP)
  end

  def grid_total_width
    6 * (SEAT_W + H_GAP) + AISLE_W
  end

  def format_time(seconds)
    s = seconds.ceil.clamp(0, 99)
    format('%02d', s)
  end
end
