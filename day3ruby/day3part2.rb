# Day 2 of Advent of Code 2018
# https://adventofcode.com/2018/day/2 part 2

# Find a non-overlapping claim

require 'pry-byebug'

filename = ARGV.first || __dir__ + '/input.txt'

file = File.open(filename, 'rb')
contents = file.read
lines = contents.split("\n")

class Claim
  def initialize(str)
    id,x,y,w,h =
             /#([0-9]+) @ ([0-9]+),([0-9]+): ([0-9]+)x([0-9]+)/.match(str).captures

    @id = id.to_i
    @x = x.to_i
    @y = y.to_i
    @w = w.to_i
    @h = h.to_i
  end

  def id
    @id
  end

  def xy
    [@x, @y]
  end

  def wh
    [@w, @h]
  end

end

# A map is a grid of 1000 by 1000 where each grid square maintains the number of claims upon it

class Grid
  def initialize(size)
    @grid = Hash.new(0)
    @size = size
  end

  def xy_to_key(x,y)
    "#{x},#{y}"
  end
  
  def getClaimCount(x,y)
    @grid[xy_to_key(x,y)]
  end

  def incClaimCount(x,y)
    @grid[xy_to_key(x,y)] = @grid[xy_to_key(x,y)] + 1
  end

  def countClaims()
    lx = 0
    count = 0
    
    while lx < @size do
      ly = 0
      while ly < @size do
        this_count = getClaimCount(lx,ly)
        if this_count >= 2
          count += 1
        end
        
        ly += 1
      end
      
      lx += 1      
    end

    count
    
  end
    
  def draw
    lx = 0
    ly = 0
    count = 0
    
    while ly < @size do
      lx = 0
      while lx < @size do
        print @grid[xy_to_key(lx,ly)]
        print ' '
        lx += 1
      end
      print "\n"
      ly += 1
    end
  end      
       
  def claimRect(claim)
    x,y = claim.xy
    w,h = claim.wh

    ly = y

    while ly <= (y + h - 1) do
      lx = x
      while lx <= (x + w - 1) do
        incClaimCount(lx,ly)
        lx += 1
      end
      
      ly += 1      
    end
    
  end

  def checkRectAll1(claim)
    x,y = claim.xy
    w,h = claim.wh

    ly = y

    while ly <= (y + h - 1) do
      lx = x
      while lx <= (x + w - 1) do
        if getClaimCount(lx,ly) != 1
          return false
        end
        lx += 1
      end
      
      ly += 1      
    end

    return true
  end
  
end

g = Grid.new(1000)

# First populate the grid

lines.each do |line|
  claim = Claim.new(line)

  g.claimRect(claim)

end

# Now do the same again but this time we want to simply
# check if a rect is entirely non-overlapping
# Each inch is 1

lines.each do |line|
  claim = Claim.new(line)

  if g.checkRectAll1(claim) == true
    puts claim.id
    break
  end

end



