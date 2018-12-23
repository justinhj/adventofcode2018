require 'pry-byebug'
require 'io/console'

filename = ARGV.first || __dir__ + '/input.txt'

file = File.open(filename, 'rb')
contents = file.read

lines = contents.split("\n")

# initial state: #..#.#..##......###...###
# pot state consists of a string of pots that extend to the right
# and left... we track the first pot (pot 0) with the index into
# the array
def pots_from_initial_pos(initial)
  
  pot_states = /initial state: ([#\.]+)/.match(initial).captures[0]

  [pot_states, 0]
  
end

pots, first_pot = pots_from_initial_pos(lines.shift)

# discard empty line
lines.shift

# load the rules

def load_rules(lines)
  rules = []
  lines.each do |line| 
    rule = /([.#]+) => ([.#])/.match(line).captures
    rules << rule
  end
  rules
end

rules = load_rules(lines)

# note to make matching simple we can extend the pots at
# any iteration to make sure that there are enough empty ones
# to take account of growth, there need only be two

def iterate(pots, start_pot, rules)

#  print "incoming pots #{pots}\n"
  
  count_end_empty_pots = 0
  i = pots.length - 1
  while pots[i] == '.'
    count_end_empty_pots += 1
    i -= 1
  end

  if count_end_empty_pots < 3
    add_pots = 3 - count_end_empty_pots
#    print "Adding #{add_pots} pots at end\n"
    pots += "." * add_pots
  end

#  print "after add right pots #{pots}\n"

  count_start_empty_pots = 0
  i = 0
  while pots[i] == '.'
    count_start_empty_pots += 1
    i += 1
  end
  
  if count_start_empty_pots < 3
    add_pots = 3 - count_end_empty_pots
    pots = "." * add_pots + pots
    start_pot += add_pots
#    print "Adding #{add_pots} pots at start. First pot now at #{start_pot}\n"
  end

#  print "after add left pots #{pots}\n"
  
  # Now find a matching rule and apply it
  # So as not to modify the plants before the rules have all been
  # applied we'll keep a hash of plant states to modify and
  # apply them at the end of the rule application

  plant_changes = []
  rules.each do |rule|
    search_pos = 0
    found = true
    while found do
      match = pots.match(Regexp.escape(rule[0]), search_pos)

      found = false if match.nil?

      if found
#        printf "#{rule[0]} matches so #{rule[1]} is new state of pot at index #{match.begin(0) + 2}\n"
        plant_changes << [rule[1], match.begin(0) + 2]
        search_pos = match.begin(0) + 1
      end
    end
  end

  #binding.pry

  pots = '.' * pots.length 
  
  # # Apply plant births and deaths
  plant_changes.each do |change|
    pots[change[1]] = change[0]
  end
  
#  print "after apply changes #{pots}\n"
  
  [pots, start_pot]
end

def get_total(first_pot, pots)
  sum = 0
  
  (0...pots.length).each_with_index do |pot, index|
    if pots[index] == '#'
      sum += (index - first_pot)
    end
  end
  sum
end

generations = 10000


gen = 1
while gen <= generations
  pots, first_pot = iterate(pots, first_pot, rules)

  if false # gen % 1 == 0
    print "gen #{gen} length #{pots.length.to_s} total #{get_total(first_pot, pots)}\n"
  end


  if gen == generations
    total = get_total(first_pot, pots)
    printf "\ngen #{gen} #{pots} total #{total}\n"
    exit
  end

  gen += 1

  
end
