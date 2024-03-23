class Clue
  attr_reader :count, :colour

  def initialize(count, colour = nil)
    if count.is_a?(String)
      @count = count[0..-2].to_i
      @colour = count[-1].to_sym
    else
      @count = count
      @colour = colour
    end
    @solution = nil
  end

  def solve(index)
    @solution = index
  end

  def solved?
    @solution.present?
  end
end
