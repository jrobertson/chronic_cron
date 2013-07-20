#!/usr/bin/env ruby

# file: chronic_cron.rb

require 'app-routes'
require 'chronic'
require 'cron_format'
require 'timetoday'


class ChronicCron
  include AppRoutes
  
  attr_reader :to_expression  
  
  def initialize(s, now=Time.now)
    
    @now = now
    
    super()
    @params = {input: s}
    expressions(@params)

    expression = find_expression(s.sub(/^(?:on|at)\s+/,''))
    @cf = CronFormat.new(expression, now)    
    @to_expression = @cf.to_expression

  end
  
  def next()    @cf.next    end
  def to_time() @cf.to_time end
    
  protected

  def expressions(params) 

    r = '[0-9\*,\?\/\-]+'
    # e.g. 00 5 15 * *
    get /(#{r}\s+#{r}\s+#{r}\s#{r}\s#{r})(\s#{r})?/ do
      "%s%s" % params[:captures]
    end

    # e.g. 9:00-18:00 every day
    get /(\d{1,2}):(\d{1,2})-(\d{1,2}):\d{1,2}\s+every day/ do
      "%s %s-%s * * *" % params[:captures].values_at(1,0,2)
    end    

    # e.g. every 30mins from 8:00am until 8:00pm mon-fri
    get /every\s+(\d+)mins\s+from\s+(\d{1,2}):(\d{1,2})([ap]m)(?:\s+until\s+|\s*-\s*)(\d{1,2}):\d{1,2}([ap]m)\s+(\w+\-\w+)/ do 
         |interval_mins, r_hrs1, mins1, meridiem1, r_hrs2, meridiem2, wdays|
      hrs1 = meridiem1 == 'pm' ? r_hrs1.to_i + 12 : r_hrs1
      hrs2 = meridiem2 == 'pm' ? r_hrs2.to_i + 12 : r_hrs2
      "%s/%s %s-%s * * %s" % [mins1.to_i, interval_mins, hrs1, hrs2, wdays]
    end        
    
    # e.g. every 30mins from 8:00am until 8:00pm every day
    get /every\s+(\d+)mins\s+from\s+(\d{1,2}):(\d{1,2})([ap]m)(?:\s+until\s+|\s*-\s*)(\d{1,2}):\d{1,2}([ap]m)\s+every day/ do 
                  |interval_mins, r_hrs1, mins1, meridiem1, r_hrs2, meridiem2|
      hrs1 = meridiem1 == 'pm' ? r_hrs1.to_i + 12 : r_hrs1
      hrs2 = meridiem2 == 'pm' ? r_hrs2.to_i + 12 : r_hrs2
      "%s/%s %s-%s * * *" % [mins1.to_i, interval_mins, hrs1, hrs2]
    end        
    
    # e.g. 8:00am until 8:00pm every day
    get /(\d{1,2}):(\d{1,2})([ap]m)(?:\s+until\s+|\s*-\s*)(\d{1,2}):\d{1,2}([ap]m)\s+every day/ do 
                                  |r_hrs1, mins1, meridiem1, r_hrs2, meridiem2|
      hrs1 = meridiem1 == 'pm' ? r_hrs1.to_i + 12 : r_hrs1
      hrs2 = meridiem2 == 'pm' ? r_hrs2.to_i + 12 : r_hrs2
      "%s %s-%s * * *" % [mins1.to_i, hrs1, hrs2]
    end    

    # e.g. 10:15am every day
    get /(\d{1,2}):(\d{1,2})([ap]m)?\s+every day/ do |raw_hrs, mins, meridiem|
      hrs = meridiem == 'pm' ? raw_hrs.to_i + 12 : raw_hrs
      "%s %s * * *" % [mins.to_i, hrs]
    end

    # e.g. at 7:30am  Monday to Friday
    get /(\d{1,2}):(\d{1,2})([ap]m)?\s+(\w+) to (\w+)/ do 
                                  |raw_hrs, mins, meridiem, wday1, wday2|
      hrs = meridiem == 'pm' ? raw_hrs.to_i + 12 : raw_hrs
      "%s %s * * %s-%s" % [mins.to_i, hrs , wday1, wday2]
    end      
    
    # e.g. at 11:00 and 16:00 on every day
    get /(\d{1,2}):(\d{1,2}) and (\d{1,2}):\d{1,2} (?:on )?every day/ do
      "%s %s,%s * * *" % params[:captures].values_at(1,0,2)
    end

    
    get('hourly')   {'0 * * * *'}    
    get('daily')    {'0 0 * * *'}
    get('midnight') {'0 0 * * *'}
    get('weekly')   {'0 0 * * 0'}
    get('monthly')  {'0 0 1 * *'}
    get('yearly')   {'0 0 1 1 *'}
    get('annually') {'0 0 1 1 *'}
    
    # e.g. at 10:30pm on every Monday
    get /(\d{1,2}):(\d{1,2})([ap]m)?\s+(?:on )?every (\w+)/ do 
                                              |raw_hrs, mins, meridiem, wday|
      hrs = meridiem == 'pm' ? raw_hrs.to_i + 12 : raw_hrs
      "%s %s * * %s" % [mins, hrs , wday]
    end
    
    # e.g. at 10pm on every Monday
    get /(\d{1,2})([ap]m)?\s+(?:on )?every (\w+)/ do 
                                              |raw_hrs, meridiem, wday|
      hrs = meridiem == 'pm' ? raw_hrs.to_i + 12 : raw_hrs
      "0 %s * * %s" % [hrs , wday]
    end    
    
    # e.g. every 10 minutes
    get(/every (\d{1,2}) min(?:ute)?s?/){|mins| "*/%s * * * *" % [mins]}
    get(/every min(?:ute)?/){"* * * * *"}
    
    # e.g. every 2 hours
    get(/every (\d{1,2}) h(?:ou)?rs?/){|hrs| "* */%s * * *" % [hrs]}
    get(/every hour/){ "0 * * * *"}
    
    # e.g. every 2 days
    get(/every (\d{1,2}) days?/){|days| "* * */%s * *" % [days]}    
    get(/every day/){ "0 0 * * *"}
    
    get /any\s?time today/ do
      self.instance_eval %q(
      def next()
        t = TimeToday.any + DAY
        @cf = CronFormat.new("%s %s %s %s *" % t.to_a[1..4])
        t
      end
      )
      "%s %s %s %s *" % TimeToday.future.to_a[1..4]
    end
    
    # e.g. every tuesday at 4pm
    get /every\s+((?:mon|tue|wed|thu|fri|sat|sun)\w*)\s+at\s+(\d{1,2})([ap]m)/i do
                                              |wday, raw_hrs, meridiem, |
      hrs = meridiem == 'pm' ? raw_hrs.to_i + 12 : raw_hrs
      "0 %s * * %s" % [hrs , wday]
    end

    # e.g. every tuesday at 4:40pm
    get /every\s+((?:mon|tue|wed|thu|fri|sat|sun)\w*)\s+at\s+(\d{1,2}):(\d{1,2})([ap]m)/i do
                                            |wday, raw_hrs, mins, meridiem, |
      hrs = meridiem == 'pm' ? raw_hrs.to_i + 12 : raw_hrs
      "%s %s * * %s" % [mins, hrs , wday]
    end    
    
    get '*' do
      t = Chronic.parse(params[:input])
      "%s %s %s %s * %s" % t.to_a.values_at(1,2,3,4,5)
    end    
  end
  
  alias find_expression run_route
  
end
