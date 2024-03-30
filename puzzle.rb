class Puzzle
  BLANK = :" "
  UNKNOWN = ".".freeze
  FANCY_UNKNOWN = "\u00b7".freeze

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
      raise "Clues cannot contain the default colour" if counts[BLANK]

      counts
    end

    top = counter.call(@top_clue_sets)
    left = counter.call(@left_clue_sets)
    raise "Top and left counts do not match: #{top} vs #{left}" if top != left

    # The sums of any rows are not greater than the number of cols and vice versa
    @top_clue_sets.each.with_index do |cs, i|
      len = ClueSetView.new(cs, from: 0, to: cs.length).sum
      max = @board.row_count
      raise "Top clue set #{i + 1} is too long: #{len} vs #{max}" if len > max
    end
    @left_clue_sets.each.with_index do |cs, i|
      len = ClueSetView.new(cs, from: 0, to: cs.length).sum
      max = @board.col_count
      raise "Left clue set #{i + 1} is too long: #{len} vs #{max}" if len > max
    end

    # Blank is defined
    raise "No default colour defined" if @colour_definitions[BLANK].nil?

    # Colour codes must be a single character
    if colour_definitions.keys.any? { |e| e.length != 1 }
      raise "Colour codes must be a single character"
    end

    # All colours are in the definitions, and vice versa
    if (@colour_definitions.keys - [BLANK]).sort != top.keys.sort
      raise "Colour codes do not match clues: #{@colour_definitions.keys} vs #{top.keys}"
    end
  end

  def solve
    # TODO: This is currently trivial because it only can work with empty lines. It has the
    # precursors of being able to split a line into parts by using solved information, but that
    # doesn't work yet.
    fill_rows_by_counting

    partition_clue_sets
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
        clue_set_view = ClueSetView.new(clue_set, from: 0, to: clue_set.length)
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

  def partition_clue_sets
    is_rows = true
    @left_clue_sets.each_with_index do |clue_set, index|
      # next unless @board.dirty?(is_rows, index)

      board_view = BoardView.new(@board, index, is_rows, 0, @board.length(!is_rows))
      matches = clue_set.match(board_view)
      binding.pry


      solved_clue_set = board_view.to_clues

      inner_board_view = BoardView.new(@board, index, is_rows, 0, @board.length(!is_rows))
      # clue_set_view = ClueSetView.new(clue_set, 0, clue_set.length)
      # clue_set_view.fill(board_view)


      # clue_set_view = ClueSetView.new(clue_set, 0, clue_set.length)
      # clue_set_view.fill(board_view)
      # @board.clean(is_rows, index)
      # changes = true

      # => "·····rrrrrr·bbbb····"
      # [2] pry(#<Puzzle>)> matches
      # => {0=>1, 1=>2}
      # [3] pry(#<Puzzle>)> clue_set.to_s
      # => "[1b,7r,8b]"
      # [5] pry(#<Puzzle>)> board_view.to_clues.to_s
      # => "[6r(5),4b(12)]"
      # [6] pry(#<Puzzle>)> clue_set

    end
  end

  def draw
    @board.draw
  end
end
