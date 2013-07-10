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
    @params = {}
    expressions(@params)

    @to_expression = find_expression(s.sub(/^(?:on|at)\s+/,''))

    if @to_expression.nil? then
      t = Chronic.parse(s)
      @to_expression = "%s %s %s %s * %s" % t.to_a.values_at(1,2,3,4,5)
    end
    
    @cf = CronFormat.new(@to_expression, now)    

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

    # e.g. 10:15am every day
    get /(\d{1,2}):(\d{1,2})([ap]m)? every day/ do |raw_hrs, mins|
      hrs = meridiem == 'pm' ? raw_hrs.to_i + 12 : raw_hrs
      "%s %s * * *" % [mins, hrs]
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
    get /(\d{1,2}):(\d{1,2})([ap]m)? (?:on )?every (\w+)/ do 
                                              |raw_hrs, mins, meridiem, wday|
      hrs = meridiem == 'pm' ? raw_hrs.to_i + 12 : raw_hrs
      "%s %s * * %s" % [mins, hrs , wday]
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
  end
  
  alias find_expression run_route
  
end
