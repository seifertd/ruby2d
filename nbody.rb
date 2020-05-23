require 'gosu'
require_relative './vector'

PI = 3.14159

class Body
  attr_accessor :name, :pos, :vel, :acc, :radius, :mass
  def initialize(name, x, y, r, m, vx, vy)
    @name = name
    @pos = Vector.new(x, y)
    @radius = r
    @mass = m
    @vel = Vector.new(vx, vy)
    @acc = Vector.new(0, 0)
  end

  def to_s
    "BODY: #{self.name}: m:#{"%.5e" % self.mass} vel:#{"%.5e" % self.vel.x},#{"%.5e" % self.vel.y} pos:#{"%.5e" % self.pos.x},#{"%.5e" % self.pos.y} r: #{"%.5e" % self.radius}"
  end

  def collides?(other)
    return false if other == self
    dx = self.pos.x - other.pos.x
    dy = self.pos.y - other.pos.y
    r2 = self.radius + other.radius
    dx * dx + dy * dy <= r2 * r2
  end

  def collide_with(other, elapsed)
    biggest = smallest = nil
    if self.mass > other.mass
      biggest = self
      smallest = other
    else
      biggest = other
      smallest = self
    end
    nr = (biggest.radius ** 3 + smallest.radius ** 3 ) ** (1.0 / 3.0)
    vnx = (biggest.mass * biggest.vel.x + smallest.mass * smallest.vel.x) / ( biggest.mass + smallest.mass )
    vny = (biggest.mass * biggest.vel.y + smallest.mass * smallest.vel.y) / ( biggest.mass + smallest.mass )
    puts "#{elapsed} COLLISION! #{biggest.name}<-#{smallest.name} r=#{"%.5e" % nr} m=#{"%.5e" % (biggest.mass + smallest.mass)} vx=#{"%.5e" % vnx} vy=#{"%.5e" % vny}"
    biggest.radius = nr
    biggest.mass = biggest.mass + smallest.mass
    biggest.vel.x = vnx
    biggest.vel.y = vny
    biggest.name = "#{biggest.name}<-#{smallest.name}"
    smallest
  end
end

class NBody < Gosu::Window
  CIRCLE_STEP = 10
  G = 6.674e-11
  MIN_RADIUS = 0.5
  attr_reader :bodies, :width, :height
  attr_accessor :energy

  def initialize(width, height)
    @width = width
    @height = height
    @energy = 0
    # meters per pixel
    @mpp = 5e5
    @running = true
    @pin_barycenter = false
    @pin_planet = nil
    @offset = Vector.new(@width/2, @height/2)
    @display = true
    @scale = 0.1
    @elapsed = 0
    # seconds per tick
    @spt = 60
    @bodies = [
      Body.new('Mother', 0, 0, 30 * @mpp, 5e28, 0, 0)
    ]
    center = @bodies.first
    if ARGV[0] == 'random'
      random_gen((ARGV[1] || 50).to_i, (ARGV[2] || 1.0).to_f, ARGV[3] == 'D')
    elsif ARGV[0] == 'moons'
      random_with_moons((ARGV[1] || 5).to_i, (ARGV[2] || 3).to_i)
    elsif ARGV[0] == 'solar'
      solar_system
    else
      puts "Usage ruby #{$0} (random N PF [D] |moons M N)"
      exit 1
    end
    super(width, height)
    @font = Gosu::Font.new(self, Gosu::default_font_name, 20)
    self.caption = "N-Body Problem"
  end

  def needs_cursor?
    true
  end

  def solar_system
    #Model the inner solar system, prepare to grind your CPU
    @mpp = 5.5e8
    #@mpp = 1e6
    @scale = 1.0
    @spt = 600
    @bodies.clear
    @bodies << Body.new("Sol", 0, 0, 696_340_000, 1.9885e30, 0.0, 0.0)
    @bodies << Body.new("Mercury", 46e9, 0, 2_439_700, 0.33011e24, 0.0, -58.98e3)
    @bodies << Body.new("Venus", 0, 107.48e9, 6_051_800, 4.86750e24, 35.26e3, 0.0)
    @bodies << Body.new("Mars", 0, -206.62e9, 3_389_500, 0.64171e24, -26.50e3, 0.0)
    # Earth at perihelion
    earth = Body.new("Earth", -147.09e9, 0, 6_371_000, 5.9724e24, 0.0, 30.29e3)
    @bodies << earth
    # Moon at perihelion
    luna = Body.new("Luna", earth.pos.x - 0.3633e9, 0, 1_737_400, 0.07346e24, 0.0, earth.vel.y + 1.082e3)
    @bodies << luna
    @bodies.each do |body|
      puts body.to_s
    end
  end

  def random_with_moons(n, m)
    @scale = 0.1
    center = @bodies.first
    n.times do |i|
      x = (-@width * 4 + rand(@width) * 8) * @mpp
      y = (-@height * 4 + rand(@height)* 8) * @mpp
      r = Vector.new(center.pos.x - x, center.pos.y - y)
      circular_orbit_vel =  Math.sqrt(G * center.mass / r.magnitude)
      vel = r.unit.normal * circular_orbit_vel
      mass = rand() * 1e26
      radius = (8 + rand(8)) * @mpp
      @bodies <<  Body.new("P#{i}", x, y, radius, mass, vel.x, vel.y)
      body = @bodies.last
      puts body.to_s

      m.times do |j|
        #moon
        d = radius + (10 + rand(40)) * @mpp
        # moon unit normal
        moon_orbit_vel = Math.sqrt(G * mass / d)
        sign = j == 1 ? 1 : -1
        moon_un = Vector.new(0, sign)
        moon_vel = vel + (moon_un * moon_orbit_vel)
        moon_mass = 1e5 * rand()
        moon_radius = (1 + rand(4)) * @mpp
        @bodies <<  Body.new("P#{i}M#{j}", x - sign * d, y, moon_radius, moon_mass, moon_vel.x, moon_vel.y)
        body = @bodies.last
        puts "MOON: #{body.name}: m:#{"%.5e" % body.mass} vel:#{"%.5e" % body.vel.x},#{"%.5e" % body.vel.y} pos:#{"%.5e" % body.pos.x},#{"%.5e" % body.pos.y}"
      end
    end
  end

  def random_gen(n, pf = 0.2, dense = true)
    @scale = 0.3
    center = @bodies.first
    n.times do |i|
      if dense
        x = (-@width / 4 + rand(@width) / 2) * @mpp
        y = (-@height / 4 + rand(@height) / 2) * @mpp
      else
        x = (-@width + rand(@width) * 2) * @mpp
        y = (-@height + rand(@height) * 2) * @mpp
      end
      r = Vector.new(center.pos.x - x, center.pos.y - y)
      circular_orbit_vel =  Math.sqrt(G * center.mass / r.magnitude)
      vel = r.unit.normal * circular_orbit_vel
      # Perturb just a tad
      vel.x = vel.x * (1.0 - (pf/2.0) + rand() * pf)
      vel.y = vel.y * (1.0 - (pf/2.0) + rand() * pf)
      base_mass = i < (n/2) ? 1e22 : 1e7
      base_radius = i < (n/2) ? 10 : 4
      @bodies <<  Body.new("P#{i}", x, y, (1 + rand(base_radius)) * @mpp, base_mass * rand(), vel.x, vel.y)
      body = @bodies.last
      puts "BODY: #{body.name}: m:#{"%.5e" % body.mass} vel:#{"%.5e" % body.vel.x},#{"%.5e" % body.vel.y} pos:#{"%.5e" % body.pos.x},#{"%.5e" % body.pos.y}"
    end
  end

  # Assumption: each tick is 1 second. To scale this up to, say, earth - sun - moon, we would need to integrate
  # the equations of motion
  def update
    return unless @running
    start = Time.new
    @spt.times do
      @elapsed += 1
      bc = barycenter
      @energy = 0
      @bodies.each do |body|
        # Add KE
        @energy += 0.5 * body.mass * body.vel.magnitude ** 2
        body.acc.x = body.acc.y = 0
        @bodies.each do |body2|
          next if body2 == body
          # Add PE
          @energy += G * body.mass * body2.mass / ( body2.pos - body.pos ).magnitude

          # Accel of body2 on body
          d = Math.sqrt((body.pos.x - body2.pos.x)**2 + (body.pos.y - body2.pos.y)**2)
          acc_vect = Vector.new((body2.pos.x - body.pos.x) / d, (body2.pos.y - body.pos.y) / d)
          body.acc.add! (acc_vect * (G * body2.mass / (d*d)))
        end
      end
      colliding = []
      @bodies.each do |body|
        body.vel.add! body.acc
        body.pos.add! body.vel
        @bodies.each do |body2|
          if body.collides?(body2)
            colliding << [body, body2]
          end
        end
      end
      colliding.each do |pair|
        body1 = pair.first
        body2 = pair.last
        @bodies.delete(body1.collide_with(body2, elapsed))
      end
    end
    if @bodies.size <= 1
      @running = false
    end
    stop = Time.new
    if (delta_t = stop.to_f - start.to_f) > 1.0
      puts "WARN: TICK TOOK #{((stop.to_f - start.to_f) * 1000.0).round(1)} ms"
    end
  end

  def button_down(id)
    if id == Gosu::KbSpace
      @running = !@running
    elsif id == Gosu::KbC
      @offset = Vector.new @width / 2, @height / 2
      @pin_planet = nil
      @pin_barycenter = false
    elsif id == Gosu::KbN
      if !@pin_planet
        @pin_planet = 1
      else
        @pin_planet += 1
        if @pin_planet >= @bodies.length
          @pin_planet = 0
        end
      end
      @bodies.each.with_index do |body, idx|
      end
      @pin_barycenter = false
    elsif id == Gosu::KbB
      @pin_barycenter = !@pin_barycenter
      @pin_planet = nil
    elsif id == Gosu::KbI
      @display = !@display
    end

  end

  def barycenter
    if @bodies.size
      total_mass = 0
      weighted_pos = Vector.new(0,0)
      @bodies.each do |body|
        total_mass += body.mass
        weighted_pos += (body.pos * body.mass)
      end
      weighted_pos / total_mass
    end
  end

  def world_to_screen(world)
    Vector.new(
      @offset.x + world.x * @scale / @mpp,
      @offset.y + world.y * @scale / @mpp
    )
  end

  def draw
    if button_down? Gosu::KbT
      @scale *= 0.9
    elsif button_down? Gosu::KbG
      @scale *= 1.1
    elsif button_down? Gosu::KbW
      @offset.y -= 10
    elsif button_down? Gosu::KbS
      @offset.y += 10
    elsif button_down? Gosu::KbA
      @offset.x -= 10
    elsif button_down? Gosu::KbD
      @offset.x += 10
    elsif button_down? Gosu::KbO
      @spt += 1
    elsif button_down? Gosu::KbL
      if @spt > 2
        @spt -= 1
      end
    end
    bc = barycenter
    if @pin_barycenter
      @offset.x = @offset.y = 0
      @offset = Vector.new(@width/2,@height/2) - world_to_screen(bc)
    elsif @pin_planet
      old_offset = Vector.new @offset
      @offset.x = @offset.y = 0
      planet = @bodies[@pin_planet]
      if planet
        @offset = Vector.new(@width/2, @height/2) - world_to_screen(planet.pos)
      else
        @offset = old_offset
      end
    end
    bc_sc = world_to_screen(barycenter)
    draw_circle(bc_sc.x, bc_sc.y, 10, Gosu::Color::RED)
    @bodies.each do |body|
      screen_pos = world_to_screen(body.pos)
      if screen_pos.x > @width * 20 || screen_pos.x < -@width * 20 
         screen_pos.y > @height * 20 || screen_pos.x < -@height * 20
        @bodies.delete(body)
        puts "#{elapsed} REMOVE: #{body.name}: vel: #{"%.5e" % body.vel.x},#{"%.5e" % body.vel.y} pos: #{"%.5e" % body.pos.x},#{"%.5e" % body.pos.y}"
        next
      end
      draw_circle(screen_pos.x, screen_pos.y, body.radius * @scale / @mpp, Gosu::Color::WHITE)
    end
    if @display
      @font.draw_text("N: #{@bodies.size}", 600, 20, 1)
      @font.draw_text("T: #{@spt}", 600, 45, 1)
      @font.draw_text("S: #{@scale.round(5)}", 600, 70, 1)
      @font.draw_text("t: #{elapsed}", 600, 95, 1)
      @font.draw_text("K: #{"%.5e" % @energy}", 600, 120, 1)
    end
  end

  def elapsed
    d = @elapsed / (3600 * 24)
    h = (@elapsed % (3600 * 24)) / 3600
    m = (@elapsed % 3600) / 60
    s = @elapsed % 60
    "%dd %02dh%02dm%02ds" % [d,h,m,s]
  end

  private
  def draw_circle(cx,cy,r,color,step = CIRCLE_STEP)
    r = [r, MIN_RADIUS].max
    0.step(360, step) do |a1|
      a2 = a1 + step
      draw_line cx + Gosu.offset_x(a1, r), cy + Gosu.offset_y(a1, r), color, cx + Gosu.offset_x(a2, r), cy + Gosu.offset_y(a2, r), color, 9999
    end
  end
end

NBody.new(800,800).show
