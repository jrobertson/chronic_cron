#!/usr/bin/env ruby

# file: chronic_cron.rb

require 'app-routes'
require 'chronic'
require 'cron_format'


class ChronicCron
  include AppRoutes
  
  attr_reader :to_expression  
  
  def initialize(s, now=Time.now)
    @now = now
    super()
    @params = {}
    expressions(@params)
    @to_expression = find_expression s
    
    if @to_expression.nil? then
      t = Chronic.parse('tomorrow')
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
    get /(\d{1,2}):(\d{1,2})am every day/ do |hrs, mins|
      "%s %s * * *" % [mins, hrs]
    end

    # e.g. at 11:00 and 16:00 on every day
    get /(\d{1,2}):(\d{1,2}) and (\d{1,2}):\d{1,2} on every day/ do
      "%s %s,%s * * *" % params[:captures].values_at(1,0,2)
    end

    get('hourly')   {'0 * * * *'}    
    get('daily')    {'0 0 * * *'}
    get('midnight') {'0 0 * * *'}
    get('weekly')   {'0 0 * * 0'}
    get('monthly')  {'0 0 1 * *'}
    get('yearly')   {'0 0 1 1 *'}
    get('annually') {'0 0 1 1 *'}
    
  end
  
  alias find_expression run_route
  
end