require_relative 'game.rb'
require 'byebug'


game = Game.new('puzzles/sudoku2.txt')
game.dlx_solve

# game.dfs_solve


