require 'pry-byebug'
require 'chunky_png'

# The following data structure is put to work in this solution
# to speed up the problem of finding sums of all sizes of
# rectangles:
# https://en.wikipedia.org/wiki/Summed-area_table
# Which links to this which is a better explanation
# https://www.codeproject.com/Articles/441226/Haar-feature-Object-Detection-in-Csharp

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

def make_grid(serial)
  grid = Hash.new(0)
  (1..300).each do |y|
    (1..300).each do |x|
      grid[[x,y]] = power_level(x,y,serial)
    end
  end
  grid
end

# return best score and the best size
def find_best_size(sat, x, y, width)

  #print "Analyze #{x},#{y}\n"
  
  best = -1000
  best_size = -1
  size = 1

  #  while x + size <= width + 1 do
  while x + size <= width + 1 &&
        y + size <= width + 1 &&
        size < 20 do

#    print "try size x #{x} #{size} - 1 (#{x + size - 1})\n"
    
    sum = sat_sum(sat, x, y, x + size - 1, y + size - 1)
    
    if sum > best
      best = sum
      best_size = size
    end

    size += 1
  end

  #print "Best #{best} best size #{best_size}\n"
  
  [best, best_size]
  
end

def find_best(sat, width)
  
  best = -1000
  best_coord = [0,0]
  best_size = -1
  
  (1..width).each do |y|
    (1..width).each do |x|

      sum, size = find_best_size(sat, x, y, width)
      
      if sum > best
        #print "\nnew best #{sum} coord #{x},#{y} size #{size}\n"
        best = sum
        best_coord = [x,y]
        best_size = size
      end
    end
  end
  
  #print "best #{best} at #{best_coord}\n"
  [best_coord[0], best_coord[1], best_size]
  
end

# take the grid and make the summed-area table which
# then allows O(1) sub region summing
def summed_area_table(grid, size)
  out = grid.clone

  (1..size).each do |y|
    (1..size).each do |x|
      out[[x,y]] = out[[x,y]] + out[[x-1,y]] + out[[x,y-1]] - out[[x-1,y-1]]
    end
  end
  out
end

# Calculate the sum of an arbitrary rectangle
# using the summed area table
def sat_sum(sat,x1,y1,x2,y2)
  sat[[x2,y2]] -
    sat[[x2,y1-1]] -
    sat[[x1-1,y2]] +
    sat[[x1-1,y1-1]]
end

def draw_sat(sat, width)
  print "\n"
  (1..width).each do |y|
    (1..width).each do |x|
      printf("%4d ", sat[[x,y]])
    end
    print "\n"
  end
  print "\n"
end

def png_grid(grid)
  size = Integer.sqrt(grid.length)
  
  print "create\n"
  png = ChunkyPNG::Image.new(size, size, ChunkyPNG::Color::BLACK)

  print "drawing\n"
  grid.each do |coord,power|
    x = coord[0] - 1
    y = coord[1] - 1
    base = 128
    scale = 30
    if power > 0
      png[x,y] = ChunkyPNG::Color(base + power * scale, 0, 0)
    elsif power < 0
      png[x,y] = ChunkyPNG::Color(0, base + power * -scale, 0)
    end
  end
  
  print "save\n"
  png.save("power.png", :interlace => true)
  
end

def grid_array_to_hash(grid)
  grid_h = Hash.new(0)

  grid.each_with_index do |row,rindex|
    row.each_with_index do |col,cindex|
      grid_h[[cindex + 1,rindex + 1]] = col 
    end
  end
  grid_h
end

grid = make_grid(5719)
sat_large = summed_area_table(grid, 300)
x,y,best = find_best(sat_large, 300)
print "Solution is #{x},#{y},#{best}\n"
