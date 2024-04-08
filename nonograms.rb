require "json"
require "pry"
# require "pry-byebug"
require "rainbow"

require "./board"
require "./board_view"
require "./clue"
require "./clue_set"
require "./clue_set_view"
require "./puzzle"

# puzzle = Puzzle.from_file("ladybug.20x20")
# puzzle = Puzzle.from_file("pumpkins.45x35")
puzzle = Puzzle.from_file("hare.30x35")
puzzle.solve
puzzle.draw(rotate: false)
# puzzle.draw(colour: true)
puts puzzle.solved? ? Rainbow(" ### Solved").green : Rainbow("### Not solved").red
puts

# https://en.wikipedia.org/wiki/X11_color_names
