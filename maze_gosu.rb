require 'gosu'
require_relative './vector'

NORTH = 1
SOUTH = 2
EAST = 4
WEST = 8
VISITED = 16
DONE = 32

PINK = Gosu::Color.argb(0xff_ffc0cb)

class Maze < Gosu::Window
  attr_reader :cell_size, :border_size, :grid_size,
    :height, :width, :maze, :stack, :total_visited
  def initialize
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
    super @width * (@cell_size + @border_size) + @border_size,
        @height * (@cell_size + @border_size) + @border_size
    self.caption = "2D Maze GOSU"
  end

  def screen_coord(coord)
    @border_size + coord * @grid_size
  end

  def update
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

  def draw
    # Draw maze
    0.upto(@width - 1) do |x|
      0.upto(@height - 1) do |y|
        draw_rect(screen_coord(x), screen_coord(y), @cell_size, @cell_size, Gosu::Color::WHITE)
        # Right edge
        #puts "CHECKING FOR RIGHT EDGE: #{x},#{y}: #{@maze[x][y].inspect} EAST: #{EAST}"
        if x < (@width - 1) && (@maze[x][y] & EAST) > 0
          draw_rect(screen_coord(x) + @cell_size, screen_coord(y), @border_size, @cell_size, Gosu::Color::WHITE)
        end
        # Bottom edge
        if y < (@height - 1) && (@maze[x][y] & SOUTH) > 0
          draw_rect(screen_coord(x), screen_coord(y) + @cell_size, @cell_size, @border_size, Gosu::Color::WHITE)
        end
      end
    end
    # Draw top of stack
    draw_rect(screen_coord(@stack[0].x), screen_coord(@stack[0].y), @cell_size, @cell_size, Gosu::Color::BLUE, 10)
    # Draw rest of stack in pink
    @stack[1..-1].each do |coord|
      draw_rect(screen_coord(coord.x), screen_coord(coord.y), @cell_size, @cell_size, PINK, 10)
    end
  end
end

Maze.new.show
