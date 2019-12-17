class ToroidalList
  attr_reader :root
  attr_accessor :current

  class << self
    def new_header(value=:h)
      node = Node.new(value)
      class << node
        include NodeOperations
        include HeaderOperations
      end
      node.instance_variable_set(:@header, true)
      node.size = 0
      node
    end

    def new_node(value)
      node = Node.new(value)
      class << node
        include NodeOperations
        attr_reader :header
      end
      node.instance_variable_set(:@header, false)
      # node.send(:attr_reader, :header)
      node
    end
  end

  def inspect
    "Columns: " + self.columns.to_s
  end

  def initialize(value=:root) # we assume we'll always want to initialize on the :root, which points to itself in all directions
    node = self.class.new_node(value)
    @current = node
    @root = node
  end

  def columns
    idx = 0
    head = @root.right
    until head == @root
      idx += 1
      head = head.right
    end
    idx
  end

  def biggest_column
    biggest = @root.right
    idx = biggest
    until idx.right == @root
      biggest = idx.size > biggest.size ? idx : biggest
      idx = idx.right
    end
    biggest
  end

  def first_column
    @root.right
  end

  def smallest_column
    smallest = @root.right
    idx = smallest
    until idx.right == @root
      smallest = idx.size < smallest.size ? idx : smallest
      idx = idx.right
    end
    smallest
  end

  def [](idx)
    start = @root
    (idx+1).times { 
      start = start.right
    }
    start
  end

  def right_push(node)
    head = @current.right
    
    node.left = @current
    node.right = head

    head.left = node
    @current.right = node

    @current = node
  end

  def generate_headers(num)
    num.times { |i|
      new_node = self.class.new_header(i)
      self.right_push(new_node)
    }
  end

  module HeaderOperations
    def self.included(base)
      base.send(:attr_accessor, :size)
      base.send(:attr_reader, :header)
    end

    def cover
      self.remove_from_row # this removes the column from the column object
      root = self.down
      until root.header
        mark = root.right

        until mark == root # this removes every row in our column from the other columns they are in
          mark.remove_from_column
          mark.head.size -= 1
          mark = mark.right
        end

        root = root.down
      end
    end

    def uncover
      root = self.up
      until root.header
        mark = root.left

        until mark == root
          mark.return_to_column
          mark.head.size += 1
          mark = mark.left
        end

        root = root.up
      end
      self.return_to_row
    end
  end

  module NodeOperations
    def remove_from_row # "cover"
      self.left.right, self.right.left = self.right, self.left
    end
    def return_to_row # "uncover"
      self.left.right, self.right.left = self, self
    end

    def remove_from_column # "cover"
      self.up.down, self.down.up = self.down, self.up
    end
    def return_to_column # "uncover"
      self.up.down, self.down.up = self, self
    end
  end
end

class Node
  attr_accessor :value, :left, :right, :up, :down, :head

  def initialize(value, left=nil, right=nil)
    @value = value
    @left, @right, @up, @down, @head = self, self, self, self, self
  end

  def inspect
    header ? "value: " + self.value.to_s : "header: " + self.head.value.to_s
  end
end