require "rainbow"

require "./puzzle"

class Board
  attr_reader :row_count, :col_count

  def initialize(row_count, col_count)
    @board = Array.new(row_count) { Array.new(col_count) }
    @dirty_rows = Array.new(row_count) { true }
    @dirty_cols = Array.new(col_count) { true }
    @row_count = row_count
    @col_count = col_count
  end

  def self.from_strings(strs)
    cols = strs.first.length
    raise "All rows must have the same number of columns" if strs.any? { |r| r.length != cols }

    board = Board.new(strs.length, cols)
    strs.each_with_index do |str, r|
      str.chars.each_with_index { |e, c| board[r, c] = e.to_sym if e != Puzzle::UNKNOWN }
    end
    board
  end

  def view(index, is_row, from = 0, to = length(!is_row))
    BoardView.new(self, index, is_row, from, to)
  end

  def []=(row, col, value)
    if @board[row][col].nil?
      @dirty_rows[row] = true
      @dirty_cols[col] = true
    elsif @board[row][col] != value
      raise "Trying to set (#{row},#{col}) to '#{value}' when it is already '#{@board[row][col]}'"
    end
    @board[row][col] = value
  end

  def [](row, col)
    @board[row][col]
  end

  def dirtify
    @dirty_rows.fill(true)
    @dirty_cols.fill(true)
  end

  def any_dirty?
    @dirty_rows.any? || @dirty_cols.any?
  end

  def dirty?(is_row, index)
    is_row ? @dirty_rows[index] : @dirty_cols[index]
  end

  def length(is_row)
    is_row ? @row_count : @col_count
  end

  def clean(is_row, index)
    _update_dirty(is_row, index, false)
  end

  def solve(is_row, index)
    _update_dirty(is_row, index, nil)
  end

  def solved?
    @dirty_rows.all?(&:nil?) || @dirty_cols.all?(&:nil?)
  end

  def _update_dirty(is_row, index, value)
    if is_row
      @dirty_rows[index] = value
    else
      @dirty_cols[index] = value
    end
  end
end
