# Day 2 of Advent of Code 2018
# https://adventofcode.com/2018/day/2

require 'pry-byebug'

filename = ARGV.first || __dir__ + '/input.txt'

file = File.open(filename, 'rb')
contents = file.read
lines = contents.split("\n")

class Claim
  def initialize(str)
    id,x,y,w,h =
             /#([0-9]+) @ ([0-9]+),([0-9])+: ([0-9]+)x([0-9]+)/.match(str).captures

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
    @grid = Array.new(size, Array.new(size, 0))
    @size = size
  end

  def getClaimCount(x,y)
    if @grid[x][y] == nil
      byebug
    end
    
    @grid[x][y]
  end

  def incClaimCount(x,y)
    @grid[x][y] = @grid[x][y] + 1
  end

  def countClaims()
    lx = 0
    ly = 0
    count = 0
    
    while lx < @size do
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
        print @grid[lx][ly]
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
    
    lx = x

    while lx <= (x + w + 1) do
      ly = y
      while ly <= (y + h + 1) do
        incClaimCount(lx,ly)
        ly += 1
      end
      
      lx += 1      
    end
    
  end
  
end

g = Grid.new(10)
  
lines.each do |line|
  claim = Claim.new(line)

  g.claimRect(claim)
  
end

puts g.countClaims()
g.draw
