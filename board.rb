class Board
  attr_reader :row_count, :col_count

  def initialize(row_count, col_count)
    @board = Array.new(row_count) { Array.new(col_count) }
    @dirty_rows = Array.new(row_count) { true }
    @dirty_cols = Array.new(col_count) { true }
    @row_count = row_count
    @col_count = col_count
  end

  def []=(row, col, value)
    if @board[row][col].nil?
      @dirty_rows[row] = true
      @dirty_cols[col] = true
    elsif @board[row][col] != value
      raise "Trying to set (#{row},#{col}) to ${value} when it is already #{@board[row][col]}"
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

  def dirty?(is_row, index)
    is_row ? @dirty_rows[index] : @dirty_cols[index]
  end

  def length(is_row)
    is_row ? @row_count : @col_count
  end

  def clean(is_row, index)
    if is_row
      @dirty_rows[index] = false
    else
      @dirty_cols[index] = false
    end
  end
  # TODO: after solving a row/col, remember to reset its dirty flag. Afterwards, not before!

  def draw
    puts "   #{(0...@col_count).map { |i| (i + 1) % 10 }.join}"
    puts "   #{'-' * @col_count}"
    @board.each_with_index do |row, i|
      puts "#{(i + 1) % 10}: #{row.map { |e| e.nil? ? '.' : e.to_s }.join} #{@dirty_rows[i] ? 'X' : ' '}"
    end
    puts ""
    puts "   #{@dirty_cols.map { |i| i ? 'X' : ' ' }.join}"
  end
end
