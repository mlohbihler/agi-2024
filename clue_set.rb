class ClueSet
  def initialize(clues)
    if clues.is_a?(String)
      clues = clues.split(",").map { |c| Clue.new(c) }
    end
    @clues = clues
  end

  def length
    @clues.length
  end

  def [](index)
    @clues[index]
  end

  def each(&blk)
    @clues.each(&blk)
  end

  # def sum
  #   last_clue_colour = nil
  #   @clues.sum do |c|
  #     spacer = c.colour == last_clue_colour ? 1 : 0
  #     last_clue_colour = c.colour
  #     c.count + spacer
  #   end
  # end

  # def fill_array(arr)
  #   diff = arr.length - sum
  #   offset = 0
  #   last_clue_colour = nil
  #   @clues.each do |clue|
  #     if clue.colour == last_clue_colour
  #       arr[offset] = :_ if diff == 0
  #       offset += 1
  #     end
  #     (diff...clue.count).each { |i| arr[offset + i] = clue.colour }
  #     offset += clue.count
  #     last_clue_colour = clue.colour
  #   end
  # end
end
