
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

# Run through all the events tracking guard sleep patterns to find the sleepiest

guard_sleep = Hash.new(0)
current_guard = nil
sleep_start = 0

sorted_events.each do |event|
  pretty = event.date.strftime('%Y-%m-%d %H:%M')
  #print("#{pretty} event #{event.event}\n")

  case event.event
  when :wake
    minute = event.date.minute
    sleep_time = minute - sleep_start
    guard_sleep[current_guard] += sleep_time
  when :sleep
    sleep_start = event.date.minute
  else
    current_guard = event.event
  end
  
end

# Most sleep?

sleepy_guard, slept = guard_sleep.max_by{|g,s| s}

print "Guard ##{sleepy_guard} slept the most (#{slept} minutes)\n" 

# Now we need to populate the guards sleep at each individual minute
# A similar loop to above

# Tracks times slept at each individual minute
guard_sleep_minutes = Hash.new(0)

sleep_start = 0
current_guard = nil

sorted_events.each do |event|
  #pretty = event.date.strftime('%Y-%m-%d %H:%M')
  # print("#{pretty} event #{event.event}\n")

  case event.event
  when :wake
    minute = event.date.minute
    if current_guard == sleepy_guard
      (sleep_start..minute).each{ |m| guard_sleep_minutes[m] += 1 }
    end
  when :sleep
    sleep_start = event.date.minute
  else
    current_guard = event.event
  end
  
end

sleepiest_minute, times_slept_at_sleepiest_minute = guard_sleep_minutes.max_by { |k,v| v }

print "sleepiest minute #{sleepiest_minute} slept #{times_slept_at_sleepiest_minute} times\n"

answer = sleepiest_minute * sleepy_guard.to_i

print "Answer #{answer}\n"
