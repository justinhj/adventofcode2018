# Day 2 of Advent of Code 2018
# https://adventofcode.com/2018/day/2

#require 'pry-byebug'

filename = ARGV.first || __dir__ + '/input.txt'

file = File.open(filename, 'rb')
contents = file.read
lines = contents.split("\n")

def remove_diff(str1, str2)
  a1 = str1.scan(/\w/)
  a2 = str2.scan(/\w/)

  diffs = a1.zip(a2).reduce("") do |acc, ab|

    a,b = ab
    
    if a == b
      acc + a
    else
      acc
    end
    
  end

  
end

# binding.pry

# we need to find two lines that differ by only one character
# and return the common characters

diffs = ""

lines.each do |line1|

  lines.each do |line2|

    diffs_removed = remove_diff(line1, line2)

    if diffs_removed.length == (line1.length - 1)
      diffs = diffs_removed
  #    binding.pry
      break diffs
    end
  end

  if diffs.length > 0
    break diffs
  end
  
end

puts diffs

    

    




