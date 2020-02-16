require 'ruby2d'
require_relative './vector'

WIDTH = 568
HEIGHT = 420
@counter = 0
@new_segment_freqency = 60
@speed_increase_frequency = 10 * 60
@paused = false
@speed = [60, 30, 20, 15, 12, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1]

set title: "Snake!", width: WIDTH, height: HEIGHT

@snake = Struct.new(:head, :segments,
  :dir, :size, :speed).new
@snake.head = Vector.new [WIDTH / 2, HEIGHT / 2]
@snake.segments = []
@snake.dir = :north
@snake.size = 16
@snake.speed = 16

def @snake.move
  case self.dir
  when :north
    self.head.y -= self.size
    if self.head.y < 0
      self.head.y = HEIGHT
    end
  when :south
    self.head.y += self.size
    if self.head.y > HEIGHT
      self.head.y = 0
    end
  when :west
    self.head.x -= self.size
    if self.head.x < 0
      self.head.x = WIDTH
    end
  when :east
    self.head.x += self.size
    if self.head.x > WIDTH
      self.head.x = 0
    end
  end
end

on :key_held do |event|
  if event.key == 'w'
    @snake.dir = :north
  elsif event.key == 's'
    @snake.dir = :south
  elsif event.key == 'a'
    @snake.dir = :west
  elsif event.key == 'd'
    @snake.dir = :east
  end
end

on :key_down do |event|
  if event.key == 'space'
    @paused = !@paused
  end
end

update do
  if !@paused && (@counter % @speed.first) == 0
    clear
    Square.new x: @snake.head.x, y: @snake.head.y, size: @snake.size, color: 'green', z: 9
    @snake.segments.each do |segment|
      Square.new x: segment.x, y: segment.y, size: @snake.size, color: 'orange', z: 10
    end
    if last = @snake.segments.pop
      @snake.segments.insert(0, Vector.new(@snake.head))
    end
    @snake.move
    @snake.segments.each do |segment|
      if @snake.head.x == segment.x && @snake.head.y == segment.y
        @paused = true
        wah = Text.new "Game Over!", x: WIDTH/2 - 100, y: HEIGHT/2 - 20, color: 'red', size: 40, z: 100
        Rectangle.new x: wah.x - 10, y: wah.y - 10, width: wah.width + 20, height: wah.height + 20, color: 'white', z: 90
      end
    end
    Text.new("SCORE: #{@snake.segments.length} SPEED: #{60 / @speed.first}", x: WIDTH/3, y: 20, z: 200)
  end
  if (@counter % @new_segment_freqency) == 0
    last = @snake.segments.last || @snake.head
    @snake.segments << Vector.new(last)
  end
  if (@counter % @speed_increase_frequency) == 0
    @speed.shift if @speed.size > 1
  end
  @counter += 1
end

show
