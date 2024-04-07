require "./clue_set_view"
require "./puzzle"

require "pry"
require "pry-remote"
require "pry-nav"

class BoardView
  include Enumerable

  attr_reader :index, :is_row, :from

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

  def each
    (0...length).each do |i|
      yield(self[i])
    end
  end

  def []=(index, value)
    if @is_row
      @board[@index, @from + index] = value
    else
      @board[@from + index, @index] = value
    end
  end

  def [](index)
    raise "Out of bounds #{index} in [#{@from}, #{@to})" unless in_bounds?(index)

    if @is_row
      @board[@index, @from + index]
    else
      @board[@from + index, @index]
    end
  end

  def fill(from, to, colour)
    (from...to).each { self[_1] = colour }
  end

  def in_bounds?(index)
    index >= 0 && index < length
  end

  def dirty?
    @board.dirty?(@is_row, @index)
  end

  def clean
    @board.clean(@is_row, @index)
  end

  def solve
    @board.solve(@is_row, @index)
  end

  def padding
    left = nil
    right = nil
    index = 0
    while length > 0 && (left.nil? || right.nil?)
      rindex = length - index
      break if left.nil? && right.nil? && rindex < index

      left ||= index if self[index] != Puzzle::BLANK
      right ||= rindex if self[rindex - 1] != Puzzle::BLANK
      index += 1
    end
    left.nil? ? [0, 0] : [left, right]
  end

  def trim
    view(*padding)
  end

  def to_s
    (0...length).map { |i| self[i].nil? ? Puzzle::UNKNOWN : self[i].to_s }.join
  end

  def to_clues
    result = []
    previous = nil
    count = 0
    each_with_index do |current, i|
      if current == previous
        count += 1
      else
        if !previous.nil?
          result << Clue.new(count, previous, i - count)
        end
        count = 1
        previous = current
      end
    end

    result << Clue.new(count, previous, length - count) if !previous.nil?

    ClueSet.new(result)
  end

  def view(from, to = length)
    self.class.new(@board, @index, @is_row, @from + from, @from + to)
  end

  def fill_from_ranges(csv)
    csv.ranges(self).each_with_index do |ranges, index|
      next unless ranges.one?

      clue = csv[index]
      range = ranges.first
      next unless range.size < clue.count * 2

      fill(range.last - clue.count, range.first + clue.count, clue.colour)
    end
  end

  def fill_from_matches(csv, bfi: false)
    board_clue_set = to_clues

    # TODO: there is potential information in the ranges, especially when there are spaces in the
    # board. Get the ranges separately here and fill spaces using that information.

    matches = bfi ? csv.match_bfi(self) : csv.match_recursive(self)

    fill_in_between_matches(csv, board_clue_set, matches)
    fill_from_edges(csv, board_clue_set, matches)
    cap_solved_clues(csv, board_clue_set, matches)
    fill_around_blanks(csv, board_clue_set, matches)

    fill_from_ranges(csv)
  end

  # TODO: Could be useful to recursively call this method on the spaces between matches.
  def fill_in_between_matches(csv, board_clue_set, matches)
    return if matches.empty?

    # Fill before the first match
    board_clue_index, clue_index = matches.first
    board_clue = board_clue_set[board_clue_index]
    spacer = csv.spacer(clue_index, before: true)
    csv.view(0, 0, clue_index).fill(view(0, board_clue.solution - spacer).trim)

    # Fill between matches
    matches.each_cons(2) do |(left_board_i, left_clue_i), (right_board_i, right_clue_i)|
      left_board_clue = board_clue_set[left_board_i]
      right_board_clue = board_clue_set[right_board_i]

      if right_clue_i == left_clue_i
        # The board clues are the same clue. Fill the space between them.
        (left_board_clue.to...right_board_clue.solution).
          each { |i| self[i] = left_board_clue.colour }
      elsif right_clue_i - left_clue_i == 1
        # The clues are adjacent, so extrapolate from them.
        right_clue = csv[right_clue_i]
        left_clue = csv[left_clue_i]

        spacer = csv.spacer(left_clue_i, before: false)

        from = right_board_clue.solution - spacer - left_clue.count
        to = left_board_clue.solution
        (from...to).each { |i| self[i] = left_board_clue.colour }

        from = right_board_clue.to
        to = left_board_clue.to + spacer + right_clue.count
        (from...to).each { |i| self[i] = right_board_clue.colour }

        # Also, fill with spaces between clues.
        from = left_board_clue.solution + spacer + left_clue.count
        to = right_board_clue.to - spacer - right_clue.count
        (from...to).each { |i| self[i] = Puzzle::BLANK }
      else
        left_spacer = csv.spacer(left_clue_i, before: false)
        right_spacer = csv.spacer(right_clue_i, before: true)
        csv.view(left_board_clue.to, left_clue_i + 1, right_clue_i).fill(
          view(left_board_clue.to + left_spacer, right_board_clue.solution - right_spacer).trim
        )
      end
    end

    # Fill after the last match
    board_clue_index = matches.keys.last
    clue_index = matches[board_clue_index]
    board_clue = board_clue_set[board_clue_index]
    spacer = csv.spacer(clue_index, before: false)
    csv.view(board_clue.to, clue_index + 1).fill(view(board_clue.to + spacer).trim)
  end

  def fill_from_edges(csv, board_clue_set, matches)
    return if matches.empty?

    bcsv = board_clue_set.view
    matches.each do |(board_clue_index, clue_index)|
      board_clue = board_clue_set[board_clue_index]
      clue = csv[clue_index]

      left_limit = bcsv.limit(board_clue_index, length, before: true)
      if left_limit
        (board_clue.to...left_limit + clue.count).each { |i| self[i] = clue.colour }
      end

      right_limit = bcsv.limit(board_clue_index, length, before: false)
      if right_limit
        (right_limit - clue.count...board_clue.solution).each { |i| self[i] = clue.colour }
      end
    end

    # Fill blanks from the edges
    board_clue_index, clue_index = matches.first
    if clue_index == 0
      board_clue = board_clue_set[board_clue_index]
      clue = csv[clue_index]
      (0...board_clue.to - clue.count).each { |i| self[i] = Puzzle::BLANK }
    end

    board_clue_index = matches.keys.last
    clue_index = matches[board_clue_index]
    if clue_index == csv.length - 1
      board_clue = board_clue_set[board_clue_index]
      clue = csv[clue_index]
      (board_clue.solution + clue.count...length).each { |i| self[i] = Puzzle::BLANK }
    end
  end

  def cap_solved_clues(csv, board_clue_set, matches)
    matches.each do |board_clue_index, clue_index|
      board_clue = board_clue_set[board_clue_index]
      next unless board_clue.count == csv[clue_index].count

      if clue_index > 0 && csv[clue_index - 1].colour == board_clue.colour
        self[board_clue.solution - 1] = Puzzle::BLANK
      end

      if clue_index < csv.length - 1 && csv[clue_index + 1].colour == board_clue.colour
        self[board_clue.to] = Puzzle::BLANK
      end
    end
  end

  # Fills cells where spaces are between consecutive clues
  def fill_around_blanks(csv, board_clue_set, matches)
    board_clue_set.each_with_index do |board_clue, index|
      next unless board_clue.colour == Puzzle::BLANK
      next unless matches[index - 1]
      next unless matches[index + 1]
      next unless matches[index - 1] == matches[index + 1] - 1 # Ensure consecutive clues.

      # Check the clue on the left.
      left = board_clue_set[index - 1]
      clue = csv[matches[index - 1]]

      # Extend the left match
      fill(board_clue.solution - clue.count, left.solution, left.colour)
      # Extend the spaces leftward
      fill(left.solution + clue.count, board_clue.solution, Puzzle::BLANK)

      # Check the clue on the right.
      right = board_clue_set[index + 1]
      clue = csv[matches[index + 1]]

      # Extend the right match
      fill(right.solution, board_clue.to + clue.count, right.colour)
      # Extend the spaces rightward
      fill(board_clue.to, right.to - clue.count, Puzzle::BLANK)
    end
  end
end
