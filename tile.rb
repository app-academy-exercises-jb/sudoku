require 'colorize'

class Tile
  attr_reader :given, :value
  
  def initialize(value, given=false)
    @value = value
    @given = given
  end

  def value=(x)
    raise "can't change set piece" if self.given == true
    @value = x
  end

  def to_s
    if given
      value.to_s.colorize(:blue)
    else
      value.to_s
    end
  end
end