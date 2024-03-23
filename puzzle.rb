class Puzzle
  def self.from_file(name)
    data = JSON.parse(File.open("puzzles/#{name}.json").read)
    new(*data[0..2])
  end

  def initialize(top_clue_sets, left_clue_sets, colour_definitions)
    @top_clue_sets = top_clue_sets.map { |cs| ClueSet.new(cs) }
    @left_clue_sets = left_clue_sets.map { |cs| ClueSet.new(cs) }
    @board = Board.new(@left_clue_sets.length, @top_clue_sets.length)
    @colour_definitions = colour_definitions.transform_keys(&:to_sym)

    # Validations:
    # The counts for each colour are the same for the rows and cols.
    counter = lambda do |clue_sets|
      counts = Hash.new(0)
      clue_sets.each { |cs| cs.each { |c| counts[c.colour] += c.count } }
      counts
    end

    top = counter.call(@top_clue_sets)
    left = counter.call(@left_clue_sets)
    raise "Top and left counts do not match: #{top} vs #{left}" if top != left

    # The sums of any rows are not greater than the number of cols and vice versa
    @top_clue_sets.each.with_index do |cs, i|
      len = ClueSetView.new(cs, 0, cs.length).sum
      max = @board.row_count
      raise "Top clue set #{i + 1} is too long: #{len} vs #{max}" if len > max
    end
    @left_clue_sets.each.with_index do |cs, i|
      len = ClueSetView.new(cs, 0, cs.length).sum
      max = @board.col_count
      raise "Left clue set #{i + 1} is too long: #{len} vs #{max}" if len > max
    end

    # _ is defined
    raise "No default colour defined" if @colour_definitions[:" "].nil?

    # Colour codes must be a single character
    if colour_definitions.keys.any? { |e| e.length != 1 }
      raise "Colour codes must be a single character"
    end

    # All colours are in the definitions, and vice versa
    if (@colour_definitions.keys - [:" "]).sort != top.keys.sort
      raise "Colour codes do not match clues: #{@colour_definitions.keys} vs #{top.keys}"
    end
  end

  def solve
    # TODO: This is currently trivial because it only can work with empty lines. It has the
    # precursors of being able to split a line into parts by using solved information, but that
    # doesn't work yet.
    fill_rows_by_counting
  end

  def fill_rows_by_counting
    # Fills cells by trying to match clues to existing board values, and then creating views of
    # corresponding rows/cols and clues, and using the fill method to try and find more values.
    @board.dirtify

    filler = lambda do |clue_sets, is_rows|
      changes = false
      clue_sets.each_with_index do |clue_set, index|
        next unless @board.dirty?(is_rows, index)

        board_view = BoardView.new(@board, index, is_rows, 0, @board.length(!is_rows))
        clue_set_view = ClueSetView.new(clue_set, 0, clue_set.length)
        clue_set_view.fill(board_view)
        @board.clean(is_rows, index)
        changes = true
      end
      changes
    end

    loop do
      # TODO: write the code that breaks a row/col into unsolved views
      filler.call(@left_clue_sets, true)
      changes_made = filler.call(@top_clue_sets, false)

      break unless changes_made
    end
  end

  def draw
    @board.draw
  end
end
