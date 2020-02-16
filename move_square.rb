require 'ruby2d'

set title: "Moving A Square"

coin = Sprite.new(
  'coin.png',
  clip_width: 84,
  time: 100,
  loop: true
)
coin.play
boom = Sprite.new(
  'boom.png',
  clip_width: 127,
  time: 75,
  loop: true
)
boom.play
# Define a square shape.
@square = Square.new(x: 10, y: 20, size: 25, color: 'blue', opacity: 0.5)

# Define the initial speed (and direction).
@x_speed = 0
@y_speed = 0

# Define what happens when a specific key is pressed.
# Each keypress influences on the  movement along the x and y axis.
on :key_down do |event|
  if event.key == 'j'
    @x_speed = -2
    @y_speed = 0
  elsif event.key == 'l'
    @x_speed = 2
    @y_speed = 0
  elsif event.key == 'i'
    @x_speed = 0
    @y_speed = -2
  elsif event.key == 'k'
    @x_speed = 0
    @y_speed = 2
  else
    @x_speed = @y_speed = 0
  end
end

update do
  @square.x += @x_speed
  @square.y += @y_speed
end

show
