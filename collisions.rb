require 'ruby2d'
require_relative "./vector"

class Polygon
  attr_reader :p, :o
  attr_accessor :angle, :pos, :overlap
  def initialize(x, y, angle)
    @p = []
    @o = []
    @angle = angle
    @pos = Vector.new([x, y])
    @overlap = false
  end

  def axes
    verts.map.with_index do |v,idx|
      p1 = v
      p2 = verts[(idx + 1) % @o.size]
      (p1 - p2).normal
    end
  end

  def edges
    verts.map.with_index do |v, idx|
      {start: v, end: verts[(idx+1) % o.size]}
    end
  end

  def diags
    verts.map do |v|
      {start: self.pos, end: v}
    end
  end

  def overlaps(shape, debug = false)
    #overlaps_sat(shape, debug)
    overlaps_diags(shape, debug)
  end

  def overlaps_diags(shape, debug)
    shapes = [self, shape]
    2.times do
      s = shapes.first
      o = shapes.last
      s.diags.each do |diag|
        o.edges.each do |edge|
          r1s = diag[:start]
          r1e = diag[:end]
          r2s = edge[:start]
          r2e = edge[:end]
          h = (r2e.x - r2s.x) * (r1s.y - r1e.y) - (r1s.x - r1e.x) * (r2e.y - r2s.y)
          t1 = ((r2s.y - r2e.y) * (r1s.x - r2s.x) + (r2e.x - r2s.x) * (r1s.y - r2s.y)) / h
          t2 = ((r1s.y - r1e.y) * (r1s.x - r2s.x) + (r1e.x - r1s.x) * (r1s.y - r2s.y)) / h
          if (t1 > 0.0 && t1 < 1.0 && t2 > 0.0 && t2 < 1.0)
            return true
          end
        end
      end
      shapes.reverse!
    end
    false
  end

  def overlaps_sat(shape, debug = false)
    [axes, shape.axes].each do |axes|
      axes.each do |axis|
        p1 = projection(axis)
        p2 = shape.projection(axis)
        return false if p1[1] < p2[0] || p1[0] > p2[1]
      end
    end
    true
  end

  def projection(axis)
     min = axis.dot(verts[0])
     max = min
     (1...verts.size).each do |j|
       proj = axis.dot(verts[j])
       if proj < min
         min = proj
       elsif proj > max
         max = proj
       end
     end
     [min, max]
  end

  private

  def verts
    @p || @o
  end
end

WIDTH = 420
HEIGHT = 420

@shapes = []
@shapes << Polygon.new(100,100,0.0)
(1..5).each do |i|
  @shapes[0].o << Vector.new([30.0 * Math.cos(Math::PI * 0.4 * i),
    30.0 * Math.sin(Math::PI * 0.4 * i)])
end
@shapes << Polygon.new(200,150,0.0)
(1..3).each do |i|
  @shapes[1].o << Vector.new([20.0 * Math.cos(Math::PI * 0.6667 * i),
    20.0 * Math.sin(Math::PI * 0.66667 * i)])
end
@shapes << Polygon.new(50,200,0.0)
@shapes[2].o << Vector.new([-30,-30])
@shapes[2].o << Vector.new([-30,30])
@shapes[2].o << Vector.new([30,30])
@shapes[2].o << Vector.new([30,-30])
set title: "Collisions", height: HEIGHT, width: WIDTH

#@shapes.each do |s|
#  s.angle = Math.atan2(s.o.last.y, s.o.last.x)
#  puts "p0: #{s.o.last.inspect} angle: #{s.angle * 180.0 / Math::PI}"
#end

@elapsed = 1.0 / 60.0
@selected = 0

on :key_held do |event|
  if event.key == 'w'
    @shapes[@selected].pos.x += Math.cos(@shapes[@selected].angle) * 60.0 * @elapsed
    @shapes[@selected].pos.y += Math.sin(@shapes[@selected].angle) * 60.0 * @elapsed
  elsif event.key == 's'
    @shapes[@selected].pos.x -= Math.cos(@shapes[@selected].angle) * 60.0 * @elapsed
    @shapes[@selected].pos.y -= Math.sin(@shapes[@selected].angle) * 60.0 * @elapsed
  elsif event.key == 'a'
    @shapes[@selected].angle -= 2.0 * @elapsed
  elsif event.key == 'd'
    @shapes[@selected].angle += 2.0 * @elapsed
  end
end

on :key_down do |event|
  if event.key == 'space'
    @selected += 1
    @selected = 0 if @selected >= 3
  end
end

update do
  clear
  @shapes.each_with_index do |shape, idx|
    shape.overlap = false
    shape.p.clear
    shape.o.each do |o|
      shape.p <<
       Vector.new([o.x * Math.cos(shape.angle) - o.y * Math.sin(shape.angle) + shape.pos.x,
         o.x * Math.sin(shape.angle) + o.y * Math.cos(shape.angle) + shape.pos.y])
    end
  end

  @shapes.each_with_index do |shape, idx|
    @shapes.each do |s2|
      next if s2 == shape
      shape.overlap ||= shape.overlaps(s2)
    end

    color = @selected == idx ? 'yellow' : 'white'
    color = 'red' if shape.overlap

    0.upto(shape.p.size - 1) do |i|
      j = (i + 1) % shape.p.size
      p1 = shape.p[i]
      p2 = shape.p[j]
      Line.new(x1: p1.x, y1: p1.y, x2: p2.x, y2: p2.y, width: 2, color: color)
    end
    if idx == 2
      # square
      midpoint = (shape.p[-1] + shape.p[-2]) / 2
      Line.new(x1: midpoint.x, y1: midpoint.y, x2: shape.pos.x, y2: shape.pos.y,
        width: 2, color: color)
    else
      Line.new(x1: shape.p.last.x, y1: shape.p.last.y, x2: shape.pos.x, y2: shape.pos.y,
        width: 2, color: color)
    end
  end
end

show
