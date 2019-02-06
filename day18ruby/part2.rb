require 'pry-byebug'
require 'io/console'

filename = ARGV.first || __dir__ + '/input.txt'

file = File.open(filename, 'rb')
contents = file.read

lines = contents.split("\n")

yard = Array.new(lines.length) { Array.new(lines[0].length) }

yard = lines.map do |row|
  row.each_char.inject([]){|acc,a| acc.unshift a}.reverse
end

$WIDTH = yard[0].length
$HEIGHT = yard.length

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

  adjacent.inject(Hash.new(0)) do |acc, a|
    acc[a] += 1
    acc
  end
  
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

# rules

# An open acre will become filled with trees if three or more adjacent acres contained trees. Otherwise, nothing happens.
# An acre filled with trees will become a lumberyard if three or more adjacent acres were lumberyards. Otherwise, nothing happens.
# An acre containing a lumberyard will remain a lumberyard if it was adjacent to at least one other lumberyard and at least one acre containing trees. Otherwise, it becomes open.

# take a yard, apply the rules. this modifies the map in place
def apply_rules(y)
  # need a copy of the original map to refer to while mutating it
  o = copy_yard(y)

  iterate_yard(y) do |row,col,thing|

    adjacent = get_adjacent(o, row, col)

    case thing
    when '.'
      if adjacent['|'] >= 3
        y[row][col] = '|'
      end
    when '|'
      if adjacent['#'] >= 3
        y[row][col] = '#'
      end
    when '#'
      if adjacent['#'] == 0 or adjacent['|'] == 0
        y[row][col] = '.'
      end
    end
  end
end

def calculate_value(y)
  lumbers = 0
  trees = 0
  iterate_yard(y) do |_,_,thing|
    case thing
    when '|'
      trees += 1
    when '#'
      lumbers +=1
    end
  end

  lumbers * trees
end

$move_up = "\u001b[1A" * ($HEIGHT + 1 + 1)
$move_down = "\u001b[1B" * ($HEIGHT + 1 + 1)

minute = 0

(1..1000000000).each do |_|
  apply_rules(yard)
  minute += 1
  value = calculate_value(yard)

  if minute % 100 == 0
    print "value #{value} time #{minute}\n"
  end

end
