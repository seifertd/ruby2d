require 'ruby2d'

# Simple 3d vector (can be used as a point, vel or acc)
class Vector
  attr_accessor :x, :y, :z
  def initialize(coords)
    @x, @y, @z = coords
  end
  def +(other)
    Vector.new [@x + other.x, @y + other.y]
  end
end

class LehmerRand
  def initialize(seed)
    @proc_gen = seed || 0
  end

  def rnd
    @proc_gen += 0xe120fc15
    tmp = @proc_gen * 0x4a39b70d
    m1 = (tmp >> 32) ^ tmp
    tmp = m1 * 0x12fad5c9
    ((tmp >> 32) ^ tmp) & 0xFFFFFFFF
  end

  def rnd_dbl(min,max)
    (rnd().to_f / 0xFFFFFFFF.to_f) * (max - min) + min
  end

  def rnd_int(min,max)
    rnd() % (max - min) + min
  end
end

class Planet
  attr_reader :distance, :radius, :foliage, :minerals, :water, :gasses, :temp, :population, :ring, :moons
  def initialize(rnd, distance)
    @distance = distance
    @radius = rnd.rnd_dbl(2.0, 10.0)
    @temp = rnd.rnd_dbl(-200.0, 300.0)
    f = rnd.rnd_dbl(0.0, 1.0)
    m = rnd.rnd_dbl(0.0, 1.0)
    g = rnd.rnd_dbl(0.0, 1.0)
    w = rnd.rnd_dbl(0.0, 1.0)
    sum = 1.0 / ( f + m + g + w)
    @foilage = f * sum
    @minerals = m * sum
    @gasses = g * sum
    @water = w * sum
    @population = [rnd.rnd_int(-5_000_000, 20_000_000), 0].max
    @ring = rnd.rnd_int(0, 10) == 1
    @moons = []
    n_moons = [rnd.rnd_int(-5, 5), 0].max
    n_moons.times do
      @moons << rnd.rnd_dbl(0.5, 2.5)
    end
  end
end

class Star
  COLORS = [ "#FFFFFF", "#D9FFFF", "#A3FFFF", "#FFC8C8", "#FFCB9D", "#9F9FFF", "#415EFF", "#28199D" ]
  attr_reader :exists, :radius, :color, :planets
  def initialize(seedx, seedy)
    @rnd = LehmerRand.new((seedx & 0XFFFF) << 16 | (seedy & 0XFFFF))
    @exists = @rnd.rnd_int(0,20) == 1
    return unless @exists
    @radius = @rnd.rnd_dbl(1.0, 10.0)
    @color = COLORS[@rnd.rnd_int(0,8)]
  end

  def generate_system
    @planets = []
    distance = @rnd.rnd_dbl(60.0, 200.0)
    n_planets = @rnd.rnd_int(0, 10)
    n_planets.times do
      @planets << Planet.new(@rnd, distance)
      distance += @rnd.rnd_dbl(20.0, 200.0)
    end
  end
end

# Setup
set title: "Universe!", width: 512, height: 480

# State
@galaxy_offset = Vector.new [0,0]
@star_selected = false
@sectors = Vector.new [512 / 16, 480 / 16]
@elapsed_time = 1.0 / 60.0 # engine runs at 60hz
@draw_system = nil

on :key_held do |event|
  if event.key == 'w'
    @galaxy_offset.y -= 50.0 * @elapsed_time
  elsif event.key == 's'
    @galaxy_offset.y += 50.0 * @elapsed_time
  elsif event.key == 'a'
    @galaxy_offset.x -= 50.0 * @elapsed_time
  elsif event.key == 'd'
    @galaxy_offset.x += 50.0 * @elapsed_time
  end
end

on :mouse_down do |event|
  if event.button == :left
    mouse = Vector.new [event.x / 16, event.y / 16]
    seedx = (@galaxy_offset.x.to_i + mouse.x) & 0xFFFFFFFF
    seedy = (@galaxy_offset.y.to_i + mouse.y) & 0xFFFFFFFF
    star = Star.new(seedx,seedy)
    if star.exists
      star.generate_system
      @draw_system = star
    else
      @draw_system = nil
    end
  end
end

update do
  clear
  mouse = Vector.new [get(:mouse_x)/16, get(:mouse_y)/16]
  universe_mouse = mouse + @galaxy_offset
  @sectors.x.times do |x_sector|
    @sectors.y.times do |y_sector|
      seedx = (@galaxy_offset.x.to_i + x_sector) & 0xFFFFFFFF
      seedy = (@galaxy_offset.y.to_i + y_sector) & 0xFFFFFFFF
      star = Star.new(seedx,seedy)
      if star.exists
        Circle.new x: (x_sector * 16 + 8), y: (y_sector * 16 + 8), radius: star.radius, color: star.color, z: 10
        if mouse.x == x_sector && mouse.y == y_sector
          Circle.new x: (x_sector * 16 + 8), y: (y_sector * 16 + 8), radius: 12, color: 'yellow', z: 1
          Circle.new x: (x_sector * 16 + 8), y: (y_sector * 16 + 8), radius: 11, color: 'black', z: 2
        end
      end
    end
  end
  if @draw_system
    scale = 6.0
    pscale = 2.0
    star = @draw_system
    Rectangle.new x: 8, y: 240, width: 496, height: 232, color: 'white', z: 100
    Rectangle.new x: 9, y: 241, width: 494, height: 230, color: 'navy', z: 101
    body = Vector.new [14, 300]
    body.x += (star.radius * 2) * scale
    Circle.new x: body.x, y: body.y, radius: star.radius * scale, color: star.color, z: 200
    body.x += (star.radius * 2) * scale + 8
    star.planets.each do |planet|
      body.x += (planet.radius * 2)
      Circle.new x: body.x, y: body.y, radius: planet.radius * pscale, color: 'red', z: 200
      moon = Vector.new [body.x, body.y + (planet.radius * 2.0 * pscale) + 10]
      planet.moons.each do |mr|
        moon.y += (mr * 2)
        Circle.new x: moon.x, y: moon.y, radius: mr * pscale, color: 'gray', z: 200
        moon.y += (mr * 2) + 10
      end
      body.x += (planet.radius * 2 * pscale) + 8
    end
  end
end

show
