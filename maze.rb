require 'ruby2d'
require_relative './vector'

NORTH = 1
SOUTH = 2
EAST = 4
WEST = 8
VISITED = 16
DONE = 32

# State
@cell_size = 18
@border_size = 6
@grid_size = @cell_size + @border_size
@height = 25
@width = 40

@maze = Array.new(@width) { Array.new(@height) { 0 } }
@stack = [Vector.new(0,0)]
@maze[0][0] |= VISITED
@total_visited = 1

def screen_coord(coord)
  @border_size + coord * @grid_size
end

# Setup
set title: "2D Maze", width: (@width * (@cell_size + @border_size) + @border_size),
 height: (@height * (@cell_size + @border_size) + @border_size)

update do
  clear
  # Draw maze
  0.upto(@width - 1) do |x|
    0.upto(@height - 1) do |y|
      Square.new(x: screen_coord(x), y: screen_coord(y), size: @cell_size,
        color: 'white')
      # Right edge
      #puts "CHECKING FOR RIGHT EDGE: #{x},#{y}: #{@maze[x][y].inspect} EAST: #{EAST}"
      if x < (@width - 1) && (@maze[x][y] & EAST) > 0
        Rectangle.new(x: screen_coord(x) + @cell_size,
          y: screen_coord(y), width: @border_size, height: @cell_size,
          color: 'white')
      end
      # Bottom edge
      if y < (@height - 1) && (@maze[x][y] & SOUTH) > 0
        Rectangle.new(x: screen_coord(x), y: screen_coord(y) + @cell_size,
          height: @border_size, width: @cell_size, color: 'white')
      end
    end
  end

  # Draw top of stack
  Square.new(x: screen_coord(@stack[0].x), y: screen_coord(@stack[0].y),
    size: @cell_size, color: 'blue', z: 10)

  # Run algo
  10.times do
    if @total_visited < (@width * @height)
      cells = []
      current = @stack[0]
      if (@maze[current.x][current.y] & DONE) == 0
        if current.x > 0 && (@maze[current.x - 1][current.y] & VISITED) == 0
          cells << Vector.new(current.x - 1, current.y, WEST)
        end
        if current.x < @width - 1 && (@maze[current.x + 1][current.y] & VISITED) == 0
          cells << Vector.new(current.x + 1, current.y, EAST)
        end
        if current.y > 0 && (@maze[current.x][current.y - 1] & VISITED) == 0
          cells << Vector.new(current.x, current.y - 1, NORTH)
        end
        if current.y < @height - 1 && (@maze[current.x][current.y + 1] & VISITED) == 0
          cells << Vector.new(current.x, current.y + 1, SOUTH)
        end
      end
      if cells.size > 0
        #puts "POSSIBLE NEIGHBORS: #{cells.inspect}"
        next_cell = cells.sample
        case next_cell.z
        when EAST
          @maze[next_cell.x][next_cell.y] |= WEST
          @maze[current.x][current.y] |= EAST
        when WEST
          @maze[next_cell.x][next_cell.y] |= EAST
          @maze[current.x][current.y] |= WEST
        when NORTH
          @maze[next_cell.x][next_cell.y] |= SOUTH
          @maze[current.x][current.y] |= NORTH
        when SOUTH
          @maze[next_cell.x][next_cell.y] |= NORTH
          @maze[current.x][current.y] |= SOUTH
        end
        @maze[next_cell.x][next_cell.y] |= VISITED
        @stack.unshift(next_cell)
        @total_visited += 1
      else
        @maze[current.x][current.y] |= DONE
        @stack.shift
      end
    end
  end
end

show
