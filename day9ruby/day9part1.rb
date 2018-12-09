require 'pry-byebug'

filename = ARGV.first || __dir__ + '/input.txt'

file = File.open(filename, 'rb')
contents = file.read

lines = contents.split("\n")

puts lines.length

inputs = []

lines.each do |line| 
  num_players, last_marble_score = /([0-9]+) players; last marble is worth ([0-9]+) points/.match(line).captures

  parsed = {num_players: num_players.to_i, last_marble_score: last_marble_score.to_i * 100}

  puts parsed
  
  inputs << parsed
end

# return new board, new pos and any player points
def insert_marble(turn, current_pos, board)
  insert_at = 0
  score = 0
  
  if turn % 23 == 0
    insert_at = (current_pos - 7) % board.length
    marble = board.delete_at(insert_at)
    score = turn + marble
  else
    if board.length < 2
      insert_at = 1
    else
      insert_at = (current_pos + 2) % board.length
    end
    board.insert(insert_at, turn)
  end

  return insert_at, score
end

def print_board(board, cp)
  board.each_with_index do |b, i|
    if i == cp
      print "(#{b}) "
    else
      print "#{b} "
    end    
  end
  print "\n"
end

def solve(input)

  board = [0]

  player_scores = Hash.new(0)
  current_pos = 0
  turn = 1

  print_board(board, current_pos)

  (1..input[:num_players]).cycle.each do |player|

    current_pos, points = insert_marble(turn, current_pos, board)

    if points > 0
      player_scores[player] += points
      # print "turn #{turn} player #{player} points #{points}\n"
    end
    
    #print_board(board, current_pos)
    
    turn += 1

    print "Turn #{turn} #{Time.new.inspect}\n" if turn % 500000 == 0
    
    #break if points == input[:last_marble_score]
    #break if turn == 26
    break if turn == input[:last_marble_score]
    
  end
  #binding.pry
  player_scores = player_scores.sort_by {|k,v| v}.reverse
  print "scores #{player_scores}\n"
  
end

inputs.each do |input|
  answer = solve(input)
end





