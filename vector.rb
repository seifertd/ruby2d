# Simple 3d vector (can be used as a point, vel or acc)
class Vector
  attr_accessor :x, :y, :z
  def initialize(*coords)
    coords.flatten!
    if coords.first.is_a? Vector
      vec = coords.first
      @x, @y, @z = vec.x, vec.y, vec.z
    else
      @x, @y, @z = coords
    end
  end
  def to_s
    "(#{[@x, @y, @z].compact.join(",")})"
  end
  def magnitude
    Math.sqrt((@x || 0) ** 2 + (@y || 0) ** 2 + (@z || 0) ** 2)
  end
  def unit
    mag = self.magnitude
    u = Vector.new((@x || 0) / mag, (@y || 0) / mag)
    if @z
      u.z = @z / mag
    end
    u
  end
  def normal
    Vector.new([-@y, @x])
  end
  def add!(other)
    @x = (@x || 0) + (other.x || 0)
    @y = (@y || 0) + (other.y || 0)
    if @z
      @z = @z + (other.z || 0)
    end
    self
  end
  def +(other)
    coords = []
    coords << (@x || 0) + (other.x || 0)
    coords << (@y || 0) + (other.y || 0)
    if @z && other.z
      coords << @z + other.z
    end
    Vector.new coords
  end
  def -(other)
    coords = []
    coords << (@x || 0) - (other.x || 0)
    coords << (@y || 0) - (other.y || 0)
    if @z && other.z
      coords << @z - other.z
    end
    Vector.new coords
  end
  def /(num)
    Vector.new [@x, @y, @z].compact.map{|c| c.to_f/num.to_f}
  end
  def *(num)
    Vector.new [@x, @y, @z].compact.map{|c| c.to_f*num.to_f}
  end
  def dot(other)
    @x * other.x + @y * other.y + (@z || 0) * (other.z || 0)
  end
end
