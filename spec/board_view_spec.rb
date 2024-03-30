require "./board"
require "./board_view"
require "./clue"
require "./clue_set"

describe BoardView do
  context "#to_clues" do
    it "returns nothing when there are no solved cells" do
      board = Board.from_strings([".........."])
      view = described_class.new(board, 0, true, 0, 10)
      expect(view.to_clues).to(eq(ClueSet.new([])))
    end

    it "returns correct clues including start positions" do
      board = Board.from_strings([".aab.bc. ."])
      view = described_class.new(board, 0, true, 0, 10)
      expect(view.to_clues).to(eq(ClueSet.new([
        Clue.new(2, :a, 1),
        Clue.new(1, :b, 3),
        Clue.new(1, :b, 5),
        Clue.new(1, :c, 6),
        Clue.new(1, :" ", 8),
      ])))
    end

    it "returns correct clues when solves cells are at the edges" do
      board = Board.from_strings(["aaa.....bb"])
      view = described_class.new(board, 0, true, 0, 10)
      expect(view.to_clues).to(eq(ClueSet.new([
        Clue.new(3, :a, 0),
        Clue.new(2, :b, 8),
      ])))
    end
  end

  context "#trim" do
    it "works" do
      expect(Board.from_strings(["  aaabb   "]).view(0, true).trim.to_s).to(eq("aaabb"))
      expect(Board.from_strings(["aaabb             "]).view(0, true).trim.to_s).to(eq("aaabb"))
      expect(Board.from_strings(["            aaabb"]).view(0, true).trim.to_s).to(eq("aaabb"))
      expect(Board.from_strings(["aaabb"]).view(0, true).trim.to_s).to(eq("aaabb"))
      expect(Board.from_strings(["    "]).view(0, true).trim.to_s).to(eq(""))
      expect(Board.from_strings(["  a  "]).view(0, true).trim.to_s).to(eq("a"))
      expect(Board.from_strings([" a "]).view(0, true).trim.to_s).to(eq("a"))
      expect(Board.from_strings(["a"]).view(0, true).trim.to_s).to(eq("a"))
    end
  end

  context "#fill_from_matches" do
    it "works" do
      # board = Board.from_strings([".....rrrrrr.bbbb...."])
      # board_view = board.view(0, true)
      # clue_set = ClueSet.new("1b,7r,8b")
      # board_clue_set = board_view.to_clues #ClueSet.new([Clue.new(6, "r", 5), Clue.new(4, "b", 12)])
      # matches = clue_set.match(board_view) # matches = { 0 => 1, 1 => 2 }
      # puts board_view.fill_from_matches(clue_set, board_clue_set, matches)

      # clue_set = ClueSet.new("1b,7r,8b")
      # solved_clue_set = ClueSet.new([])
      # matches = {}
      # puts board_view.fill_from_matches(clue_set, board_clue_set, matches)

      # clue_set = ClueSet.new("1b,7r,8b")
      # solved_clue_set = ClueSet.new([Clue.new(1, "r", 5), Clue.new(1, "r", 7), Clue.new(1, "r", 10)])
      # matches = { 0 => 1, 1 => 1, 2 => 1 }
      # puts board_view.fill_from_matches(clue_set, board_clue_set, matches)

      # clue_set = ClueSet.new("1b,7r,8b")
      # solved_clue_set = ClueSet.new([Clue.new(1, "r", 1)])
      # matches = { 0 => 1 }
      # puts board_view.fill_from_matches(clue_set, board_clue_set, matches)

      # Including spaces
    end
  end

  context "#fill_in_between_matches" do
    context "when filling before a match" do
      it "works" do
        # board_view = Board.from_strings(["....x.."]).view(0, true)
        # clue_set = ClueSet.new("2a,1a,1x")
        # board_view.fill_in_between_matches(clue_set, board_view.to_clues, clue_set.match(board_view))
        # expect(board_view.to_s).to(eq("aa.ax.."))

        # board_view = Board.from_strings(["....x.."]).view(0, true)
        # clue_set = ClueSet.new("2a,1b,1x")
        # board_view.fill_in_between_matches(clue_set, board_view.to_clues, clue_set.match(board_view))
        # expect(board_view.to_s).to(eq(".a..x.."))

        # board_view = Board.from_strings([" ...x.."]).view(0, true)
        # clue_set = ClueSet.new("2a,1b,1x")
        # board_view.fill_in_between_matches(clue_set, board_view.to_clues, clue_set.match(board_view))
        # expect(board_view.to_s).to(eq(" aabx.."))

        board_view = Board.from_strings([".. .x.."]).view(0, true)
        clue_set = ClueSet.new("2a,1b,1x")
        board_view.fill_in_between_matches(clue_set, board_view.to_clues, clue_set.match(board_view))
        expect(board_view.to_s).to(eq("aa bx.."))

        board_view = Board.from_strings(["... x.."]).view(0, true)
        clue_set = ClueSet.new("2a,1b,1x")
        board_view.fill_in_between_matches(clue_set, board_view.to_clues, clue_set.match(board_view))
        expect(board_view.to_s).to(eq("aab x.."))
      end
    end

    context "when filling between matches" do
      it "works" do
        # board_view = Board.from_strings(["....x.."]).view(0, true)
        # clue_set = ClueSet.new("2a,1a,1x")
        # board_view.fill_in_between_matches(clue_set, board_view.to_clues, clue_set.match(board_view))
        # expect(board_view.to_s).to(eq("aa.ax.."))

        # board_view = Board.from_strings(["....x.."]).view(0, true)
        # clue_set = ClueSet.new("2a,1b,1x")
        # board_view.fill_in_between_matches(clue_set, board_view.to_clues, clue_set.match(board_view))
        # expect(board_view.to_s).to(eq(".a..x.."))

        # board_view = Board.from_strings([" ...x.."]).view(0, true)
        # clue_set = ClueSet.new("2a,1b,1x")
        # board_view.fill_in_between_matches(clue_set, board_view.to_clues, clue_set.match(board_view))
        # expect(board_view.to_s).to(eq(" aabx.."))

        # board_view = Board.from_strings([".. .x.."]).view(0, true)
        # clue_set = ClueSet.new("2a,1b,1x")
        # board_view.fill_in_between_matches(clue_set, board_view.to_clues, clue_set.match(board_view))
        # expect(board_view.to_s).to(eq("aa bx.."))

        # board_view = Board.from_strings(["... x.."]).view(0, true)
        # clue_set = ClueSet.new("2a,1b,1x")
        # board_view.fill_in_between_matches(clue_set, board_view.to_clues, clue_set.match(board_view))
        # expect(board_view.to_s).to(eq("aab x.."))
      end
    end

    context "when filling after a matche" do
      it "works" do
        # board_view = Board.from_strings(["....x.."]).view(0, true)
        # clue_set = ClueSet.new("2a,1a,1x")
        # board_view.fill_in_between_matches(clue_set, board_view.to_clues, clue_set.match(board_view))
        # expect(board_view.to_s).to(eq("aa.ax.."))

        # board_view = Board.from_strings(["....x.."]).view(0, true)
        # clue_set = ClueSet.new("2a,1b,1x")
        # board_view.fill_in_between_matches(clue_set, board_view.to_clues, clue_set.match(board_view))
        # expect(board_view.to_s).to(eq(".a..x.."))

        # board_view = Board.from_strings([" ...x.."]).view(0, true)
        # clue_set = ClueSet.new("2a,1b,1x")
        # board_view.fill_in_between_matches(clue_set, board_view.to_clues, clue_set.match(board_view))
        # expect(board_view.to_s).to(eq(" aabx.."))

        # board_view = Board.from_strings([".. .x.."]).view(0, true)
        # clue_set = ClueSet.new("2a,1b,1x")
        # board_view.fill_in_between_matches(clue_set, board_view.to_clues, clue_set.match(board_view))
        # expect(board_view.to_s).to(eq("aa bx.."))

        # board_view = Board.from_strings(["... x.."]).view(0, true)
        # clue_set = ClueSet.new("2a,1b,1x")
        # board_view.fill_in_between_matches(clue_set, board_view.to_clues, clue_set.match(board_view))
        # expect(board_view.to_s).to(eq("aab x.."))
      end
    end
  end
end
