require "./puzzle"

class ClueSetView
  include Enumerable

  def initialize(clue_set, from: 0, to: clue_set.length)
    @clue_set = clue_set
    @from = from
    @to = to
  end

  def each
    (@from...@to).each do |i|
      yield(@clue_set[i])
    end
  end

  def length
    @to - @from
  end

  def [](index)
    raise "Out of bounds #{index} in [#{@from}, #{@to})" unless in_bounds?(index)

    @clue_set[@from + index]
  end

  def in_bounds?(index)
    index >= 0 && index < length
  end

  def view(from, to = length)
    self.class.new(@clue_set, from: @from + from, to: @from + to)
  end

  def spacer(index, before:)
    if before
      if index == 0
        0
      else
        self[index - 1].colour == self[index].colour ? 1 : 0
      end
    elsif index == length - 1
      0
    else
      self[index + 1].colour == self[index].colour ? 1 : 0
    end
  end

  def limit(index, len, before:)
    if before
      if index == 0
        0
      else
        c = self[index - 1]
        c.colour == self[index].colour ? nil : c.to
      end
    elsif index == length - 1
      len
    else
      c = self[index + 1]
      c.colour == self[index].colour ? nil : c.solution
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

  # TODO: need a way to better accomodate for spaces in determining ranges. Like eliminating clue
  # ranges when they can't fit together inside a view section.
  def ranges(board_view)
    diff = board_view.length - sum
    padding = board_view.padding
    diff -= padding.first + board_view.length - padding.last
    offset = padding.first
    last_clue_colour = nil

    ranges = map do |clue|
      offset += 1 if clue.colour == last_clue_colour
      range = (offset...offset + clue.count + diff)
      offset += clue.count
      last_clue_colour = clue.colour
      range
    end.map.with_index do |range, clue_index|
      # Split ranges by removing locations that contain incompatible solutions.
      clue = self[clue_index]
      clue_ranges = []
      remainder = range
      range.each do |location|
        next if board_view[location].nil? || board_view[location] == clue.colour

        left = (remainder.first...location)
        clue_ranges << left if left.size >= clue.count
        remainder = (location + 1...remainder.last)
      end
      clue_ranges << remainder if remainder.size >= clue.count
      clue_ranges
    end.map.with_index do |ranges, clue_index|
      # Limit ranges where they abut with solutions of the same colour.
      clue = self[clue_index]
      ranges.map do |range|
        while range.size >= clue.count &&
            (
              (range.first > 0 && board_view[range.first - 1] == clue.colour) ||
              (
                range.first + clue.count < board_view.length - 1 &&
                board_view[range.first + clue.count] == clue.colour
              )
            )
          range = (range.first + 1...range.last)
        end
        while range.size >= clue.count &&
            (
              (range.last < board_view.length - 1 && board_view[range.last] == clue.colour) ||
              (
                range.last - clue.count > 0 &&
                board_view[range.last - clue.count - 1] == clue.colour
              )
            )
          range = (range.first...range.last - 1)
        end
        range if range.size >= clue.count
      end.compact
    end

    limit_range_overlap(ranges)
    ranges
  end

  def limit_range_overlap(ranges)
    # Limit ranges so that they don't invalidly overlap.
    # Left to right
    (0...ranges.length - 1).each do |ranges_index|
      left_ranges = ranges[ranges_index]
      right_ranges = ranges[ranges_index + 1]
      left_clue = self[ranges_index]
      right_clue = self[ranges_index + 1]
      spacer = left_clue.colour == right_clue.colour ? 1 : 0

      min = left_ranges.first.first + spacer + left_clue.count
      # binding.pry
      while right_ranges.first.first < min
        range = (min...right_ranges.first.last)
        if range.size < right_clue.count
          right_ranges.shift
        else
          right_ranges[0] = range
        end
      end
    end

    # Right to left
    (ranges.length - 2..0).step(-1).each do |ranges_index|
      left_ranges = ranges[ranges_index]
      right_ranges = ranges[ranges_index + 1]
      left_clue = self[ranges_index]
      right_clue = self[ranges_index + 1]
      spacer = left_clue.colour == right_clue.colour ? 1 : 0

      max = right_ranges.last.last - spacer - right_clue.count
      # binding.pry
      while left_ranges.last.last > max
        range = (left_ranges.last.first...max)
        if range.size < left_clue.count
          left_ranges.pop
        else
          left_ranges[-1] = range
        end
      end
    end
  end

  def match(board_view)
    ranges = ranges(board_view)
    matches = {}
    bvcs = board_view.to_clues
    bvcs.each.each_with_index do |board_clue, board_clue_index|
      next if board_clue.colour == Puzzle::BLANK

      board_clue_from = board_clue.solution
      board_clue_to = board_clue.solution + board_clue.count
      matches[board_clue_index] = []

      ranges.each_with_index do |clue_ranges, clue_index|
        clue = self[clue_index]
        next if clue.colour != board_clue.colour

        clue_ranges.each do |range|
          next unless self.class.contains?(range.first, range.last, board_clue_from, board_clue_to)

          # Determine if the board clue is an exclusive match with the range.
          exclusive = clue_ranges.one? &&
            board_clue_from - range.first < 2 && range.last - board_clue_to < 2

          if exclusive
            raise "Range already has an exclusive match" if matches[board_clue_index].is_a?(Integer)

            matches[board_clue_index] = clue_index
          elsif matches[board_clue_index].is_a?(Array)
            matches[board_clue_index] << clue_index
          end
          break
        end
      end
    end

    mark_solved_clues(self.class.resolve_multiple_matches(matches), bvcs)
  end

  def self.resolve_multiple_matches(matches)
    matches = matches.to_a

    loop do
      change = false

      # Change single elements arrays to ints
      matches.each do |m|
        next unless m[1].is_a?(Array) && m[1].one?

        m[1] = m[1].first
        change = true
      end

      # Remove array elements where their values are less than previous ints
      min = nil
      matches.each do |_bi, ci|
        if ci.is_a?(Array)
          next if min.nil?

          ci.filter! do |e|
            next true if e >= min

            change = true
            false
          end
        else
          min = ci
        end
      end

      # Remove array elements where their values are greater than subsequent ints
      max = nil
      matches.reverse_each do |_bi, ci|
        if ci.is_a?(Array)
          next if max.nil?

          ci.filter! do |e|
            next true if e <= max

            change = true
            false
          end
        else
          max = ci
        end
      end

      break unless change
    end

    matches.select { |m| m[1].is_a?(Integer) }.to_h
  end

  def mark_solved_clues(matches, bvcs)
    matches.each do |(board_clue_index, clue_index)|
      board_clue = bvcs[board_clue_index]
      clue = self[clue_index]
      next unless board_clue.count == clue.count

      clue.solve(board_clue.solution)
    end
  end

  def fill(board_view)
    diff = board_view.length - sum
    offset = 0
    last_clue_colour = nil
    each do |clue|
      if clue.colour == last_clue_colour
        board_view[offset] = Puzzle::BLANK if diff == 0
        offset += 1
      end
      (diff...clue.count).each { |i| board_view[offset + i] = clue.colour }
      offset += clue.count
      last_clue_colour = clue.colour
    end
  end

  def to_s
    "[#{map(&:to_s).join(',')}]"
  end

  def match_bfi(board_view)
    solutions = find_all_solutions_bfi(board_view)
    matches = {}
    board_view.to_clues.each_with_index do |board_clue, board_clue_index|
      next if board_clue.colour == Puzzle::BLANK

      board_clue_from = board_clue.solution
      board_clue_to = board_clue.solution + board_clue.count
      matches[board_clue_index] = nil

      solutions.each do |solution|
        solution.each_with_index do |location, clue_index|
          next if matches[board_clue_index] == clue_index

          clue = self[clue_index]
          clue_from = location
          clue_to = location + clue.count

          if self.class.overlap?(board_clue_from, board_clue_to, clue_from, clue_to)
            if matches[board_clue_index].nil?
              matches[board_clue_index] = clue_index
            elsif matches[board_clue_index] != clue_index
              matches.delete(board_clue_index)
              break
            end
          end
        end

        break unless matches.key?(board_clue_index)
      end
    end

    matches
  end

  def self.overlap?(from_1, to_1, from_2, to_2)
    (from_2 >= from_1 && from_2 < to_1) ||
      (to_2 > from_1 && to_2 <= to_1) ||
      (from_2 < from_1 && to_2 > to_1)
  end

  def self.contains?(container_from, container_to, containee_from, containee_to)
    container_from <= containee_from && container_to >= containee_to
  end

  def find_all_solutions_bfi(board_view)
    max_first_location = board_view.length - sum

    # freedom = board_view.length - sum + 1
    # clues = length
    # puts "freedom: #{freedom}, clues: #{clues}, complexity: #{freedom**clues}"
    # iterations = 0

    solutions = []
    locations = []
    move_last_clue = false
    loop do
      # iterations += 1
      if move_last_clue
        # Increment the current location
        locations[-1] += 1
        clue_index = locations.length - 1

        # Short curcuit
        break if clue_index.zero? && locations[-1] > max_first_location

        clue = self[clue_index]
      else
        clue_index = locations.length
        clue = self[clue_index]

        # Find the first valid location for the clue
        previous_clue = clue_index.zero? ? nil : self[clue_index - 1]
        location = previous_clue.nil? ? 0 : locations[-1] + previous_clue.count
        location += 1 if clue.colour == previous_clue&.colour
        locations << location
      end

      location = locations[-1]
      while location + clue.count <= board_view.length
        break if clue.valid_location_bfi?(board_view, location)

        location += 1
      end

      if location + clue.count <= board_view.length
        locations[-1] = location

        if locations.length == length
          # Make sure that the spaces in between the clues don't contain any solved cells.
          valid = (0..length).all? do |i|
            from = i.zero? ? 0 : locations[i - 1] + self[i - 1].count
            to = i == length ? board_view.length : locations[i]
            (from...to).all? { |l| board_view[l].nil? || board_view[l] == Puzzle::BLANK }
          end

          solutions << locations.dup if valid
          move_last_clue = true
        else
          move_last_clue = false
        end
      else
        break if clue_index.zero?

        move_last_clue = true
        locations.pop
      end
    end

    # puts "iterations: #{iterations}"

    solutions
  end
end
