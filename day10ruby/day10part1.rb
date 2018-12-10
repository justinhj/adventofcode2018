# Day 10 lol

require 'pry-byebug'
require 'io/console'

filename = ARGV.first || __dir__ + '/input.txt'

file = File.open(filename, 'rb')
contents = file.read

lines = contents.split("\n")

dudes = []

lines.each do |line| 
  x,y,dx,dy = /position=<[ ]*([\-0-9]+),[ ]*([\-0-9]+)> velocity=<[ ]*([\-0-9]+),[ ]*([\-0-9]+)>/.match(line).captures

  dudes << {x: x.to_i, y: y.to_i, dx: dx.to_i, dy: dy.to_i}
end

def draw_message(dudes)

  min_x = dudes.min_by { |dude| dude[:x] }[:x]
  max_x = dudes.max_by { |dude| dude[:x] }[:x]

  min_y = dudes.min_by { |dude| dude[:y] }[:y]
  max_y = dudes.max_by { |dude| dude[:y] }[:y]

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

  dudes = dudes.map do |dude|

    dude[:x] += dude[:dx]
    dude[:y] += dude[:dy]
    
  end
  
end

loop do
  draw_message(dudes)

  k = STDIN.getch

  if k == 'q'
    break
  end
  
  move(dudes)
end





