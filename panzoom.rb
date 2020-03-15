require 'ruby2d'
require_relative "./vector"

set title: "Pan and Zoom", width: 1028, height: 768

@offset = Vector.new([514,380])
@dragging = false
@scale = Vector.new([1.0,1.0])
@rot = 0.0

def world_to_screen(world)
  Vector.new [
    @offset.x + world.x * @scale.x * Math.cos(@rot) - world.y * @scale.y * Math.sin(@rot),
    @offset.y + world.x * @scale.x * Math.sin(@rot) + world.y * @scale.y * Math.cos(@rot)
  ]
end

on :key_held do |event|
  case event.key
  when 'w'
    @scale *= 1.1
  when 's'
    @scale *= 0.9
  when 'a'
    @rot -= Math::PI * 2.0 / 72.0
  when 'd'
    @rot += Math::PI * 2.0 / 72.0
  end
end

on :mouse_down do |event|
  case event.button
  when :left
    @dragging = true
  end
end
on :mouse_up do |event|
  case event.button
  when :left
    @dragging = false
  end
end

update do
  clear
  if @dragging
    @offset.x = get :mouse_x
    @offset.y = get :mouse_y
  end
  grid = 5.0
  11.times do |i|
    l1_start = world_to_screen(Vector.new [-grid * 5.0, grid * 5.0 - i.to_f * grid])
    l1_end = world_to_screen(Vector.new [grid * 5.0, grid * 5.0 - i.to_f * grid])
    l2_start = world_to_screen(Vector.new [-grid * 5.0 + i.to_f * grid, -grid * 5.0])
    l2_end = world_to_screen(Vector.new [-grid *5.0 + i.to_f * grid, grid * 5.0])
                         
    Line.new(x1: l1_start.x, y1: l1_start.y, x2: l1_end.x, y2: l1_end.y, color: i == 5 ? 'blue' : 'white', width: 2)
    Line.new(x1: l2_start.x, y1: l2_start.y, x2: l2_end.x, y2: l2_end.y, color: i == 5 ? 'blue' : 'white', width: 2)
  end

  p1 = nil
  (-25.0).step(25.0, 0.1) do |x|
    y = Math.sin(x) * 12.5
    if !p1.nil?
      p2 = world_to_screen(Vector.new([x,y]))
      Line.new(x1: p1.x, y1: p1.y, x2: p2.x, y2: p2.y, color: 'red', width: 2)
      p1 = p2
    else
      p1 = world_to_screen(Vector.new([x,y]))
    end

  end
end

show
