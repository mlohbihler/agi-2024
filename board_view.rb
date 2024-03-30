require "./clue_set_view"
require "./puzzle"

require "pry"
require "pry-remote"
require "pry-nav"

class BoardView
  include Enumerable

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

  def in_bounds?(index)
    index >= 0 && index < length
  end

  def padding
    left = nil
    right = nil
    index = 0
    while left.nil? || right.nil?
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

  def to_clues
    result = []
    previous = nil
    count = 0
    each_with_index do |current, i|
      if current != previous
        if !previous.nil?
          result << Clue.new(count, previous, i - count)
        end
        count = 1
        previous = current
      else
        count += 1
      end
    end

    result << Clue.new(count, previous, @to - count) if !previous.nil?

    ClueSet.new(result)
  end

  def view(from, to)
    BoardView.new(@board, @index, @is_row, @from + from, @from + to)
  end

  def fill_from_matches(clue_set, board_clue_set, matches)
    fill_in_between_matches(clue_set, board_clue_set, matches)
  end

  def fill_in_between_matches(clue_set, board_clue_set, matches)
    return if matches.empty?

    binding.pry
    # Fill before the first match
    board_clue_index, clue_index = match.first
    board_clue = board_clue_set[board_index]
    clue_set_view = clue_set.view(from: 0, to: clue_index)
    # if clue_set_view.any?


    #   board_clue = board_clue_set[board_index]
    #     sub_board_view = view(last_board_clue.nil? ? 0 : last_board_clue.to, board_clue.solution)
    #     clue_set_view.fill(sub_board_view)
    #   end

    #   last_clue_index = clue_index
    #   last_board_clue = board_clue
    # end

    # Fill between matches
    # previous_clue_index = nil
    # previous_board_clue = nil
    # matches.each do |board_index, clue_index|
    #   board_clue = board_clue_set[board_index]
    #   clue_set_view = clue_set.view(
    #     from: previous_clue_index.nil? ? 0 : previous_clue_index + 1, to: clue_index
    #   )
    #   if clue_set_view.any?
    #     sub_board_view = view(previous_board_clue.nil? ? 0 : previous_board_clue.to, board_clue.solution)
    #     clue_set_view.fill(sub_board_view)
    #   end

    #   previous_clue_index = clue_index
    #   previous_board_clue = board_clue
    # end

    # From after the last match
  end


    # # Fill gaps between solved that match the same clue.

    # clue_set.each_with_index do |clue, clue_index|
    #   # Find the available range for the clue. Begin by finding any solved clues that bound this
    #   # clue.

  def to_s
    (0...length).map { |i| self[i].nil? ? Puzzle::FANCY_UNKNOWN : self[i].to_s }.join
  end
end
