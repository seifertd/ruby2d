# Simple 3d vector (can be used as a point, vel or acc)
class Vector
  attr_accessor :x, :y, :z
  def initialize(coords)
    if coords.is_a? Vector
      @x, @y, @z = coords.x, coords.y, coords.z
    else
      @x, @y, @z = coords
    end
  end
  def normal
    Vector.new([-@y, @x])
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
