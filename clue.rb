require "pry"
require "pry-remote"
require "pry-nav"

class Clue
  attr_reader :count, :colour, :solution

  def initialize(count, colour = nil, solution = nil)
    if count.is_a?(String)
      @count = count[0..-2].to_i
      @colour = count[-1].to_sym
    else
      @count = count
      @colour = colour
    end
    @solution = solution
  end

  def solve(index)
    @solution = index
  end

  def solved?
    !@solution.nil?
  end

  def to
    solution + count
  end

  def ==(other)
    @count == other.count && @colour == other.colour && @solution == other.solution
  end

  def to_s
    "#{count}#{colour}#{solution ? "(#{solution})" : ''}"
  end

  def valid_location_bfi?(bv, location)
    # Cannot abut the same colour on either side
    return false if location > 0 && bv[location - 1] == colour
    return false if location + count < bv.length && bv[location + count] == colour

    # Can only overlap with unknown or the same colour.
    (location...location + count).all? do |i|
      cell = bv[i]
      cell.nil? || cell == colour
    end
  end
end
