require 'gosu'
require_relative './vector'

PI = 3.14159

class Body
  attr_accessor :pos, :vel, :acc, :radius, :mass
  def initialize(x, y, r, m, vx, vy)
    @pos = Vector.new(x, y)
    @radius = r
    @mass = m
    @vel = Vector.new(vx, vy)
    @acc = Vector.new(0, 0)
  end

  def collides?(other)
    return false if other == self
    dx = self.pos.x - other.pos.x
    dy = self.pos.y - other.pos.y
    r2 = self.radius + other.radius
    return dx * dx + dy * dy <= r2 * r2
  end

  def collide_with(other)
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
    puts "COLLISION! r=#{"%.5e" % nr} m=#{"%.5e" % (biggest.mass + smallest.mass)} vx=#{"%.5e" % vnx} vy=#{"%.5e" % vny}"
    Body.new(biggest.pos.x, biggest.pos.y, nr, biggest.mass + smallest.mass, vnx, vny)
  end
end

class NBody < Gosu::Window
  CIRCLE_STEP = 10
  G = 6.674e-11
  # meters per pixel
  MPP = 5e5
  attr_reader :bodies, :width, :height

  def initialize(width, height)
    @width = width
    @height = height
    @running = true
    @pin_barycenter = false
    @offset = Vector.new(@width/2, @height/2)
    @display = true
    @scale = 0.1
    @elapsed = 0
    # seconds per tick
    @spt = 60
    @bodies = [
      Body.new(0, 0, 30 * MPP, 5e28, 0, 0)
    ]
    center = @bodies.first
    random_gen(50, 1.0, false)
    #random_with_moons(5,3)
    super(width, height)
    @font = Gosu::Font.new(self, Gosu::default_font_name, 20)
    self.caption = "N-Body Problem"
  end

  def needs_cursor?
    true
  end

  def random_with_moons(n, m)
    @scale = 0.3
    center = @bodies.first
    n.times do |i|
      x = (-@width * 4 + rand(@width) * 8) * MPP
      y = (-@height * 4 + rand(@height)* 8) * MPP
      r = Vector.new(center.pos.x - x, center.pos.y - y)
      circular_orbit_vel =  Math.sqrt(G * center.mass / r.magnitude)
      vel = r.unit.normal * circular_orbit_vel
      mass = rand() * 1e26
      radius = (8 + rand(8)) * MPP
      @bodies <<  Body.new(x, y, radius, mass, vel.x, vel.y)
      body = @bodies.last
      puts "BODY: #{i}: m:#{"%.5e" % body.mass} vel:#{"%.5e" % body.vel.x},#{"%.5e" % body.vel.y} pos:#{"%.5e" % body.pos.x},#{"%.5e" % body.pos.y}"

      m.times do |j|
        #moon
        d = radius + (10 + rand(40)) * MPP
        # moon unit normal
        moon_orbit_vel = Math.sqrt(G * mass / d)
        sign = j == 1 ? 1 : -1
        moon_un = Vector.new(0, sign)
        moon_vel = vel + (moon_un * moon_orbit_vel)
        moon_mass = 1e7 * rand()
        moon_radius = (1 + rand(4)) * MPP
        @bodies <<  Body.new(x - sign * d, y, moon_radius, moon_mass, moon_vel.x, moon_vel.y)
        body = @bodies.last
        puts "MOON: #{i}: m:#{"%.5e" % body.mass} vel:#{"%.5e" % body.vel.x},#{"%.5e" % body.vel.y} pos:#{"%.5e" % body.pos.x},#{"%.5e" % body.pos.y}"
      end
    end
  end

  def random_gen(n, pf = 0.2, dense = true)
    @scale = 0.3
    center = @bodies.first
    n.times do |i|
      if dense
        x = (-@width / 4 + rand(@width) / 2) * MPP
        y = (-@height / 4 + rand(@height) / 2) * MPP
      else
        x = (-@width / 2 + rand(@width)) * MPP
        y = (-@height / 2 + rand(@height)) * MPP
      end
      r = Vector.new(center.pos.x - x, center.pos.y - y)
      circular_orbit_vel =  Math.sqrt(G * center.mass / r.magnitude)
      vel = r.unit.normal * circular_orbit_vel
      # Perturb just a tad
      vel.x = vel.x * (1.0 - (pf/2.0) + rand() * pf)
      vel.y = vel.y * (1.0 - (pf/2.0) + rand() * pf)
      base_mass = i < (n/2) ? 1e22 : 1e7
      base_radius = i < (n/2) ? 10 : 4
      @bodies <<  Body.new(x, y, (1 + rand(base_radius)) * MPP, base_mass * rand(), vel.x, vel.y)
      body = @bodies.last
      puts "BODY: #{i}: m:#{"%.5e" % body.mass} vel:#{"%.5e" % body.vel.x},#{"%.5e" % body.vel.y} pos:#{"%.5e" % body.pos.x},#{"%.5e" % body.pos.y}"
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
      @bodies.each do |body|
        body.acc.x = body.acc.y = 0
        @bodies.each do |body2|
          next if body2 == body
          # Accel of body2 on body
          d = Math.sqrt((body.pos.x - body2.pos.x)**2 + (body.pos.y - body2.pos.y)**2)
          acc_vect = Vector.new((body2.pos.x - body.pos.x) / d, (body2.pos.y - body.pos.y) / d)
          acc_vect = Vector.new((body2.pos.x - body.pos.x) / d, (body2.pos.y - body.pos.y) / d)
          body.acc.add! (acc_vect * (G * body2.mass / (d*d)))
        end
      end
      @bodies.each do |body|
        body.vel.add! body.acc

        body.pos.add! body.vel

        colliding = []
        @bodies.each do |body2|
          if body.collides?(body2)
            colliding << [body, body2]
          end
        end
        colliding.each do |pair|
          body1 = pair.first
          body2 = pair.last
          @bodies.delete(body1)
          @bodies.delete(body2)
          @bodies << body1.collide_with(body2)
        end
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
    elsif id == Gosu::KbB
      @pin_barycenter = !@pin_barycenter
    elsif id == Gosu::KbI
      @display = !@display
    end

  end

  def energy
    @bodies.map do |body|
      0.5 * body.mass * Math.sqrt(body.vel.x ** 2 + body.vel.y ** 2)
    end.sum
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
      @offset.x + world.x * @scale / MPP,
      @offset.y + world.y * @scale / MPP
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
    bc_sc = world_to_screen(barycenter)
    if @pin_barycenter
      @offset.x = @offset.y = 0
      @offset = Vector.new(@width/2,@height/2) + world_to_screen(bc - @bodies.first.pos)
    end
    draw_circle(bc_sc.x, bc_sc.y, 20 * @scale * MPP, Gosu::Color::RED)
    @bodies.each do |body|
      screen_pos = world_to_screen(body.pos)
      if screen_pos.x > @offset.x + 10000 || screen_pos.x < @offset.x - 10000 ||
         screen_pos.y > @offset.y + 10000 || screen_pos.x < @offset.y - 10000
        @bodies.delete(body)
        puts "REMOVE: vel: #{"%.5e" % body.vel.x},#{"%.5e" % body.vel.y} pos: #{"%.5e" % body.pos.x},#{"%.5e" % body.pos.y}"
        next
      end
      draw_circle(screen_pos.x, screen_pos.y, body.radius * @scale / MPP, Gosu::Color::WHITE)
    end
    if @display
      @font.draw_text("N: #{@bodies.size}", 600, 20, 1)
      @font.draw_text("T: #{@spt}", 600, 45, 1)
      @font.draw_text("S: #{@scale.round(5)}", 600, 70, 1)
      @font.draw_text("E: #{elapsed}", 600, 95, 1)
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
    0.step(360, step) do |a1|
      a2 = a1 + step
      draw_line cx + Gosu.offset_x(a1, r), cy + Gosu.offset_y(a1, r), color, cx + Gosu.offset_x(a2, r), cy + Gosu.offset_y(a2, r), color, 9999
    end
  end
end

NBody.new(800,800).show
