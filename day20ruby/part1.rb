require 'pry-byebug'
require 'io/console'

filename = ARGV.first || __dir__ + '/input.txt'

file = File.open(filename, 'rb')
contents = file.read
contents = contents.chars

Room = Struct.new(:left, :right, :up, :down) do

  def room_count
    0 + (left ? 1 : 0) + (right ? 1 : 0) + (down ? 1 : 0) + (up ? 1 : 0)
  end
  
end

# returns the remaining input
def expand_map(input, loc, room, stop_at, rooms)
  next_move, *rest = input
  while next_move != stop_at do
    case next_move
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

    next_move, *rest = rest
  end
  rest
end

# Map of coordinates to rooms
rooms = Hash.new{Room.new}
start = [0,0]
rooms[start] = Room.new

rest = expand_map(contents, [0,0], Room.new, '$', rooms)

def expand_routes(input, routes)

  

  
end

routes = expand_routes(contents, [])

rooms.each{|k,v| printf "#{k} #{(v.room_count())}\n" }

# We need to be able to split choice routes in brackets into the individual parts
# taking care to correctly ignore any nested brackets
# Returns an array of new routes not including the begin and end bracket
def split_routes(route)

  # Calculate the positions of all the | and the final ) as offsets into rest
  cur_pos=1 # Skipping the initial '('
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

printf "#{split_routes("(EE|WW|)N$".chars)}\n"
printf "#{split_routes("(EE|WW|NN)N$".chars)}\n"
printf "#{split_routes("(EE|(WW|EE)|NN)N$".chars)}\n"



