require 'pry-byebug'
require 'io/console'

filename = ARGV.first || __dir__ + '/input.txt'

file = File.open(filename, 'rb')
contents = file.read

lines = contents.split("\n")

yard = Array.new(lines.length) { Array.new(lines[0].length) }

yard = lines.map do |row|
  row.each_char.inject([]){|acc,a| acc.unshift a}
end

$WIDTH = yard[0].length
$HEIGHT = yard.length

# rules

# An open acre will become filled with trees if three or more adjacent acres contained trees. Otherwise, nothing happens.
# An acre filled with trees will become a lumberyard if three or more adjacent acres were lumberyards. Otherwise, nothing happens.
# An acre containing a lumberyard will remain a lumberyard if it was adjacent to at least one other lumberyard and at least one acre containing trees. Otherwise, it becomes open.

# Gets a map of type of acre to count of adjacent acres for the specified acre in the yard
def get_adjacent(yard, row, col)
  
  adjacent = []

  # diagonal above left
  if row > 0 and col > 0
    adjacent << yard[row-1][col-1]
  end
  # above
  if row > 0
    adjacent << yard[row-1][col]
  end
  # diagonal above right
  if row > 0 and col < $WIDTH-1
    adjacent << yard[row-1][col+1]
  end
  # left
  if col > 0
    adjacent << yard[row][col-1]
  end
  # right
  if col < $WIDTH-1
    adjacent << yard[row][col+1]
  end
  # diagonal below left
  if row < $HEIGHT-1 and col > 0
    adjacent << yard[row+1][col-1]
  end
  # below
  if row < $HEIGHT-1
    adjacent << yard[row+1][col]
  end
  # diagonal below right
  if row < $HEIGHT-1 and col < $WIDTH-1
    adjacent << yard[row+1][col+1]
  end

  # TODO group into a map
  
  adjacent
  
end

def copy_yard(yard)
  yard.map(&:dup)
end

# Lets you iterate a yard by row and column
# something like each_with_index but with row
# and column
def iterate_yard(y)
  y.each_with_index do |row, row_index|
    row.each_with_index do |col, col_index|
      yield(row_index, col_index, y[row_index][col_index]) if block_given?
    end
  end
end

def draw_yard(y)
  iterate_yard(y) do |row,col,thing|
    print "\n" if col == 0
    print "#{thing}"
  end
  print "\n"
end

# take a yard, apply the rules. this modifies the map in place
def apply_rules(y)
  # need a copy of the original map to refer to while mutating it
  o = copy_yard(y)

  iterate_yard(y) do |row,col,thing|

    adjacent = get_adjacent(o, row, col)

    print "#{adjacent}\n"
    
  end
  
end

# iterate_yard(yard) do |row,index,thing|
#   printf "#{row},#{index}\n"
# end

apply_rules(yard)
