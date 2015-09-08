require './conways.rb'

def assert actual, expected
  raise "got #{actual}, expected #{expected}" unless actual == expected
end

def assert_raise error_class, &block
  block.call
  require 'pry'
  binding.pry
  raise "expected an error of type #{error_class.to_s} to be raised"
rescue error_class
end

# Any live cell with fewer than two live neighbours dies, as if caused by under-population.
# Any live cell with two or three live neighbours lives on to the next generation.
# Any live cell with more than three live neighbours dies, as if by overcrowding.
# Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.

# x x x x
# o o o x
# x x o x
# x x x x
# -------
# x o x x
# x o o x
# x x o x
# x x x x
# -------
# x o o x
# x o o x
# x o o x
# x x x x
# -------
# x o o x
# o x x o
# x o o x
# x x x x


#BOARD TESTS
board = Conway::Board::Generator.from_live_indeces [[1,0]]
assert(board.cells.length, 9)
assert(board.cells.map(&:to_a).sort,
  [ [0,-1], [0,0], [0,1],
    [1,-1], [1,0], [1,1],
    [2,-1], [2,0], [2,1]
  ].sort
)

assert(board.cells.select(&:alive?).map(&:to_a), [[1,0]])
assert(board.cell_at(1,0).to_a, [1,0])

board = Conway::Board::Generator.from_live_indeces [[1,0],[1,1],[1,2],[2,2]]
cell = Conway::Cell.new 0, 1, false

assert(cell.alive?, false)
assert(cell.dead?, true)
next_cell = Conway::Cell::Generator.for_next_generation cell, board
assert(next_cell.alive?,true)

# CELL TESTS
cell = Conway::Cell.new 1, 2, true
assert(cell.to_a, [1,2])
assert(cell.alive?, true)
assert(cell.neighbor_indeces.sort,
  [ [0,1], [0,2], [0,3],
    [1,1],        [1,3],
    [2,1], [2,2], [2,3]
  ].sort
)

second_cell = Conway::Cell.new 1, 2, false
assert(cell == second_cell, true)

third_cell = Conway::Cell.new 0, 2, true
assert(cell == third_cell, false)

# integration test
game = Conway.new [[1,0],[1,1],[1,2],[2,2]]

game.age!
assert(game.to_a.sort, [[0,1],[1,1],[1,2],[2,2]].sort)

game.age!
assert(game.to_a.sort, [[0,1],[0,2],[1,1],[1,2],[2,1],[2,2]].sort)

game.age!
assert(game.to_a.sort, [[0,1],[0,2],[1,0],[1,3],[2,1],[2,2]].sort)

assert_raise(Conway::BoardError) { game.age! }

# testing infinite board
game = Conway.new [[1,1],[1,2],[1,3]]
game.age!
assert(game.to_a.sort, [[0,2],[1,2],[2,2]].sort)

p 'all tests passed'