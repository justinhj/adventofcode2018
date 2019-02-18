require 'pry-byebug'
require 'io/console'

filename = ARGV.first || __dir__ + '/input.txt'

file = File.open(filename, 'rb')
contents = file.read
directions = contents.chars

Room = Struct.new(:left, :right, :up, :down) do
  def room_count
    0 + (left ? 1 : 0) + (right ? 1 : 0) + (down ? 1 : 0) + (up ? 1 : 0)
  end
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
def expand_map(input, loc, room, rooms)
  next_move, *remaining = input
  loop do
    case next_move
    when '('
      routes = split_routes(remaining)
      routes.each {|route| expand_map(route, loc, room, rooms)}
      break
    when '$'
      break
    when 'N'
      new_loc = [loc[0],loc[1] + 1]
      new_room = rooms[new_loc]
      new_room.down = room
      room.up = new_room
      rooms[loc] = room
      rooms[new_loc] = new_room
      loc = new_loc
      room = new_room
    when 'W'
      new_loc = [loc[0] - 1,loc[1]]
      new_room = rooms[new_loc]
      new_room.right = room
      room.left = new_room
      rooms[loc] = room
      rooms[new_loc] = new_room
      loc = new_loc
      room = new_room
    when 'S'
      new_loc = [loc[0],loc[1] - 1]
      new_room = rooms[new_loc]
      new_room.up = room
      room.down = new_room
      rooms[loc] = room
      rooms[new_loc] = new_room
      loc = new_loc
      room = new_room
    when 'E'
      new_loc = [loc[0] + 1,loc[1]]
      new_room = rooms[new_loc]
      new_room.left = room
      room.right = new_room
      rooms[loc] = room
      rooms[new_loc] = new_room
      loc = new_loc
      room = new_room
    end

    next_move, *remaining = remaining
  end

end

# Map of coordinates to rooms
rooms = Hash.new{Room.new}
start = [0,0]
rooms[start] = Room.new

expand_map(directions, [0,0], Room.new, rooms)

rooms.each{|k,v| printf "#{k} #{(v.room_count())}\n" }

# Draw the map

def draw_map(rooms)
  min_x = 0
  max_x = 0
  min_y = 0
  max_y = 0

  rooms.each do |coord, room|
    x,y = coord

    min_x = [x, min_x].min
    max_x = [x, max_x].max

    min_y = [y, min_y].min
    max_y = [y, max_y].max
  end

  printf "Map extents [#{min_x},#{min_y}] to [#{max_x},#{max_y}]\n"
  
end

draw_map(rooms)
