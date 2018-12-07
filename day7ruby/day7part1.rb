require 'set'

require 'pry-byebug'

filename = ARGV.first || __dir__ + '/input.txt'

file = File.open(filename, 'rb')
contents = file.read
lines = contents.split("\n")

# Map of dependencies as map of A to List[Deps]

deps = {}

not_made = Set[]

lines.each do |line| 
  a, b = /Step ([A-Z]) must be finished before step ([A-Z]) can begin./.match(line).captures

  current_deps = deps[b]
  if current_deps == nil
    current_deps = []
  end
  current_deps = current_deps << a
  not_made << a
  not_made << b
  deps[b] = current_deps
end

while true

  buildable = []

  not_made.each do |thing|

    requires = deps[thing]

    if requires == nil
      buildable << thing
    else

      if (not_made & requires).size == 0
        buildable << thing
      end
              
    end
    
  end

  buildable = buildable.sort

  build = buildable[0]

  print "#{build}"

  not_made.delete(build)

  if not_made.size == 0
    break
  end
  
  
end
