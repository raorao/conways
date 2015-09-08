require 'forwardable'
require 'colored'

class Conway
  class BoardError < StandardError; end
  def initialize live_cell_indeces
    @grandparent_board = nil
    @parent_board      = nil
    @current_board     = Board::Generator.from_live_indeces live_cell_indeces
  end

  def age!
    @grandparent_board = @parent_board
    @parent_board      = @current_board
    @current_board     = Board::Generator.for_next_generation board

    raise BoardError.new 'board is stable'        if frozen?
    raise BoardError.new 'board is stuck in loop' if stuck_in_loop?
  end

  def frozen?
    @parent_board == @current_board
  end

  def stuck_in_loop?
    @grandparent_board && @grandparent_board == @current_board
  end

  def board
    @current_board
  end

  def to_s
    board.to_matrix.map do |row|
      row.join(" ")
    end.join("\n")
  end

  def to_a
    board.to_a
  end

  class Board
    attr_reader :cells

    def initialize cells, old_board = nil
      @cells = cells
      @lookup_table = old_board ? old_board.lookup_table : {}
      add_to_lookup_table
    end

    def to_a
      live_cells.map(&:to_a)
    end

    def add_to_lookup_table
      @cells.each do |cell|
        @lookup_table[cell.x] ||= {}
        @lookup_table[cell.x][cell.y] = cell
      end
    end

    def to_matrix
      global_boundary = @cells.min_by(&:y).y
      @cells.group_by(&:x).sort.map do |row_number, row|
        padding_length = row.min_by(&:y).y - global_boundary
        padding = Array.new(padding_length) { " " }
        padding + row.sort_by(&:y).map(&:to_s)
      end
    end

    def cell_at x, y
      return nil unless @lookup_table.has_key? x
      @lookup_table[x][y]
    end

    def live_cells
      cells.select(&:alive?)
    end

    def dead_cells
      cells.select(&:dead?)
    end

    def == board
      live_cells.sort == board.live_cells.sort
    end

    protected

    attr_reader :lookup_table
  end

  class Cell
    def self.from_cell old_cell, alive
      self.new old_cell.x, old_cell.y, alive
    end

    attr_reader :x, :y
    def initialize x, y, alive
      @x = x
      @y = y
      @alive = alive
    end

    def alive?
      @alive
    end

    def dead?
      !alive?
    end

    def to_s
      alive? ? "o".yellow :  'x'.black
    end

    def to_a
      state
    end

    def neighbor_indeces
      [x,x-1,x+1].product([y,y-1,y+1]) - [self.to_a]
    end

    def == cell
      hash == cell.hash
    end

    alias_method :eql?, :==
    def hash
      [x,y].hash
    end

    protected

    def <=> cell
      state <=> cell.state
    end

    def state
      @state ||= [x,y]
    end
  end

  class Board::Generator
    class << self
      def from_live_indeces live_cell_indeces
        cells = self.cells_from_indeces(live_cell_indeces, alive: true)
        self.new(cells).generate
      end

      def for_next_generation board
        cells = board.cells.map do |cell|
          Cell::Generator.for_next_generation cell, board
        end

        self.new(cells, board).generate
      end

      def cells_from_indeces indeces, alive: raise
        indeces.map do |x,y|
          Cell.new x, y, alive
        end
      end
    end

    def initialize current_cells, board = nil
      @board         = board
      @current_cells = current_cells
    end

    def generate
      Board.new generate_cells, board
    end

    private

    attr_reader :current_cells, :board

    def generate_cells
      current_cells + new_dead_cells
    end

    def alive_cells
      @alive_cells ||= current_cells.select(&:alive?)
    end

    def new_dead_cells
      return [] if alive_cells.length == 0
      all_cell_indeces = indeces_for_axis(:x).product indeces_for_axis(:y)
      new_dead_cell_indeces = all_cell_indeces - current_cells.map(&:to_a)
      cells_from_indeces(new_dead_cell_indeces, alive: false)
    end

    def indeces_for_axis axis
      min, max = alive_cells.map(&axis).minmax
      ( (min - 1)..(max + 1) ).to_a
    end

    def cells_from_indeces indeces, alive: raise
      self.class.cells_from_indeces indeces, alive: alive
    end
  end

  class Cell::Generator
    extend Forwardable

    def self.for_next_generation cell, board
      self.new(cell,board).generate_next
    end

    def initialize cell, board
      @cell = cell
      @board = board
    end

    def generate_next
      Cell.from_cell @cell, alive_next_generation?
    end

    private

    def_delegators :@cell, :neighbor_indeces, :alive?, :dead?
    def_delegators :@board, :cell_at

    def alive_next_generation?
      survives? || regenerates?
    end

    def neighbors
      @neighbors ||= neighbor_indeces.map do |x,y|
        cell_at x, y
      end.compact
    end

    def living_neighbors
      @living_neighbors ||= neighbors.select(&:alive?)
    end

    def survives?
      alive? && [2,3].include?(living_neighbors.count)
    end

    def regenerates?
      dead? && living_neighbors.count == 3
    end
  end
end


if ARGV[0] == 'sandbox'
  random_starting_cells = 20.times.map do
    [rand(1..5), rand(1..5)]
  end.uniq

  game = Conway.new random_starting_cells

  200.times do
    system "clear"
    puts game.to_s
    game.age!
    sleep(0.01)
  end
end