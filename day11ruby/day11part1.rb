require 'pry-byebug'

# Find the fuel cell's rack ID, which is its X coordinate plus 10.
# Begin with a power level of the rack ID times the Y coordinate.
# Increase the power level by the value of the grid serial number (your puzzle input).
# Set the power level to itself multiplied by the rack ID.
# Keep only the hundreds digit of the power level (so 12345 becomes 3; numbers with no hundreds digit become 0).
# Subtract 5 from the power level

def power_level(x,y,serial)
  rack_id = x + 10
  pl = rack_id * y
  pl += serial
  pl *= rack_id

  pl = (pl / 100) % 10

  pl -= 5
end

# puts power_level(3,5,8)

# Fuel cell at  122,79, grid serial number 57: power level -5.
# Fuel cell at 217,196, grid serial number 39: power level  0.
# Fuel cell at 101,153, grid serial number 71: power level  4

# puts power_level(122,79,57)
# puts power_level(217,196,39)
# puts power_level(101,153,71)

def make_grid(serial)
  grid = {}
  (1..300).each do |y|
    (1..300).each do |x|
      grid[[x,y]] = power_level(x,y,serial)
    end
  end
  grid
end

def find_best(grid)
  best = -1000
  best_coord = [0,0]                
  
  (1..300-2).each do |y|
    (1..300-2).each do |x|
      sum = grid[[x,y]] + grid[[x+1,y]] + grid[[x+2,y]] +
            grid[[x,y+1]] + grid[[x+1,y+1]] + grid[[x+2,y+1]] +
            grid[[x,y+2]] + grid[[x+1,y+2]] + grid[[x+2,y+2]]

      if sum > best
        best = sum
        best_coord = [x,y]
      end
    end
  end

  print "best #{best} at #{best_coord}\n"
  
end

def print_grid(grid, limit)
  (1..limit).each do |y|
    (1..limit).each do |x|
#      binding.pry
      if grid[[x,y]] < 0
        print "#{grid[[x,y]]} "
      else
        print " #{grid[[x,y]]} "
      end
    end
    print "\n"
  end
end

grid = make_grid(5719)
find_best(grid)

print_grid(grid, 30)






                                
    


