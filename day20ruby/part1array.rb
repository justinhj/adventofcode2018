# coding: utf-8
require 'pry-byebug'
require 'io/console'

filename = ARGV.first || __dir__ + '/input.txt'

file = File.open(filename, 'rb')
contents = file.read
directions = contents.chars

# Map is a 2d array of rooms
# Room has left right up and down booleans which default to nil
# We must use array offsets when accessing the map to handle negative x,y

MAP_WIDTH=ARGV[1].to_i || 50
MAP_HEIGHT=ARGV[2].to_i || 50

ROW_OFFSET=MAP_HEIGHT/2
COL_OFFSET=MAP_WIDTH/2

Room = Struct.new(:left, :right, :up, :down) do
  def room_count
    0 + (left ? 1 : 0) + (right ? 1 : 0) + (down ? 1 : 0) + (up ? 1 : 0)
  end
end

rooms = Array.new(MAP_HEIGHT) { Array.new(MAP_WIDTH) { Room.new } }

def draw_room(room)

  s = '?'
  if room[:up] && room[:left] && room[:right] && room[:down]
   s = '┼' 
  elsif room[:up] && room[:left] && room[:right] && room[:down].nil?
    s = '┴'
  elsif room[:up].nil? && room[:left] && room[:right] && room[:down]
    s = '┬'
  elsif room[:up] && room[:left].nil? && room[:right] && room[:down]
    s = '├'
  elsif room[:up] && room[:left] && room[:right].nil? && room[:down]
    s = '┤'
  elsif room[:up].nil? && room[:left] && room[:right].nil? && room[:down]
    s = '┐'
  elsif room[:up] && room[:left].nil?  && room[:right] && room[:down].nil?
    s = '└'
  elsif room[:up] && room[:left]  && room[:right].nil? && room[:down].nil?
    s = '┘'
  elsif room[:up].nil? && room[:left].nil?  && room[:right] && room[:down]
    s = '┌'
  elsif room[:up].nil? && room[:left]  && room[:right] && room[:down].nil?
    s = '─'
  elsif room[:up] && room[:left].nil?  && room[:right].nil? && room[:down]
    s = '│'
  elsif room[:up]
    s = '^'
  elsif room[:down]
    s = 'v'
  elsif room[:left]
    s = '<'
  elsif room[:right]
    s = '>'
  else
    s = '.'
  end

  print s

end

$draws = 0

def draw_map(rooms, force=false)

  $draws += 1

  return unless $draws % 10000000000 == 0 || force
  
  # Clear the terminal
  puts "\e[H\e[2J"

  (0...MAP_HEIGHT).each do |row|
    (0...MAP_WIDTH).each do |col|
      room = rooms[col][row]
      draw_room(room)
    end
    print "\n"
  end
  print "\nDraws #{$draws}\n"
  
  # k = STDIN.getch

  # if k == 'q'
  #   exit
  # end

  sleep 0.2
  
end

# We need to be able to split choice routes in brackets into the individual parts
# taking care to correctly ignore any nested brackets
# Returns an array of new routes not including the begin and end bracket
def split_routes(route)

  # Calculate the positions of all the | and the final ) as offsets into rest
  cur_pos=0
  positions = []
  ignore_count = 0
  cstart = cur_pos

  loop do
    cur = route[cur_pos]
    if route[cur_pos] == ')' && ignore_count == 0
      positions << [cstart, cur_pos]
      break
    elsif cur == '|' && ignore_count == 0
      positions << [cstart, cur_pos]
      cstart = cur_pos + 1
    elsif cur == '(' && ignore_count == 0
      ignore_count += 1
    elsif cur == ')' && ignore_count > 0
      ignore_count -= 1
    end
    
    cur_pos += 1
  end
  
  # Each list is the start and end slice we calculated and then the rest of the list
  positions.map do |s,e|
    route[s..e-1] + route[cur_pos+1..]
  end
  
end

# printf "#{split_routes("EE|WW|)N$".chars)}\n"
# printf "#{split_routes("EE|WW|NN)N$".chars)}\n"
# printf "#{split_routes("EE|(WW|EE)|NN)N$".chars)}\n"

# returns the remaining input
def expand_map(input, loc, room, rooms, draw, depth)
  next_move, *remaining = input

  loop do
    case next_move
    when '('
      routes = split_routes(remaining)
      routes.each {|route| expand_map(route, loc, room, rooms, draw, depth + 1)}
      break
    when '$'
      break
    when 'N'
      new_loc = [loc[0],loc[1] - 1]
      new_room = rooms[new_loc[0]][new_loc[1]]
      new_room.down = true
      room.up = true
      loc = new_loc
      room = new_room
      draw_map(rooms) if draw
    when 'W'
      new_loc = [loc[0] - 1,loc[1]]
      new_room = rooms[new_loc[0]][new_loc[1]]
      new_room.right = true
      room.left = true
      loc = new_loc
      room = new_room
      draw_map(rooms) if draw
    when 'S'
      new_loc = [loc[0],loc[1] + 1]
      new_room = rooms[new_loc[0]][new_loc[1]]
      new_room.up = true
      room.down = true
      loc = new_loc
      room = new_room
      draw_map(rooms) if draw
    when 'E'
      new_loc = [loc[0] + 1,loc[1]]
      new_room = rooms[new_loc[0]][new_loc[1]]
      new_room.left = true
      room.right = true
      loc = new_loc
      room = new_room
      draw_map(rooms) if draw
    end

#    print "Remaining length #{remaining.length} depth #{depth}\n"
    
    next_move, *remaining = remaining
  end

end

expand_map(directions, [ROW_OFFSET,COL_OFFSET], Room.new, rooms, true, 0)

draw_map(rooms, true)
    
# ┴ ULR
# ┬ DLR
# ├ UDR
# ┤ UDL
# 
# udlr
# u ^
# d V
# l <
# r >
# 
# ┐ LD
# └ UR
# ┘ UL
# ┌ DR
# ─ LR
# │ UD
# 
# ┼ UDLR
