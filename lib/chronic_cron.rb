#!/usr/bin/env ruby

# file: chronic_cron.rb

require 'date'
require 'time'

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
  
  def self.parse(s)
    
    raw_a = s.split
    raw_a << '*' if raw_a.length <= 5 # add the year?

    units = {min: 0, hour: 0, mday: 1, month: 1, wday: nil, year: Time.now.year}

    dt = units.values.map do |start|
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

    ceil = {min: 60, hour: 23, day: 31, month: 12}.values

    if repeaters.any? then
      repeaters.each_with_index do |x,i|
        if x then
          raw_date[i] = raw_date[i].map {|y|
            (y.to_i..ceil[i]).step(x.to_i).to_a.map(&:to_s)
          }.flatten
        else  
          raw_date[i]
        end 
      end
    end  


    a = raw_date.inflate.map do |date|

      wday, year = date.pop(2)
      date << year
      next unless day_valid? date.reverse.take 3
      t = Time.parse("%s-%s-%s %s:%s" % date.reverse)

      i = 3
      while t < Time.now and i >= 0 and raw_a[i][/\*/]
        date[i] = Time.now.to_a[i+1].to_s
        t = Time.parse("%s-%s-%s %s:%s" % date.reverse)
        i -= 1
      end  
        
      if t < Time.now then

        if t.month < Time.now.month and raw_a[4] == '*' then
          # increment the year
          date[4].succ!
          t = Time.parse("%s-%s-%s %s:%s" % date.reverse)
        elsif t.day < Time.now.day and raw_a[3] == '*' then
          # increment the month
          if date[3].to_i <= 11 then
            date[3].succ!
          else 
            date[3] = '1'
            date[4].succ!
          end
          t = Time.parse("%s-%s-%s %s:%s" % date.reverse)
        elsif  t.hour < Time.now.hour and raw_a[2] == '*' then
          # increment the day
          t += 60 * 60 * 24 * ((Time.now.day - date[2].to_i) + 1)
        elsif t.min < Time.now.min and raw_a[1] == '*' then
          # increment the hour
          t += 60 * 60 * ((Time.now.hour - date[1].to_i) + 1)
        elsif raw_a[0] == '*' then
          # increment the minute
          t += 60 * ((Time.now.min - date[0].to_i) + 1)
        end   

      end

      if wday == '*' and raw_a[2] == '*' then
        wday = t.wday 
      elsif wday then
        t += (60 * 60 * 24) until t.wday == wday.to_i
      end

      t     
    end

    a.compact.min
  end
  
end
