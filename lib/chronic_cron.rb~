#!/usr/bin/env ruby

# file: chronic_cron.rb

require 'app-routes'
require 'cron_format'


class ChronicCron
  include AppRoutes
  
  attr_reader :to_expression
  
  def self.parse(s, now=Time.now)    
    CronFormat.new(s, now).to_time
  end
  
  def initialize(s, now=Time.now)
    @now = now
    super()
    @params = {}
    expressions(@params)
    @to_expression = find_expression s
    @cf = CronFormat.new(@to_expression, now)    
  end
  
  def next()    @cf.next    end
  def to_time() @cf.to_time end
    
  protected

  def expressions(params) 

    get /10:15am every day/ do 
      '15 10 * * *'
    end

    # e.g. 10:15am every day
    get /(\d{1,2}):(\d{1,2})am every day/ do |hrs, mins|
      "%s %s * * *" % [mins, hrs]
    end

    # e.g. at 11:00 and 16:00 on every day
    get /(\d{1,2}):(\d{1,2}) and (\d{1,2}):(\d{1,2}) on every day/ do
      "00 %s,%s * * *" % params.captures
    end

  end
  
  alias find_expression run_route
  
end