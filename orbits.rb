require 'gosu'
require_relative './vector'

class Body
  attr_reader :pos, :vel, :acc, :radius, :mass
  attr_accessor :g, :orbit_radius
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
    d = Math.sqrt((other.pos.x - self.pos.x)**2 + (other.pos.y - self.pos.y)**2)

    # unit normal along line connecting centers
    normal = Vector.new((other.pos.x - self.pos.x) / d, (other.pos.y - self.pos.y) / d)

    kx = self.vel.x - other.vel.x
    ky = self.vel.y - other.vel.y
    
    p = 2.0 * (normal.x * kx + normal.y * ky) / ( self.mass + other.mass )

    self.vel.x -= p * other.mass * normal.x * 0.95
    self.vel.y -= p * other.mass * normal.y * 0.95
    other.vel.x += p * self.mass * normal.x * 0.95
    other.vel.y += p * self.mass * normal.y * 0.95

    # Displace other away from g to account for possible overlap
    overlap = (d - self.radius - other.radius) * 0.5
    self.pos.x -= overlap * (self.pos.x - other.pos.x) / d
    self.pos.y -= overlap * (self.pos.y - other.pos.y) / d
    other.pos.x += overlap * (self.pos.x - other.pos.x) / d
    other.pos.y += overlap * (self.pos.y - other.pos.y) / d
  end
end

class Orbits < Gosu::Window
  CIRCLE_STEP = 10
  G = 6.674e-11
  # meters per pixel
  MPP = 5e5
  attr_reader :bodies, :width, :height

  def initialize(width, height)
    @width = width
    @height = height
    @running = true
    #@center = Body.new(width / 2, height / 2, 20, 5e26, 0, 0)
    # EARTH: 
    @center = Body.new(width / 2, height / 2, 20, 5e26, 0, 0)
    @bodies = []
    4.times do |i|
      x = 50 + i * 100
      if i == 3
        x = 300
      end
      d = @center.pos.x - x
      vel = Math.sqrt(G * @center.mass / (d * MPP)) / MPP
      period = Math.sqrt(4 * 3.14159 * (d * MPP)**3 / G / @center.mass)
      puts "BODY: #{i}: vel: #{vel.round(3)} period: #{period.round(3)} distance: #{d * MPP/ 1000} km"
      if i == 3
        # let's turn this one elliptical
        vel = vel * 0.7
      end
      @bodies <<  Body.new(x, height / 2,  3, 1e5, 0, vel)
      @bodies.last.orbit_radius = d
    end
    super(width, height)
    self.caption = "Orbits"
  end

  # Assumption: each tick is 1 second. To scale this up to, say, earth - sun - moon, we would need to integrate
  # the equations of motion
  def update
    start = Time.new
    return unless @running
    @bodies.each do |body|
      # Acceleration due to center
      d = Math.sqrt((body.pos.x - @center.pos.x)**2 + (body.pos.y - @center.pos.y)**2)
      # unit acc_vect along line connecting centers
      acc_vect = Vector.new((@center.pos.x - body.pos.x) / d, (@center.pos.y - body.pos.y) / d)
      # Calculate acceration of body in pixels per second
      body.g = acc_vect * (G * @center.mass / (d*d*MPP*MPP) / MPP)
      #puts "G: #{body.g.x.round(3)},#{body.g.y.round(3)} V: #{body.vel.x.round(3)},#{body.vel.y.round(3)} B:#{body.pos.x.round(3)},#{body.pos.y.round(3)} S:#{@center.pos.x},#{@center.pos.y}"

      body.vel.x += body.g.x
      body.vel.y += body.g.y

      body.pos.x += body.vel.x
      body.pos.y += body.vel.y

      @bodies.each do |body2|
        if body.collides?(body2)
          body.collide_with(body2)
        end
        if body.collides?(@center)
          @running = false
        end
      end
    end
    stop = Time.new
    #puts "UPDATE TOOK #{(stop.to_f - start.to_f) * 1000.0} ms"
  end

  def button_down(id)
    if id == Gosu::KbSpace
      @running = !@running
    end
  end

  def draw
    draw_circle(@center.pos.x, @center.pos.y, @center.radius, Gosu::Color::WHITE)
    draw_circle(@center.pos.x, @center.pos.y, 3, Gosu::Color::WHITE,36)
    @bodies.each do |body|
      draw_circle(body.pos.x, body.pos.y, body.radius, Gosu::Color::WHITE)
      theta = Math.atan2(body.g.y, body.g.x)
      endc = Vector.new body.pos.x + 30 * Math.cos(theta), body.pos.y + 30 * Math.sin(theta)
      draw_line(body.pos.x, body.pos.y, Gosu::Color::GREEN, endc.x, endc.y, Gosu::Color::GREEN)
      draw_circle(@center.pos.x, @center.pos.y, body.orbit_radius, Gosu::Color::BLUE)
    end
  end

  private
  def draw_circle(cx,cy,r,color,step = CIRCLE_STEP)      
    0.step(360, step) do |a1|
      a2 = a1 + step
      draw_line cx + Gosu.offset_x(a1, r), cy + Gosu.offset_y(a1, r), color, cx + Gosu.offset_x(a2, r), cy + Gosu.offset_y(a2, r), color, 9999
    end
  end
end

Orbits.new(800,800).show
