#require 'pry-byebug'
require 'io/console'

# track recipes
$recipes = [3,7]

# track positions
$elf1 = 0
$elf2 = 1

def iterate
  sum = $recipes[$elf1] + $recipes[$elf2]
  if sum >= 10
    $recipes << 1
    $recipes << (sum - 10)
  else
    $recipes << sum
  end

  l = $recipes.length

  $elf1 = ($elf1 + $recipes[$elf1] + 1) % l
  $elf2 = ($elf2 + $recipes[$elf2] + 1) % l
end

def check_solution(recipes, seq, offset)
  i = recipes.length - 1 - offset
  s = seq.length - 1

  while s >= 0
    if recipes[i] == seq[s]
      i -= 1
      s -= 1
    else
      return false
    end
  end

  print "Winner, winner, chicken dinner! #{recipes.length - seq.length} #{seq.length}\n"

  s = recipes.length - 10
  while s < recipes.length
    print "#{s} #{recipes[s]}\n"
    s += 1
  end
  
  return true
end

def solve(seq)
  
  loop do
    iterate

    break if check_solution($recipes, seq, 0)
    break if check_solution($recipes, seq, 1)
    
    if $recipes.length % 100000 == 0
      print "."
    end
    
  end

end

print "\n"
solve([5,1,5,8,9])
$recipes = [3,7]
$elf1 = 0
$elf2 = 1

print "\n"
solve([0,1,2,4,5])
$recipes = [3,7]
$elf1 = 0
$elf2 = 1

print "solving 1 8 7 2 5 1 should be 187251\n" 
solve([1,8,7,2,5,1])
$recipes = [3,7]
$elf1 = 0
$elf2 = 1

print "\n"
solve([9,2,5,1,0])
$recipes = [3,7]
$elf1 = 0
$elf2 = 1

print "\n"
solve([5,9,4,1,4])

print "solving 147061\n"

$recipes = [3,7]
$elf1 = 0
$elf2 = 1

solve([1,4,7,0,6,1])

print "635041\n"

$recipes = [3,7]
$elf1 = 0
$elf2 = 1

solve([6,3,5,0,4,1])

print "\n"

