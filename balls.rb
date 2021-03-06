require 'gosu'
require_relative './vector'

class Ball
  attr_reader :pos, :vel, :radius, :mass
  def initialize(x, y, r, vx, vy)
    @pos = Vector.new(x, y)
    @radius = @mass = r 
    @vel = Vector.new(vx, vy)
  end

  def collides?(ball)
    return false if ball == self
    dx = self.pos.x - ball.pos.x
    dy = self.pos.y - ball.pos.y
    r2 = self.radius + ball.radius
    return dx * dx + dy * dy <= r2 * r2
  end

  def collide_with(ball)
    d = Math.sqrt((ball.pos.x - self.pos.x)**2 + (ball.pos.y - self.pos.y)**2)

    # unit normal along line connecting centers
    nx = (ball.pos.x - self.pos.x) / d
    ny = (ball.pos.y - self.pos.y) / d

    kx = self.vel.x - ball.vel.x
    ky = self.vel.y - ball.vel.y
    
    p = 2.0 * (nx * kx + ny * ky) / ( self.mass + ball.mass )

    self.vel.x -= p * ball.mass * nx * 0.95
    self.vel.y -= p * ball.mass * ny * 0.95
    ball.vel.x += p * self.mass * nx * 0.95
    ball.vel.y += p * self.mass * ny * 0.95

    # Displace ball away from g to account for possible overlap
    overlap = (d - self.radius - ball.radius) * 0.5
    self.pos.x -= overlap * (self.pos.x - ball.pos.x) / d
    self.pos.y -= overlap * (self.pos.y - ball.pos.y) / d
    ball.pos.x += overlap * (self.pos.x - ball.pos.x) / d
    ball.pos.y += overlap * (self.pos.y - ball.pos.y) / d
  end
end

class Ballz < Gosu::Window
  CIRCLE_STEP = 10
  attr_reader :balls, :width, :height

  def initialize(width, height)
    @width = width
    @height = height
    @balls = [
      Ball.new(10, 10, 20, -5 + rand(10), -5 + rand(10))
    ]
    20.times do 
      @balls << Ball.new(rand(width), rand(height), 5 + rand(10), -5 + rand(10), -5 + rand(10))
    end
    super(width, height)
    self.caption = "Ballz!"
  end

  def update
    @balls.each do |ball|
      ball.pos.x += ball.vel.x
      ball.pos.y += ball.vel.y
      
      if ball.pos.x > (self.width - ball.radius)
        ball.pos.x = (self.width - ball.radius)
        ball.vel.x *= -1
      end
      if ball.pos.x < ball.radius
        ball.pos.x = ball.radius
        ball.vel.x *= -1
      end
      if ball.pos.y > (self.height - ball.radius)
        ball.pos.y = (self.height - ball.radius)
        ball.vel.y *= -1
      end
      if ball.pos.y < ball.radius
        ball.pos.y = ball.radius
        ball.vel.y *= -1
      end
      if ball.vel.x.abs() < 0.001
        ball.vel.x = 0.0
      end
      if ball.vel.y.abs() < 0.001
        ball.vel.y = 0.0
      end

      @balls.each do |ball2|
        if ball.collides?(ball2)
          ball.collide_with(ball2)
        end
      end
    end
  end

  def draw
    @balls.each do |ball|
      draw_circle(ball.pos.x, ball.pos.y, ball.radius, Gosu::Color::WHITE)
    end
  end

  private
  def draw_circle(cx,cy,r,color)      
    0.step(360, CIRCLE_STEP) do |a1|
      a2 = a1 + CIRCLE_STEP
      draw_line cx + Gosu.offset_x(a1, r), cy + Gosu.offset_y(a1, r), color, cx + Gosu.offset_x(a2, r), cy + Gosu.offset_y(a2, r), color, 9999
    end
  end
end

Ballz.new(400,400).show
