require "pry"
require "json"
# require "pry-byebug"

require "./board"
require "./board_view"
require "./clue"
require "./clue_set"
require "./clue_set_view"
require "./puzzle"

puzzle = Puzzle.from_file("ladybug.20x20")
# puzzle = Puzzle.from_file("pumpkins.45x35")
puzzle.solve
puzzle.draw

# tops = Hash.new(0)
# clues[:top].each { |s| s.split(",").each { |c| tops[c[-1]] += c[0..-2].to_i } }
# p tops
# #
# lefts = Hash.new(0)
# clues[:left].each { |s| s.split(",").each { |c| lefts[c[-1]] += c[0..-2].to_i } }
# p lefts

# a = Array.new(10)
# ClueSet.new("4b,1a,3b").fill_array(a)

# a = Array.new(10)
# ClueSet.new("4b,1b,3b").fill_array(a)


# puzzle = Puzzle.new(
#   ["1b,2g,2b,4g,6b,7g,1b,11g,1b"],
#   ["", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""],
#   {}
# )
# # c = ClueSet.new("1b,2g,2b,4g,6b,7g,1b,11g,1b")
# # v = ClueSetView.new(c, 0, c.length)
# # p v.sum

# puzzle.draw
# puzzle.solve
# puzzle.draw
