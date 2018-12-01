# Day 1 of Advent of Code 2018
# https://adventofcode.com/2018/day/1

# require 'pry-byebug'

filename = ARGV.first || 'input.txt'

file = File.open(filename, 'rb')
contents = file.read

lines = contents.split("\n")
sum = lines.reduce(0) { |acc, line| acc + line.to_i }

puts sum
