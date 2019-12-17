require_relative 'board.rb'
require_relative 'tile.rb'

class Game
  attr_reader :board
  def initialize(puzzles)
    raise "file does not exist" unless File.exist?(puzzles)
    @board = Board.from_file(puzzles)

    # self.play
    # board.render
    # puts "You won!"
  end

  def render
    @board.render
  end

  def dlx_solve
    @board.dlx_solve_board
  end

  def dfs_solve
    @board.dfs_solve_board
  end

  def search_nodes
    @board.search_nodes
  end

  def solved?
    @board.solved?
  end

  def valid?
    @board.valid?
  end

  def play
    until board.solved?
      board.render
      user_input = self.prompt
      board[user_input[0],user_input[1]] = user_input[2]

    end
  end 

  def prompt
    puts "Please enter an input like this: pos_x, pos_y, value"
    
    input = gets.chomp
    
    until /^\d, \d, \d$/.match?(input)
      puts "Please try again, like this: pos_x, pos_y, value"
      input = gets.chomp
    end
    
    input.split(", ").map!(&:to_i)
  end
end