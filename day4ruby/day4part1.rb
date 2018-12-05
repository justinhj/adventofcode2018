
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

sorted_events.each do |event|
  pretty = event.date.strftime('%Y-%m-%d %H:%M')
  print("parsed #{pretty} event #{event.event}\n")
end





