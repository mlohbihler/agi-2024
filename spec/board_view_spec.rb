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

    it "returns correct clues when solved cells are at the edges" do
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
      expect(Board.from_strings([" "]).view(0, true).trim.to_s).to(eq(""))
      expect(Board.from_strings([""]).view(0, true).trim.to_s).to(eq(""))
    end
  end

  context "#fill_from_matches" do
    def call(board, clues, bfi: false)
      board_view = Board.from_strings([board]).view(0, true)
      csv = ClueSet.new(clues).view
      board_view.fill_from_matches(csv, bfi: bfi)
      board_view.to_s
    end

    it "doesn't actuallly change anything, but would be nice if it did" do
      expect(call("...b..b...b .b.b... ", "4b,1b,3b")).to(eq("...b..b...b .b.b..  "))
      expect(call("......     ...", "4a,2a")).to(eq("......     ..."))
    end

    it "works using bfi" do
      expect(call(".....ggg.gg.bggg..g.bb....   ... ............", "1b,1g,1b,3g(5),1b,3g,1b,3g,2b,2g,6b", bfi: true)).
        to(eq(    ".....gggbgg.bgggbbg.bbbbb.                   "))
      expect(call(".....gggbgg.bgggbbg.bbbbb.                   ", "1b,1g,1b,3g(5),1b,3g,1b,3g,2b,2g,6b")).
        to(eq(    ".....gggbgggbgggbbggbbbbb.                   "))
      expect(call(".....gggbgggbgggbbggbbbbb.                   ", "1b,1g,1b,3g(5),1b,3g,1b,3g,2b,2g,6b")).
        to(eq(    ".....gggbgggbgggbbggbbbbbb                   "))
    end
  end

  context "#fill_in_between_matches" do
    def call(board, clues)
      board_view = Board.from_strings([board]).view(0, true)
      csv = ClueSet.new(clues).view
      board_view.fill_in_between_matches(csv, board_view.to_clues, csv.match(board_view))
      board_view.to_s
    end

    context "when filling before a match" do
      it "works" do
        expect(call("....x..", "2a,1a,1x")).to(eq("aa ax.."))
        expect(call("....x..", "2a,1b,1x")).to(eq(".a..x.."))
        expect(call(" ...x..", "2a,1b,1x")).to(eq(" aabx.."))
        expect(call(".. .x..", "2a,1b,1x")).to(eq(".a .x.."))
        expect(call("... x..", "2a,1b,1x")).to(eq("aab x.."))
      end
    end

    context "when filling between matches" do
      it "works" do
        expect(call("aa..x..", "2a,1a,1x")).to(eq("aa.ax.."))
        expect(call("aa .x..", "2a,1a,1x")).to(eq("aa ax.."))
      end

      it "fills space between board clues for the same clue" do
        expect(call("..aa....aaa.", "11a")).to(eq("..aaaaaaaaa."))
      end

      it "extrapolates from adjacent clues, and fills spaces between them" do
        expect(call(".a.......bb.", "2a,3b")).to(eq(".a.     .bb."))
        expect(call(".aa.....bbb.", "2a,3b")).to(eq(".aa     bbb."))
        expect(call("..aa..aaa..", "4a,5a")).to(eq(".aaa..aaaa."))
      end
    end

    context "when filling after a match" do
      it "works" do
        expect(call("..aaa...", "4a,2a")).to(eq("..aaa.aa"))
        expect(call("..aaa...", "4a,2b")).to(eq("..aaa.b."))
      end
    end
  end

  context "#fill_from_edges" do
    def call(board, clues)
      board_view = Board.from_strings([board]).view(0, true)
      csv = ClueSet.new(clues).view
      board_view.fill_from_edges(csv, board_view.to_clues, csv.match(board_view))
      board_view.to_s
    end

    it "works" do
      # expect(call("    .... b..    bb  ", "2b,3b,2b")).to(eq("    .... bbb    bb  "))
      expect(call("..aaa...........", "10a")).to(eq("..aaaaaaaa..    "))
      expect(call("aaa...........", "10a")).to(eq("aaaaaaaaaa    "))
      expect(call(".....aaa......", "8a")).to(eq(".....aaa..... "))
      expect(call(".....aaa......", "7a")).to(eq(" ....aaa....  "))
      expect(call("...aaa.......", "11a")).to(eq("..aaaaaaaaa.."))
      expect(call("...........aaa..", "10a")).to(eq("    ..aaaaaaaa.."))
      expect(call("...........aaa", "10a")).to(eq("    aaaaaaaaaa"))
      expect(call(".aaa.... .. ....bb", "7a,2c,4b")).to(eq(".aaaaaa. .. ..bbbb"))
      expect(call("  .aa....   .b.  .cc.  .....d   ", "7a,3b,3c,2d")).to(eq("  aaaaaaa   bbb  .cc.  ....dd   "))
      expect(call("          .b..      ", "3b")).to(eq("          .bb.      "))
      expect(call("..b..  ", "4b")).to(eq(".bbb.  "))
      expect(call("  ..b..", "4b")).to(eq("  .bbb."))
      expect(call(".aaa...   ..    bb..", "7a,2c,4b")).to(eq("aaaaaaa   ..    bbbb"))
      expect(call("....abb....", "4a,5b")).to(eq(" aaaabbbbb "))
      expect(call("....a.bb....", "4a,5b")).to(eq(" .aaa.bbbb. "))
    end
  end

  context "#cap_solved_clues" do
    def call(board, clues)
      board_view = Board.from_strings([board]).view(0, true)
      csv = ClueSet.new(clues).view
      board_view.cap_solved_clues(csv, board_view.to_clues, csv.match(board_view))
      board_view.to_s
    end

    it "works" do
      expect(call("..aaa...", "3a")).to(eq("..aaa..."))
      expect(call("..aaa.....", "3a,1a")).to(eq("..aaa ...."))
    end
  end
end


# 12345678901234567890
# --------------------
# 1:     .... b..    bb
# 2:     .b.b b.. bbbb
# 3:      ...rrrrbbb bb b
# 4:     brrrrrrrbbbbbbbb
# 5:    brrrrrrr bbbbb b
# 6:   brrrrrrrr  bbbbbb
# 7:   brrrbbrrrbbbbbbbb
# 8:  brrrrbbrrrbbb bbb
# 9:  brrrrrrrrrbbb  rr..
# 0:  rrrrrrrrrbrrrrrrr..
# 1:  rrrrrrrrbrrrrrrrrbb
# 2: bbrbbrrrbrrrrrrrrr
# 3: b rbbrrbrrrrbbrrr...
# 4: barrrrbrrrrrbbrrrbb
# 5:  aarrbrrrrrrrrrrr..
# 6:  aarbrrrbbrrrrrrb bb
# 7:  a  rrrrbbrrrrrb
# 8:     aarrrrrrrbb
# 9:    aaaa brrbb
# 0:       bbb