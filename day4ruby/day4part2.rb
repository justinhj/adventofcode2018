
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
    #print "Wake at #{minute}\n"

    if guards_sleep_minutes.include? current_guard
      #puts "get #{current_guard}"
      guards_minutes = guards_sleep_minutes[current_guard]      
    else
      #puts "new #{current_guard}"
      guards_minutes = Hash.new(0)
    end

    (sleep_start...minute).each{ |m| guards_minutes[m] += 1 }

    guards_sleep_minutes[current_guard] = guards_minutes

  when :sleep
    sleep_start = event.date.minute
    #print "Sleep at #{sleep_start}\n"

  else
    puts event.event
    current_guard = event.event
    sleep_start = 0
  end
  
end

# Now create a map of guard id to most popular sleep minute

guards_to_minute_times = Hash.new(0)

guards_sleep_minutes.each { | g, mins |
  mins = mins.sort_by { |k,v| k }
  fave_minute, times = mins.max_by { |k,v| v }

  # print "guard #{g} fave min #{fave_minute} times #{times}\n"
  guards_to_minute_times[g] = [fave_minute, times]
}

guard, minute_times = guards_to_minute_times.max_by { |g,m| m[1] }

fave_minute, times = minute_times
answer = guard.to_i * fave_minute

print "Answer is Guard ##{guard} at minute #{fave_minute} : #{answer}\n"
