require 'pry-byebug'

Node = Struct.new(:left, :right, :data) do
end

root = nil

# sample = [1,2,5,3,6,4]
sample = [10,15,20,5,8,12,14]

def insert(root, data)
  if root.nil?
    root = Node.new(nil, nil, data)
  elsif data < root.data
    if root.left.nil?
      root.left = Node.new(nil, nil, data)
    else
      insert(root.left, data)
    end
  else
    if root.right.nil?
      root.right = Node.new(nil, nil, data)
    else
      insert(root.right, data)
    end
  end
  root
end

#binding.pry

while d = sample.shift do
  root = insert(root, d)
end

def draw_tree(root, level)
  return if root.nil?
  
  printf "#{" "*level}#{root.data}\n"

  draw_tree(root.left, level + 1)
  draw_tree(root.right, level + 1)
end

draw_tree(root, 0)

def level_order(root)

  queue = []

  queue << root

  while n = queue.shift do
    puts n.data
    queue << n.left unless n.left.nil?
    queue << n.right unless n.right.nil?
  end
end

level_order(root)
