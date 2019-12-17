require 'byebug'
require_relative 'tile.rb'
require_relative 'toroidal_list.rb'

class Board
  attr_reader :grid

  def initialize(grid)
    @grid = grid
    @search_nodes = 0
  end

  def self.from_file(file)
    grid = []

    File.read(file).split.each { |line| 
      row = []

      line.each_char { |char| 
        i = char.to_i
        new_tile = i == 0 ? Tile.new(i) : Tile.new(i, true)
        row << new_tile
      }

      grid << row
    }

    Board.new(grid)
  end

  # 
  # Begin Board Helper Methods
  # 
  def render 
    self.grid.each do |row|
      tmp_row = ''
      row.each do |tile|
        tmp_row += tile.to_s  
      end
      puts tmp_row
    end
  end

  def [](x, y)
    raise "these must be numbers" unless x.is_a?(Integer) && y.is_a?(Integer)
    self.grid[x][y]
  end

  def []=(x, y, z)
    raise "these must be numbers" unless x.is_a?(Integer) && y.is_a?(Integer)

    begin
      self.grid[x][y].value =  z
    rescue => exception
      puts exception.message
    end
    
  end

  def solved?
    cols_solved? && rows_solved? && groups_solved?
  end

  def cols_solved? 
    @grid.transpose.each { |column|
      col_solved?(column)
    }
  end
  
  def rows_solved? 
    @grid.each { |row| 
      col_solved?(row)
    }
  end

  def col_solved?(col)
    temp = Array.new(col.length) { |i| col[i].value }
    temp.uniq.length == 9 && temp.max == 9 && temp.min == 1
  end

  def groups_solved? 
    [0,3,6].each { |n| 
      [0,3,6].each { |m|
        group = Array.new(3) { |j| Array.new(3) { |i| grid[j+m][i+n] } }
        group.flatten!(1)
        return false unless col_solved?(group)
      }
    }

    true
  end

  def valid?
    @grid.transpose.each { |column|
      return false unless col_valid?(column)
    }
    @grid.each { |row| 
      return false unless col_valid?(row)
    }
    [0,3,6].each { |n| 
      [0,3,6].each { |m|
        group = Array.new(3) { |j| Array.new(3) { |i| grid[j+m][i+n] } }
        group.flatten!(1)
        return false unless col_valid?(group)
      }
    }
    true
  end

  def col_valid?(col)
    temp = Array.new(col.length) { |i| col[i].value }
    # temp must only contain at most one of each value, except for 0
    temp.all? { |i| i == 0 || temp.one? { |j| j == i } } && temp.max <= 9 && temp.min >= 0
  end
  # 
  # End Board Helper Methods
  # 

  # 
  # Begin Board DFS Solver Methods
  # 
  def dfs_solve_board
    system('clear')
    self.render 
    
    @search_nodes += 1
    # step 1: find first available tile
    # step 2: place value
    # step 3: check if valid
    # step 4: if valid, go to step 1, else backtrack
    tile = first_available
    
    (1..9).each { |i|
      return if self.solved?
      tile.value = i
      self.dfs_solve_board if self.valid?
    }

    tile.value = 0 unless self.solved?
  end

  def first_available
    grid.each { |row|
      row.each { |tile|
        return tile if tile.value == 0 && tile.given == false
      }
    }
  end
  # 
  # End Board DFS Solver Methods
  # 

  


  # 
  # Begin Board DLX Solver Methods
  # 

  # This method involves parsing sudoku to be an exact cover problem, and implementing knuth's algorithm X in order to solve that problem. In particular, we use the Dancing Links implementation of algorithm X, which uses a particular data structure (ToroidalList here) in order to represent the matrix for which we are searching for an exact cover.

  # In our case, an empty sudoku board can be represented as a 324 column x 729 row matrix, as below:

  # the 324 constraints are 81 particular constraints in 4 different sets. 
  # "Row Constraints":
    # Row 1 has to have a # 1. There are 9 possibilities:
    # {R1C1#1, R1C1#2, R1C1#3, R1C1#4, R1C1#5, R1C1#6, R1C1#7, R1C1#8, R1C1#9 }
    # Row 1 has to have 9 such numbers. Therefore, there are 9 possibility sets -- 9 rows, so 81 possibility sets -- 729 distinct possibilities total. 
  # "Column Constraints":
    # Column 1 has to have a # 1. There are 9 possibilities:
    # { R1C1#1, R2C1#1, R3C1#1, R4C1#1, R5C1#1, R6C1#1, R7C1#1, R8C1#1, R9C1#1 }
    # Column 1 has to have 9 such numbers. Therefore, there are 9 possibility sets -- 9 columns, so 81 possibility sets -- 729 distinct possibilities total. 
  # "Box Constraints":
    # ... same: 81 possibility sets -- 729 distinct possibilities total. 
  # "Cell Constraints": ("Row Column Constraints")
    # Every cell, say, R1C1 must have a number. There are 9 possibilities:
    # R1C1 = { R1C1#1, R1C1#2, R1C1#3, R1C1#4, R1C1#5, R1C1#6, R1C1#7, R1C1#8, R1C1#9 }
    # There are 81 such cells, so 81 possibility sets. 729 possibilities total. 
  # 81 possibility sets * 4 gives us our 729 max potential rows.
  
  # You can see a rendering of the matrix at https://www.stolaf.edu/people/hansonr/sudoku/exactcovermatrix.htm

  # Box Index is given like this: (row - (row % 3)) + (col / 3). Boxes are also 0 indexed.
  # Thanks https://code.google.com/archive/p/narorumo/wikis/SudokuDLX.wiki -- update -- thanks knuth for the original in his DANCE program
  def dlx_solve_board
    # step 1: generate sparse matrix representing every possible decision for the sudoku puzzle (324 constraints x 729 (max) decisions (see considerations above)), parsing given numbers as we go
    # step 2: parse sparse matrix as a ToroidalList
    # step 3: implement algorithm x
    # step 4: parse resultant toroidal list as a sparse matrix
    # step 5: parse resultant sparse matrix as sudoku solution
    @solution = []
    sparse_matrix = generate_sparse_matrix

    @torus = generate_toroidal_list(sparse_matrix, sparse_matrix[0].length)
    solution = dlx_solve(0)
    
    @solution.each { |sol| 
      dlx_parse(sol)
    }
    if @solution.empty?
      p "no solutions found"
      self.render
    end
  end

  def dlx_parse(solution)
    # each solution represents a row
    sparse_matrix = []
    solution.each { |row|
      new_row = []
      4.times { 
        new_row << row.head.value
        row = row.right
      }
      sparse_matrix << new_row
    }

    sparse_matrix[0..80].each { |choice|
      pos = choice.select { |i| i < 81 }
      val = choice.select { |i| i >= 81 && i < 162 }

      val = ((val[0] - 81) % 9) + 1
      pos_x = (pos[0]) / 9
      pos_y = pos[0] % 9


      grid[pos_x][pos_y].value = val unless grid[pos_x][pos_y].given
    }

    self.render
    p "-"*32
  end

  def dlx_solve(depth, solution=[])
    # step 1: if the torus is empty return the solution
    # step 2: choose a column, c (we choose the smallest)
    # step 3: choose the column's first row, r
    # step 4: include r in the solution
    # step 5: for each of the column rows,
    if @torus.root.right.value == :root
      @solution << solution
      return solution
    end

    col = @torus.smallest_column
    # col = @torus.first_column
    col.cover

    row = col.down
    until row == col
      # solution << row
      solution[depth] = row

      right = row.right
      until right == row
        right.head.cover
        right = right.right
      end

      dlx_solve(depth+1, solution)

      row = solution[depth] #isn't this just row from above?
      col = row.head
      left = row.left
      until left == row
        left.head.uncover
        left = left.left
      end

      # raise "it's not" unless solution[depth] == row
      # r = solution[depth] #isn't this just row from above?
      # c = r.head
      # left = r.left
      # until left == r
      #   left.head.uncover
      #   left = left.left
      # end

      row = row.down
    end
    col.uncover
    return
  end

  def generate_toroidal_list(sparse_matrix, length)
    toroidal_list = ToroidalList.new
    toroidal_list.generate_headers(length)
    sparse_matrix.each_with_index { |row, i|

      row.each_with_index.reduce(nil) { |acc, (pos, j)|
        next acc if pos == 0
        new_node = ToroidalList.new_node(1)
        header = toroidal_list[j]
        header.size += 1

        lowest_in_column = header
        until lowest_in_column.down.header == true
          lowest_in_column = lowest_in_column.down
        end

        new_node.head = header
        new_node.up = lowest_in_column
        new_node.down = lowest_in_column.down
        lowest_in_column.down = new_node

        unless acc == nil 
          leftmost = acc.right
          new_node.left = acc
          new_node.right = leftmost
          leftmost.left = new_node
          acc.right = new_node
        end

        new_node
      }
    }
    toroidal_list
  end

  def generate_part_row(row, col) 
    # this function will generate single constraint set. four of them are required for a full row in our sparse matrix. the row and col arguments represent the y,x position in the grid that we are building a sparse row for.
    sparse_row = Array.new(81, 0)
    sparse_row[row*9 + col] = 1
    sparse_row
  end

  def generate_sparse_row(i, j, num)
    row_col_cons = generate_part_row(i, j)
    row_cons = generate_part_row(i, num)
    col_cons = generate_part_row(j, num)
    box_idx = (i - ( i % 3 )) + ( j / 3 )
    box_cons = generate_part_row(box_idx, num)
    return row_col_cons.concat(row_cons, col_cons, box_cons)
  end

  def generate_sparse_matrix
    sparse_matrix = []
    # once for each constraint set as follows:
    # Cell Constraint, RowNumber Constraint, ColumnNumber Constraint, BoxNumber Constraint
    # the knowledge of this ordering is private to our implementation, but will not matter except when parsing our answer back to a regular sudoku board
    @grid.each_with_index { |row, i|
      row.each_with_index { |tile, j|
        if tile.value == 0
          # generate all 9 solution choices for all 324 constraints
          (0..8).each { |num| # zero indexing for simple math
            sparse_matrix << generate_sparse_row(i, j, num)
          }
        else
          # generate only the solution choice which corresponds to the tile's value
          sparse_matrix << generate_sparse_row(i, j, tile.value-1)
        end
      }
    }
    sparse_matrix
  end
  # 
  # Begin Board DLX Solver Methods
  # 
end