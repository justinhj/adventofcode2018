require 'set'

# require 'pry-byebug'

filename = ARGV.first || __dir__ + '/input.txt'

file = File.open(filename, 'rb')
contents = file.read

nums = contents.split(' ').map(&:to_i)

# Parse to a tree, format:
# node = [num children] [num meta] [nodes] [meta]

# Returns a hash for each node and the next position in the input array
def parse_tree(start, nums)
  num_children = nums[start]
  num_meta = nums[start + 1]

  children = []
  pos = start + 2

  unless num_children.zero?
    (0...num_children).each do |_|
      child, pos = parse_tree(pos, nums)
      children << child
    end
  end

  unless num_meta.zero?
    meta = []
    (0...num_meta).each do |_|

      meta << nums[pos]
      pos += 1
    end
  end

  [{ children: children, meta: meta }, pos]
end

root, _ = parse_tree(0, nums)

def sum(tree)
  sum = tree[:meta].sum

  tree[:children].each do |n|

    sum += sum(n)
  end

  sum
end

puts sum(root)

def sum2(tree)
  if tree[:children].size.zero?
    sum = tree[:meta].sum
    # print "sum meta #{sum}\n"
  else
    sum = 0
    tree[:meta].each do |n|

      n -= 1

      next unless n < tree[:children].size

      sum += sum2(tree[:children][n])
      # print "sum child #{sum}\n"
    end
  end
  # print "sum total #{sum}\n"

  sum
end

puts sum2(root)
