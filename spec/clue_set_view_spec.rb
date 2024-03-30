require "./board"
require "./board_view"
require "./clue"
require "./clue_set"
require "./clue_set_view"

describe ClueSetView do
  def create_board_view(input)
    board = Board.from_strings([input])
    BoardView.new(board, 0, true, 0, input.length)
  end

  context "#ranges" do
    def ranges(clues, board_input)
      bv = Board.from_strings([board_input]).view(0, true)
      csv = ClueSet.new(clues).view
      csv.ranges(bv)
    end

    it "works" do
      expect(ranges("2a,2a,2a", "..a...a...")).to(eq([
        [(1...4)],
        [(5...7)],
        [(6...10)],
      ]))
      expect(ranges("2a,2a,2a", "..a ..a...")).to(eq([
        [(1...3)],
        [(5...7)],
        [(6...10)],
      ]))
      expect(ranges("3a,2a,5b,1b,3a", "....aa....bbb.b....")).to(eq([
        [(0...6)],
        [(4...9)],
        [(8...13)],
        [(14...15)],
        [(15...19)],
      ]))
      expect(ranges("3a,2a,5b,1b,3a", "...aa...b.b.b.....aa.")).to(eq([
        [(2...6)],
        [(6...8)],
        [(6...15)],
        [(12...18)],
        [(13...21)],
      ]))
      expect(ranges("7a,2b,6a", "a.a.a.a....b...aa...a")).to(eq([
        [(0...11)],
        [(7...15)],
        [(12...21)],
      ]))
      expect(ranges("1a,1a", " .a......")).to(eq([
        [(2...7)],
        [(2...9)],
      ]))
      expect(ranges("4a,2a,2a,2a", "....a...a........a")).to(eq([
        [1...7],
        [7...12],
        [8...15],
        [11...18],
      ]))
      expect(ranges("4a,2a,2a,2a", ".aaaa...a........a")).to(eq([
        [1...5],
        [7...12],
        [8...15],
        [11...18],
      ]))
    end
  end

  context "#match" do
    def matches(clues, board_input, expected = nil)
      bv = Board.from_strings([board_input]).view(0, true).trim
      csv = ClueSet.new(clues).view
      csv.match_bfi(bv)
      expect(csv.match(bv)).to eq(expected || csv.match_bfi(bv))
    end

    it "works" do
      matches("3a,2a,5b,1b,3a", "..................")
      matches("2a,2a,2a", "..a...a...")
      matches("3a,2a,5b,1b,3a", "....aa....bbb.b....", { 1 => 2, 2 => 3 })
      matches("3a,2a,5b,1b,3a", "...aa...b.b.b.....aa.", { 0 => 0, 1 => 2, 2 => 2, 4 => 4 })
      matches("7a,2b,6a", "aaaaaaa........")
      matches("7a,2b,6a", "a.a.a.a....b...aa...a")
      matches("10a,2a", ".a.a...a............")
    end

    it "matches clues at boundaries" do
      matches("1a,1a", "a.........")
      matches("1a,1a", ".a.........")
      matches("1a,1a", "..a.......")
      matches("1a,1a", "......a..")
      matches("1a,1a", "........a.")
      matches("1a,1a", ".........a")
      matches("4a,2a,2a,2a", "....a............a")
      matches("4a,2a,2a,2a", "a..............a..")
      matches("4a,2a,2a,2a", "....a...a........a", { 0 => 0, 2 => 3 })
      matches("4a,2a,2a,2a", ".aaaa...a........a", { 0 => 0, 2 => 3 })
    end

    it "matches correctly when there are spaces" do
      binding.pry
      matches("1a,1a", " .a......")
                          # 00000
                          #   11111
      matches("1a,1a", " ......a. ")
    end

    # it "raises if the clue sets are not comparable" do
    #   csv = ClueSet.new("2a,5b,1b").view
    #   board_view = create_board_view("...aa..bbbbbb.b")
    #   expect do
    #     csv.match(board_view)
    #   end.to raise_error(StandardError, a_string_matching(/Unable to match clue sets/))
    # end
  end

  context "#fill" do
    it "works" do
      clue_set_view = ClueSetView.new(ClueSet.new("1b,7r,8b"))
      board_view = create_board_view("....................")
      clue_set_view.fill(board_view)
      expect(board_view.to_s).to eq("·····rrr····bbbb····")

      clue_set_view = ClueSetView.new(ClueSet.new("1a,1a,1a,1a,1a,"))
      board_view = create_board_view(".........")
      clue_set_view.fill(board_view)
      expect(board_view.to_s).to eq("a a a a a")
    end
  end

  # context "#fill_when_spaces" do
  #   it "works" do
  #     board_view = Board.from_strings(["  .  "]).view(0, true)
  #     clue_set_view = ClueSetView.new(ClueSet.new("1a"))
  #     binding.pry
  #     # board_view.fill_in_between_matches(clue_set, board_view.to_clues, clue_set.match(board_view))
  #     # expect(board_view.to_s).to(eq("aa.ax.."))

  #     clue_set_view.fill_with_spaces(board_view)
  #     expect(board_view.to_s).to eq("·····rrr····bbbb····")
  #   end
  # end

  context "#match_bfi" do
    def matches(clues, board)
      csv = ClueSet.new(clues).view
      bv = Board.from_strings([board]).view(0, true)
      csv.match_bfi(bv)
    end

    it "works" do
      expect(matches("1a,1a,4b,2a", " ... ...b... ")).to(eq({ 2 => 2 }))
      expect(matches("1a,1a,4b,2a", " .a. ...b... ")).to(eq({ 1 => 0, 3 => 2 }))
      expect(matches("1a,1a,4b,2a", "..a. ...b... ")).to(eq({ 2 => 2 }))
      expect(matches("4a,4b,2a", "..a.a.b.b... ")).to(eq({ 0 => 0, 1 => 0, 2 => 1, 3 => 1 }))
      expect(matches("1a,1a,4b,2a", "..a.a..b.b..")).to(eq({ 0 => 0, 1 => 1, 2 => 2, 3 => 2 }))
    end
  end

  context ".overlap?" do
    it "works" do
      expect(described_class.overlap?(2, 7, 1, 2)).to(eq(false))
      expect(described_class.overlap?(2, 7, 1, 3)).to(eq(true))
      expect(described_class.overlap?(2, 7, 2, 3)).to(eq(true))
      expect(described_class.overlap?(2, 7, 3, 5)).to(eq(true))
      expect(described_class.overlap?(2, 7, 3, 7)).to(eq(true))
      expect(described_class.overlap?(2, 7, 3, 8)).to(eq(true))
      expect(described_class.overlap?(2, 7, 6, 8)).to(eq(true))
      expect(described_class.overlap?(2, 7, 7, 8)).to(eq(false))
      expect(described_class.overlap?(2, 7, 8, 9)).to(eq(false))

      expect(described_class.overlap?(1, 2, 2, 7)).to(eq(false))
      expect(described_class.overlap?(1, 3, 2, 7)).to(eq(true))
      expect(described_class.overlap?(2, 3, 2, 7)).to(eq(true))
      expect(described_class.overlap?(3, 5, 2, 7)).to(eq(true))
      expect(described_class.overlap?(3, 7, 2, 7)).to(eq(true))
      expect(described_class.overlap?(3, 8, 2, 7)).to(eq(true))
      expect(described_class.overlap?(6, 8, 2, 7)).to(eq(true))
      expect(described_class.overlap?(7, 8, 2, 7)).to(eq(false))
      expect(described_class.overlap?(8, 9, 2, 7)).to(eq(false))
    end
  end

  context ".contains?" do
    it "works" do
      expect(described_class.contains?(2, 7, 1, 2)).to(eq(false))
      expect(described_class.contains?(2, 7, 1, 3)).to(eq(false))
      expect(described_class.contains?(2, 7, 2, 3)).to(eq(true))
      expect(described_class.contains?(2, 7, 3, 5)).to(eq(true))
      expect(described_class.contains?(2, 7, 3, 7)).to(eq(true))
      expect(described_class.contains?(2, 7, 3, 8)).to(eq(false))
      expect(described_class.contains?(2, 7, 6, 8)).to(eq(false))
      expect(described_class.contains?(2, 7, 7, 8)).to(eq(false))
      expect(described_class.contains?(2, 7, 8, 9)).to(eq(false))
    end
  end

  context "#find_all_solutions_bfi" do
    def solutions(clues, board)
      csv = ClueSet.new(clues).view
      bv = Board.from_strings([board]).view(0, true)
      csv.find_all_solutions_bfi(bv)
    end

    it "works for positive cases" do
      expect(solutions("1a", "..")).to(eq([[0], [1]]))
      expect(solutions("1a,2a", ".....")).to(eq([[0, 2], [0, 3], [1, 3]]))
      expect(solutions("1a,2b", "....")).to(eq([[0, 1], [0, 2], [1, 2]]))
      expect(solutions("1a,1a,4b,2a", "a abbbbaa")).to(eq([[0, 2, 3, 7]]))
      expect(solutions("1a,1a,4b,2a", ".........")).to(eq([[0, 2, 3, 7]]))
      expect(solutions("1a,1a,4b,2a", "..........")).to(eq([[0, 2, 3, 7], [0, 2, 3, 8], [0, 2, 4, 8], [0, 3, 4, 8], [1, 3, 4, 8]]))
      expect(solutions("1a,1a,4b,2a", "........b....")).to(eq(
        [
          [0, 2, 5, 9],
          [0, 2, 5, 10],
          [0, 2, 5, 11],
          [0, 2, 6, 10],
          [0, 2, 6, 11],
          [0, 2, 7, 11],
          [0, 3, 5, 9],
          [0, 3, 5, 10],
          [0, 3, 5, 11],
          [0, 3, 6, 10],
          [0, 3, 6, 11],
          [0, 3, 7, 11],
          [0, 4, 5, 9],
          [0, 4, 5, 10],
          [0, 4, 5, 11],
          [0, 4, 6, 10],
          [0, 4, 6, 11],
          [0, 4, 7, 11],
          [0, 5, 6, 10],
          [0, 5, 6, 11],
          [0, 5, 7, 11],
          [0, 6, 7, 11],
          [1, 3, 5, 9],
          [1, 3, 5, 10],
          [1, 3, 5, 11],
          [1, 3, 6, 10],
          [1, 3, 6, 11],
          [1, 3, 7, 11],
          [1, 4, 5, 9],
          [1, 4, 5, 10],
          [1, 4, 5, 11],
          [1, 4, 6, 10],
          [1, 4, 6, 11],
          [1, 4, 7, 11],
          [1, 5, 6, 10],
          [1, 5, 6, 11],
          [1, 5, 7, 11],
          [1, 6, 7, 11],
          [2, 4, 5, 9],
          [2, 4, 5, 10],
          [2, 4, 5, 11],
          [2, 4, 6, 10],
          [2, 4, 6, 11],
          [2, 4, 7, 11],
          [2, 5, 6, 10],
          [2, 5, 6, 11],
          [2, 5, 7, 11],
          [2, 6, 7, 11],
          [3, 5, 6, 10],
          [3, 5, 6, 11],
          [3, 5, 7, 11],
          [3, 6, 7, 11],
          [4, 6, 7, 11],
        ]
      ))
      expect(solutions("1a,1a,4b,2a", " ... ...b... ")).to(eq(
        [[1, 3, 5, 9], [1, 3, 5, 10], [1, 3, 6, 10], [1, 5, 6, 10], [2, 5, 6, 10], [3, 5, 6, 10]]
      ))
      expect(solutions("1a,1a,4b,2a", "....bbbbaa")).to(eq([[0, 2, 4, 8], [0, 3, 4, 8], [1, 3, 4, 8]]))
      expect(solutions("3a,2a,5b,1b,3a", "....aa....bbb.b....")).to(eq([[0, 4, 8, 14, 15], [0, 4, 8, 14, 16]]))
      expect(solutions("3a,2a,5b,1b,2a", "....aa....bbb.b....")).to(eq([
        [0, 4, 8, 14, 15],
        [0, 4, 8, 14, 16],
        [0, 4, 8, 14, 17],
        [0, 4, 10, 16, 17],
        [3, 7, 10, 16, 17],
        [3, 8, 10, 16, 17],
        [4, 8, 10, 16, 17],
      ]))
      expect(solutions("2a,2a,2a", "..a...a...")).to(eq([[1, 5, 8], [2, 5, 8]]))
    end

    it "works for negative cases" do
      expect(solutions("1a,1a,4b,2a", "....")).to(eq([]))
      expect(solutions("1a,1a,4b,2a", "..... ...")).to(eq([]))
    end
  end
end
