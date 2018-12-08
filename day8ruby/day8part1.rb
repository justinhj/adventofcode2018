require 'set'

require 'pry-byebug'

filename = ARGV.first || __dir__ + '/input.txt'

file = File.open(filename, 'rb')
contents = file.read

nums = contents.split(" ").map { |n| n.to_i }

# Parse to a tree

# node = [num children] [num meta] [nodes] [meta]

class Node
  attr_accessor :children, :meta
  def initialize(children, meta)
    @children = children
    @meta = meta
  end
end

# return a class how many array consumed
def parseTree(start, nums)

  num_children = nums[start]
  num_meta = nums[start+1]

  children = []
  pos = start+2

#  binding.pry
  
  unless num_children.zero?
    (0...num_children).each do |n|

      child, pos = parseTree(pos, nums)
      children << child
    
    end
  end

  unless num_meta.zero?
    meta = []
    (0...num_meta).each do |n|
      
      meta << nums[pos]
      pos += 1
      
    end
  end

  return Node.new(children, meta), pos
  
end

#binding.pry

root, final_pos = parseTree(0, nums)

def sum(tree)

  sum = tree.meta.sum

  tree.children.each do |n|

    sum += sum(n)
    
  end

  sum
  
end

puts sum(root)

def sum2(tree)

  #binding.pry
  
  if tree.children.size.zero?
    sum = tree.meta.sum
    print "sum meta #{sum}\n"
  else

#    binding.pry
    sum = 0
    tree.meta.each do |n|

      n -= 1
      
      if n < tree.children.size

        sum += sum2(tree.children[n])
        print "sum child #{sum}\n"
        
      end
      
    end

  end
  print "sum total #{sum}\n"

  sum
end

puts sum2(root)

