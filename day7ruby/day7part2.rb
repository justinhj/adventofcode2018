require 'set'
# require 'pry-byebug'

filename = ARGV.first || __dir__ + '/input.txt'

file = File.open(filename, 'rb')
contents = file.read
lines = contents.split("\n")

# Map of dependencies as map of A to List[Deps]

deps = {}

not_made = Set[]
making = Set[]

lines.each do |line|
  a, b = /Step ([A-Z]) must be finished before step ([A-Z]) can begin./.match(line).captures

  current_deps = deps[b]
  current_deps = [] if current_deps.nil?
  current_deps = current_deps << a
  not_made << a
  not_made << b
  deps[b] = current_deps
end

# Tracks available workers and what they are building
class Worker
  attr_accessor :id, :building, :seconds_left

  def initialize(id)
    @id = id
    @building = nil
    @seconds_left = 0
  end

  def build(thing)
    @building = thing
    @seconds_left = (thing.ord - 'A'.ord) + 1 + 60
    print "Build #{thing} seconds left #{@seconds_left}\n"
  end
end

workers = (0...5).map { |n| Worker.new(n) }
minute = 0

loop do
  print "Minute #{minute}\n"

  workers.each do |w|
    next if w.seconds_left.zero?

    w.seconds_left -= 1
    next if w.seconds_left > 0

    print "Worker #{w.id} finished making #{w.building} at #{minute}\n"
    making.delete(w.building)
    w.building = nil

    if making.empty? && not_made.empty?
      print "Eveything is made at #{minute}\n"
      break
    end
  end

  print "still making #{making} not made #{not_made}\n"

  if making.empty? && not_made.empty?
    print "Eveything is made at #{minute}\n"
    break
  end

  buildable = []

  not_made.each do |thing|
    requires = deps[thing]

    if requires.nil?
      buildable << thing
    elsif ((making | not_made) & requires).empty?
      buildable << thing
    end
  end

  # Assign buildable things to idle workers

  buildable.each do |thing|
    available = workers.find { |w| w.seconds_left.zero? }

    next if available.nil?

    not_made.delete(thing)
    making.add(thing)

    available.build(thing)

    print "Worker #{available.id} starts making #{thing}\n"
  end

  # Increment work time and build anything that was building
  minute += 1
end
