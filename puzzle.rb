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
      raise "Clues cannot contain the default colour" if counts.key(BLANK)

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

  def for_all_clue_sets
    fn = lambda do |clue_sets, is_rows|
      clue_sets.each_with_index do |cs, index|
        bv = BoardView.new(@board, index, is_rows, 0, @board.length(!is_rows))
        yield(cs, bv)
      end
    end
    fn.call(@left_clue_sets, true)
    fn.call(@top_clue_sets, false)
  end

  def loop_until_clean
    @board.dirtify

    loop do
      for_all_clue_sets do |cs, bv|
        next unless bv.dirty?

        bv.clean
        yield(cs, bv)
      end

      break unless @board.any_dirty?
    end
  end

  def solve
    # Find any row/cols without clues with spaces.
    for_all_clue_sets do |cs, bv|
      (0...bv.length).each { |i| bv.set[i] = Puzzle::BLANK } if cs.empty?
    end

    # Start with a easy method of adding initial information. Then we can move on to move intricate
    # algos.
    fill_rows_by_counting

    # Like this one.
    fill_rows_by_clue_matching

    # TODO: use the "solved" attribute in the clues to know what clues are done, and be able to
    # split views into sub-views
  end

  def fill_rows_by_counting
    # Fills cells by trying to match clues to existing board values, and then creating views of
    # corresponding rows/cols and clues, and using the fill method to try and find more values.
    loop_until_clean do |cs, bv|
      cs.view.fill(bv)
    end
  end

  def fill_rows_by_clue_matching
    @board.dirtify

    loop_until_clean do |cs, bv|
      bv.fill_from_matches(cs.view)
      @board.draw
      binding.pry
    end
  end

  def draw
    @board.draw
  end
end
