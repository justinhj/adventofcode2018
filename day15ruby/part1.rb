require 'pry-byebug'
require 'io/console'

filename = ARGV.first || __dir__ + '/input.txt'

file = File.open(filename, 'rb')
contents = file.read

lines = contents.split("\n")

map = lines do |line|
  
end

# Combat
# Each unit not dead
#   resolve all actions
# Decide who does what based on row then column
#   try to move in range
#   attack
#   if multiple targets priority is top to bottom then left to right
#    no diagonal attack
# step 1
#    identify targets

