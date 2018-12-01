# Day 1 of Advent of Code 2018 part 2
# https://adventofcode.com/2018/day/1

# require 'pry-byebug'

require 'set'

filename = ARGV.first || 'input.txt'

file = File.open(filename, 'rb')
contents = file.read

lines = contents.split("\n")

# Return the first element we encounter twice
# Need a set to remember all the values we saw so far

encountered = Set[]
sum = 0

twice_encountered = lines.cycle.each do |line|
  sum += line.to_i

  if encountered.include? sum
    break sum
  else
    encountered << sum
  end
end

puts twice_encountered
