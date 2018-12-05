
=begin 
Parse the data, needs to be sorted by date and time

[1518-07-31 00:54] wakes up
[1518-04-09 00:01] Guard #3407 begins shift
[1518-04-03 00:36] wakes up
[1518-10-24 00:03] Guard #1049 begins shift
[1518-03-15 00:11] falls asleep

Watch out for guards coming on duty at 11 oclock the day before, can round that to midnight 

Run through the events and for each guard total up the minutes asleep and pick the guard with the most

Next we want to run through all events for that guard plotting all the minutes he is asleep in a map (minute => times asleep)

Then multiply those together 

=end

require 'date'
require 'pry-byebug'

filename = ARGV.first || __dir__ + '/input.txt'

file = File.open(filename, 'rb')
contents = file.read
lines = contents.split("\n")

class Event

  def initialize(str)
    raw_date,raw_event = /\[([0-9\-: ]+)\] (.*$)/.match(str).captures
    @event = case raw_event
             when 'wakes up'
               :wake
             when 'falls asleep'
               :sleep
             else
               /Guard #([0-9]+) begins shift/.match(raw_event).captures[0]
             end
    
    @date = DateTime.parse(raw_date)
  end

  def date
    @date
  end

  def event
    @event
  end

end

events = lines.map{ |line| Event.new(line) }

sorted_events = events.sort_by { |event| event.date }

# Now we need to populate all the guards sleep at each individual minute

# Tracks times slept at each individual minute 
guards_sleep_minutes = Hash.new()
# this is a hash of hashes, so guard id to another hash of minutes to times slept

sleep_start = 0
current_guard = nil

sorted_events.each do |event|

  case event.event
  when :wake
    minute = event.date.minute

    if guards_sleep_minutes.include? current_guard
      guards_minutes = guards_sleep_minutes[current_guard]      
    else
      guards_minutes = Hash.new(0)
    end

    (sleep_start..minute).each{ |m| guards_minutes[m] += 1 }

    guards_sleep_minutes[current_guard] = guards_minutes

  when :sleep
    sleep_start = event.date.minute
  else
    current_guard = event.event
  end
  
end

# Now create a map of guard id to most popular sleep minute

guards_to_minute = Hash.new(0)

guards_sleep_minutes.each { | g, mins |
  fave_minute = mins.max_by { |k,v| v }[0]
  print "guard #{g} fave min #{fave_minute}\n"
  guards_to_minute[g] = fave_minute
}

guard, minute = guards_to_minute.max_by { |g,m| m }
answer = guard.to_i * minute

print "Answer is Guard ##{guard} at minute #{minute} : #{answer}\n"
