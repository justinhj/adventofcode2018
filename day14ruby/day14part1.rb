
# track recipes
$recipes = [3,7]

# track positions
$elf1 = 0
$elf2 = 1

def draw_recipes
  $recipes.each_with_index do |r, i|
    if i == $elf1
      print "(#{r}) "
    elsif i == $elf2
      print "[#{r}] "
    else
      print " #{r}  "
    end
  end
  print "\n"
end

def draw_10_after(n)
  (n..n+1+10).each do |i|
    r = $recipes[i]
    print "#{r}"
  end
  print "\n"
end

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

def solve(count)

  while $recipes.length < (count + 10)
    iterate
  end

  draw_10_after(count)

end

# solve(9)
# solve(5)
# solve(18)
# solve(2018)
solve(635041)

