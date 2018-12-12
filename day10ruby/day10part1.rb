# Day 10 lol

require 'pry-byebug'
require 'io/console'
require 'chunky_png'

# Note I was going to draw a png file because the points were so large
# but then it occured to me to just run until they were close together
# and then draw it. I've left the PNG code in here for future utility

filename = ARGV.first || __dir__ + '/input.txt'

file = File.open(filename, 'rb')
contents = file.read

lines = contents.split("\n")

dudes = []

lines.each do |line| 
  x,y,dx,dy = /position=<[ ]*([\-0-9]+),[ ]*([\-0-9]+)> velocity=<[ ]*([\-0-9]+),[ ]*([\-0-9]+)>/.match(line).captures

  dudes << {x: x.to_i, y: y.to_i, dx: dx.to_i, dy: dy.to_i}
end

def png_message(dudes, num)

  min_x = dudes.min_by { |dude| dude[:x] }[:x]
  max_x = dudes.max_by { |dude| dude[:x] }[:x]

  min_y = dudes.min_by { |dude| dude[:y] }[:y]
  max_y = dudes.max_by { |dude| dude[:y] }[:y]

  scale = 20
  
  width = 6000
  height = 6000

  print "create\n"
  png = ChunkyPNG::Image.new(width, height, ChunkyPNG::Color::TRANSPARENT)

  print "drawing\n"
  dudes.each do |dude|
    x = (dude[:x] + -min_x) / scale
    y = (dude[:y] + -min_y) / scale

    png[x,y] = ChunkyPNG::Color('black @ 1.0')
  end

  print "save\n"
  png.save("filename_#{num}.png", :interlace => true)
  
end

def draw_message(dudes)

  min_x = dudes.min_by { |dude| dude[:x] }[:x]
  max_x = dudes.max_by { |dude| dude[:x] }[:x]

  min_y = dudes.min_by { |dude| dude[:y] }[:y]
  max_y = dudes.max_by { |dude| dude[:y] }[:y]

  x_range = (max_x - min_x).abs
  y_range = (max_y - min_y).abs
  
  width = 100.0
  height = 30.0
  
  (min_y..max_y).each do |y|

    points_on_row = dudes.select { |dude| dude[:y] == y }

    (min_x..max_x).each do |x| 

      if points_on_row.find { |dude| dude[:x] == x }
        print "#"
      else
        print "."
      end
    end
    print "\n"
  end
end

def move(dudes)

  dudes.map do |dude|

    dude[:x] += dude[:dx]
    dude[:y] += dude[:dy]
    
  end
  
end

def delta(dudes)

  iteration = 1
  min_delta = 9223372036854775807
  
  dudes.each do |dude|
    move(dudes)

    delta = dudes.inject(0) { |acc, dude| acc += dude[:x]**2 + dude[:y]**2 }

    min_delta = delta unless delta > min_delta

    print "step #{iteration} delta #{delta}\n"

    k = STDIN.getch
    
    if k == 'q'
      break
    end

    iteration += 1
  end
  
end

#delta(dudes)

count = 0
min_delta = 9223372036854775807
min_delta_step = 0

loop do

  # Note I ran this first to find the minimum
  # point and then just started drawing from there...
  if count == 10124
    draw_message(dudes)
    break
  end
  
  delta = dudes.inject(0) { |acc, dude| acc += dude[:x]**2 + dude[:y]**2 }

  if delta > min_delta
    if count == min_delta_step + 1
      print "min step #{count - 1}\n"
    end
  else
    min_delta = delta
    min_delta_step = count
  end

  print "step #{count} delta #{delta}\n"
  
  move(dudes)

  count += 1
end

# Solution:
# #....#..######...####...#....#..#####...#####...######..#####.
# #....#..#.......#....#..#....#..#....#..#....#.......#..#....#
# .#..#...#.......#........#..#...#....#..#....#.......#..#....#
# .#..#...#.......#........#..#...#....#..#....#......#...#....#
# ..##....#####...#.........##....#####...#####......#....#####.
# ..##....#.......#.........##....#....#..#.........#.....#....#
# .#..#...#.......#........#..#...#....#..#........#......#....#
# .#..#...#.......#........#..#...#....#..#.......#.......#....#
# #....#..#.......#....#..#....#..#....#..#.......#.......#....#
# #....#..######...####...#....#..#####...#.......######..#####.



