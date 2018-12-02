# Day 2 of Advent of Code 2018
# https://adventofcode.com/2018/day/2

# require 'pry-byebug'

filename = ARGV.first || __dir__ + '/input.txt'

file = File.open(filename, 'rb')
contents = file.read
lines = contents.split("\n")

def count_twos_and_threes(str)
  sa = str.scan(/\w/)

  groups = sa.group_by { |c| c }.values

  has_two = groups.any? { |g| g.length == 2 }
  has_three = groups.any? { |g| g.length == 3 }

  return has_two ? 1 : 0, has_three ? 1 : 0
end

counts = lines.reduce([0, 0]) do |acc, line|
  twos, threes = count_twos_and_threes(line)

  acc[0] = acc[0] + twos
  acc[1] = acc[1] + threes

  acc
end

puts counts[0] * counts[1]



