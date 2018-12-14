require 'pry-byebug'

filename = ARGV.first || __dir__ + '/input.txt'

file = File.open(filename, 'rb')
contents = file.read

lines = contents.split("\n")

puts lines.length

# initial state: #..#.#..##......###...###
def pots_from_initial_pos(initial)

  pot_states = /initial state: ([#\.]+)/.match(initial).captures[0]

  
  
  
end

ass = pots_from_initial_pos(lines[0])


