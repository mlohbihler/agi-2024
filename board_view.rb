class BoardView
  def initialize(board, index, is_row, from, to)
    @board = board
    @index = index
    @is_row = is_row
    @from = from
    @to = to
  end

  def length
    @to - @from
  end

  def []=(index, value)
    if @is_row
      @board[@index, @from + index] = value
    else
      @board[@from + index, @index] = value
    end
  end

  def [](index)
    if @is_row
      @board[@index, @from + index]
    else
      @board[@from + index, @index]
    end
  end

  def to_clues
    result = []
    previous = nil
    count = 0
    (@from...@to).map do |i|
      current = self[i]
      if current != previous
        if !previous.nil?
          result << Clue.new(count, previous)
        end
        count = 1
        previous = current
      else
        count += 1
      end
    end

    result << Clue.new(count, previous) if !previous.nil?

    result
  end

  def to_s
    (@from...@to).map { |i| self[i].nil? ? "." : self[i].to_s }.join
  end
end
