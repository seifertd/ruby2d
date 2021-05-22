G = 6.674e-11

require_relative './vector'

m1 = 5e+28

r = Vector.new(-1.0949290061342688e+08,4.294668045397363e+07)

puts "Pos: #{r}"
puts "Distance: #{r.magnitude} m"

circular_orbit_vel =  Math.sqrt(G * m1 / r.magnitude)

puts "Vc: #{circular_orbit_vel} m/s"
puts "u: #{r.unit}"
puts "u.n: #{r.unit.normal}"

vel = r.unit.normal * circular_orbit_vel

puts "V: #{vel}"
