class ClueSetView
  def initialize(clue_set, from, to)
    @clue_set = clue_set
    @from = from
    @to = to
  end

  def each
    (@from...@to).each do |i|
      yield(@clue_set[i])
    end
  end

  # Calculates the minimum length of all of the clues in this view.
  def sum
    last_clue_colour = nil
    sum = 0
    each do |c|
      spacer = c.colour == last_clue_colour ? 1 : 0
      last_clue_colour = c.colour
      sum += c.count + spacer
    end
    sum
  end

  def fill(board_view)
    diff = board_view.length - sum
    offset = 0
    last_clue_colour = nil
    each do |clue|
      if clue.colour == last_clue_colour
        board_view[offset] = :_ if diff == 0
        offset += 1
      end
      (diff...clue.count).each { |i| board_view[offset + i] = clue.colour }
      offset += clue.count
      last_clue_colour = clue.colour
    end
  end
end
