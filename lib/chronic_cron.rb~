#!/usr/bin/env ruby

# file: chronic_cron.rb

require 'date'
require 'time'

MINUTE = 60
HOUR = MINUTE * 60
DAY = HOUR * 24

class Array

  def inflate()
    Array.new(self.max_by {|x| x.length}.length).map do |x|
      self.map{|x| x.length <= 1 ? x.first : x.shift}
    end
  end
end


class ChronicCron
  
  def self.day_valid?(date)
    year, month, day = date
    last_day = DateTime.parse("%s-%s-%s" % [year, month.succ, 1]) - 1
    day.to_i <= last_day.day
  end  
  
  def self.parse(object, now=Time.now)
    
    raw_a = object.is_a?(String) ? object.split : object
    raw_a << '*' if raw_a.length <= 5 # add the year?

    units = now.to_a.values_at(1..4) + [nil, now.year]
      
    procs = {
      min: lambda{|x, interval| x += (interval * MINUTE).to_i},
      hour: lambda{|x, interval| x += (interval * HOUR).to_i},
      day: lambda{|x, interval| x += (interval * DAY).to_i}, 
      month: lambda{|x, interval| 
         date = x.to_a.values_at(1..5)
         interval.times { date[3].succ! }
         Time.parse("%s-%s-%s %s:%s" % date.reverse)},
      year: lambda{|x, interval| 
         date = x.to_a.values_at(1..5)
         interval.times { date[4].succ! }
         Time.parse("%s-%s-%s %s:%s" % date.reverse)}
    }

    dt = units.map do |start|
      # convert * to time unit
      lambda do |x| v2 = x.sub('*', start.to_s)
        # split any times
        multiples = v2.split(/,/)
        range = multiples.map do |time|
          s1, s2 = time.split(/-/)
          s2 ? (s1..s2).to_a : s1
        end
        range.flatten
      end

    end
    
    # take any repeater out of the unit value
    raw_units, repeaters = [], []

    raw_a.each do |x| 
      v1, v2 = x.split('/')
      raw_units << v1
      repeaters << v2
    end

    raw_date = raw_units.map.with_index {|x,i| dt[i].call(x) }
    
    # expand the repeater

    ceil = {min: MINUTE, hour: 23, day: 31, month: 12}.values

    if repeaters.any? then
      repeaters.each_with_index do |x,i|
        if x and not raw_a[i][/^\*/] then
          raw_date[i] = raw_date[i].map {|y|            
            (y.to_i...ceil[i]).step(x.to_i).to_a.map(&:to_s)
          }.flatten
        else  
          raw_date[i]
        end 
      end
    end  
   
    dates = raw_date.inflate
    
    a = dates.map do |date|
      d = date.map{|x| x ? x.clone : nil}
      wday, year = d.pop(2)
      d << year

      next unless day_valid? d.reverse.take 3
      t = Time.parse("%s-%s-%s %s:%s" % d.reverse)
        
      if t < now and wday and wday != t.wday then
        d[2], d[3] = now.to_a.values_at(3,4).map(&:to_s)
        t = Time.parse("%s-%s-%s %s:%s" % d.reverse)
        t += DAY until t.wday == wday.to_i
      end

      i = 3
      while t < now and i >= 0 and raw_a[i][/\*/]
        d[i] = now.to_a[i+1].to_s
        t = Time.parse("%s-%s-%s %s:%s" % d.reverse)
        i -= 1
      end

      if t < now then

        if t.month < now.month and raw_a[4] == '*' then
          # increment the year
          d[4].succ!
          t = Time.parse("%s-%s-%s %s:%s" % d.reverse)

          if repeaters[4] then
            d[4].succ!
            t = Time.parse("%s-%s-%s %s:%s" % d.reverse)
          end
        elsif t.day < now.day and raw_a[3] == '*' then
          # increment the month
          if d[3].to_i <= 11 then
            d[3].succ!
          else 
            d[3] = '1'
            d[4].succ!
          end
          t = Time.parse("%s-%s-%s %s:%s" % d.reverse)
        elsif  t.hour < now.hour and raw_a[2] == '*' then
          # increment the day
          t += DAY * ((now.day - d[2].to_i) + 1)
        elsif t.min < now.min and raw_a[1] == '*' then
          # increment the hour
          t += HOUR * ((now.hour - d[1].to_i) + 1)
        elsif raw_a[0] == '*' then
          # increment the minute
          t += MINUTE * ((now.min - d[0].to_i) + 1)
          t = procs.values[i].call(t, repeaters[i].to_i) if repeaters[i]
        end   

      end

      if wday then
        t += DAY until t.wday == wday.to_i
      end
      
      if t <= now and repeaters.any? then

        repeaters.each_with_index do |x,i|
          if x then
            t = procs.values[i].call(t, x.to_i)
          end
        end
      end

      t     
    end

    a.compact.min
  end
  
end
