# same as part 1 but with linked list for board

require 'pry-byebug'

filename = ARGV.first || __dir__ + '/input.txt'

file = File.open(filename, 'rb')
contents = file.read

lines = contents.split("\n")

puts lines.length

inputs = []

lines.each do |line| 
  num_players, last_marble_score = /([0-9]+) players; last marble is worth ([0-9]+) points/.match(line).captures

  parsed = {num_players: num_players.to_i, last_marble_score: last_marble_score.to_i}

  puts parsed
  
  inputs << parsed
end

# return new pos and any player points
def insert_marble(turn, board)

  score = 0
  if turn % 23 == 0
#    binding.pry
    board = board_skip(board, -7)
    board[:previous][:next] = board[:next]
    board[:next][:previous] = board[:previous]
    marble = board[:value]
    score = turn + marble
    board = board[:previous]
  else
    board = board_skip(board, 1)
    new_board = {previous: board, next: board[:next], value: turn}
    board[:next][:previous] = new_board
    board[:next] = new_board
    board = new_board

  end

  return board, score
end

# Assumes board has no repeated values or lol
def print_board(board)
  stop_value = board[:value]
  print "(#{board[:value]}) "
  
  b = board[:next]
  while b[:value] != stop_value
    print "#{b[:value]} "
    b = b[:next]
  end    
  print "\n"
end

def board_skip(board, skip)
  if skip < 0
    (0...-skip).each do |_|
      board = board[:previous]
    end
  else
    (0...skip).each do |_|
      board = board[:next]
    end
  end

  board
end

def solve(input)

  board = {previous: nil, next: nil, value: 0}
  board[:previous] = board
  board[:next] = board

  player_scores = Hash.new(0)
  turn = 1

 # print_board(board)

#binding.pry
  
  (1..input[:num_players]).cycle.each do |player|

    board, points = insert_marble(turn, board)

    if points > 0
      player_scores[player] += points
      # print "turn #{turn} player #{player} points #{points}\n"
    end
    
    print_board(board)
    
    turn += 1

    print "Turn #{turn} #{Time.new.inspect}\n" # if turn % 500000 == 0
    
    break if turn == input[:last_marble_score]
    
  end
  #binding.pry
  player_scores = player_scores.sort_by {|k,v| v}.reverse
  print "scores #{player_scores}\n"
  
end

inputs.each do |input|
  answer = solve(input)
end





