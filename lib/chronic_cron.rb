#!/usr/bin/env ruby

# file: chronic_cron.rb

require 'app-routes'
require 'chronic'
require 'cron_format'
require 'timetoday'


MONTHS =  (Date::MONTHNAMES[1..-1] + Date::ABBR_MONTHNAMES[1..-1]).join('|')

class ChronicCron
  include AppRoutes
  using ColouredText

  attr_reader :to_expression

  def self.parse(s)
    r = new(s)
    r.valid? ? r : nil
  end

  def initialize(s, now=Time.now, log: nil, debug: false)

    @now, @log, @debug = now, log, debug

    puts ('@now: ' + @now.inspect).debug if @debug

    super()
    @params = {input: s}
    expressions(@params)

    if s =~ /^tomorrow/i then

      s.sub!(/^tomorrow /i,'')
      expression = find_expression(s.downcase\
                                 .sub(/^(?:is|on|at|from|starting)\s+/,''))
      @cf = CronFormat.new(expression, now)
      @cf.adjust_date @cf.to_time - (24 * 60 * 60)

    else

      expression = find_expression(s.downcase\
                                 .sub(/^(?:on|at|from|starting)\s+/,''))
      puts 'expression: ' + expression.inspect if @debug
      return unless expression
      puts 'now: ' + now.inspect if @debug
      @cf = CronFormat.new(expression, now)

    end


    @to_expression = @cf.to_expression

  end

  def inspect()
    if @cf then
      "#<ChronicCron:%s @to_expression=\"%s\", @to_time=\"%s\">" %
        [self.object_id, @to_expression, @cf.to_time]
    else
      "#<ChronicCron:%s >" % [self.object_id]
    end
  end

  def next()
    @cf.next
  end

  def to_date()
    @cf.to_time.to_date
  end

  def to_time()
    @cf.to_time
  end

  def valid?
    @cf.respond_to? :to_time
  end

  protected

  def expressions(params)

    log = @log

    r = '[0-9\*,\?\/\-]+'
    daily = '(?:every day|daily)'

    # e.g. 00 5 15 * *
    get /(#{r}\s+#{r}\s+#{r}\s#{r}\s#{r})(\s#{r})?/ do

      puts 'ChronicCron#expressions 10' if @debug

      "%s%s" % params[:captures]
    end

    # e.g. 9:00-18:00 every day
    get /(\d{1,2}):(\d{1,2})-(\d{1,2}):\d{1,2}\s+#{daily}/ do

      puts 'ChronicCron#expressions 20' if @debug

      "%s %s-%s * * *" % params[:captures].values_at(1,0,2)
    end

    # e.g. every 30mins from 8:00am until 8:00pm mon-fri
    get /every\s+(\d+)\s*mins\s+from\s+(\d{1,2}):(\d{1,2})([ap]m)(?:\s+until\s+|\s*-\s*)(\d{1,2}):\d{1,2}([ap]m)\s+(\w+\-\w+)/x do
         |interval_mins, r_hrs1, mins1, meridiem1, r_hrs2, meridiem2, wdays|

      hrs1 = meridiem1 == 'pm' ? r_hrs1.to_i + 12 : r_hrs1
      hrs2 = meridiem2 == 'pm' ? r_hrs2.to_i + 12 : r_hrs2

      puts 'ChronicCron#expressions 30' if @debug

      "%s/%s %s-%s * * %s" % [mins1.to_i, interval_mins, hrs1, hrs2, wdays]
    end

    # e.g. every 30mins from 8:00am until 8:00pm every day
    get /every\s+(\d+)\s*mins\s+from\s+(\d{1,2}):(\d{1,2})([ap]m)(?:\s+until\s+|\s*-\s*)(\d{1,2}):\d{1,2}([ap]m)\s+#{daily}/ do
                  |interval_mins, r_hrs1, mins1, meridiem1, r_hrs2, meridiem2|
      hrs1 = meridiem1 == 'pm' ? r_hrs1.to_i + 12 : r_hrs1
      hrs2 = meridiem2 == 'pm' ? r_hrs2.to_i + 12 : r_hrs2

      puts 'ChronicCron#expressions 40' if @debug

      "%s/%s %s-%s * * *" % [mins1.to_i, interval_mins, hrs1, hrs2]
    end

    # e.g. 8:00am until 8:00pm every day
    get /(\d{1,2}):(\d{1,2})([ap]m)(?:\s+until\s+|\s*-\s*)(\d{1,2}):\d{1,2}([ap]m)\s+#{daily}/ do
                                  |r_hrs1, mins1, meridiem1, r_hrs2, meridiem2|
      hrs1 = meridiem1 == 'pm' ? r_hrs1.to_i + 12 : r_hrs1
      hrs2 = meridiem2 == 'pm' ? r_hrs2.to_i + 12 : r_hrs2

      puts 'ChronicCron#expressions 50' if @debug

      "%s %s-%s * * *" % [mins1.to_i, hrs1, hrs2]
    end

    # e.g. 10:15am every day
    get /(\d{1,2}):?(\d{1,2})([ap]m)?\s+#{daily}/ do |raw_hrs, mins, meridiem|
      hrs = in24hrs(raw_hrs, meridiem)

      puts 'ChronicCron#expressions 60' if @debug

      "%s %s * * *" % [mins.to_i, hrs]
    end

    # e.g. at 7:30am  Monday to Friday
    get /(\d{1,2}):?(\d{1,2})([ap]m)?\s+(\w+) to (\w+)/ do
                                  |raw_hrs, mins, meridiem, wday1, wday2|
      hrs = in24hrs(raw_hrs, meridiem)

      puts 'ChronicCron#expressions 70' if @debug

      "%s %s * * %s-%s" % [mins.to_i, hrs , wday1, wday2]
    end

    # e.g. at 11:00 and 16:00 on every day
    get /(\d{1,2}):?(\d{1,2}) and (\d{1,2}):?\d{1,2} (?:on )?#{daily}/ do

      puts 'ChronicCron#expressions 80' if @debug

      "%s %s,%s * * *" % params[:captures].values_at(1,0,2)
    end


    get('hourly')   {'0 * * * *'}
    get('daily')    {'0 0 * * *'}
    get('midnight') {'0 0 * * *'}
    get('weekly')   {'0 0 * * 0'}
    get('monthly')  {'0 0 1 * *'}
    get('yearly')   {'0 0 1 1 *'}
    get('annually') {'0 0 1 1 *'}

    weekday = '((?:mon|tue|wed|thu|fri|sat|sun)\w*)'

    # e.g. at 10:30pm on every Monday
    get /(\d{1,2}):?(\d{1,2})([ap]m)?\s+(?:on )?every #{weekday}/i do
                                              |raw_hrs, mins, meridiem, wday|
      hrs = in24hrs(raw_hrs, meridiem)

      puts 'ChronicCron#expressions 90' if @debug

      "%s %s * * %s" % [mins, hrs , wday]
    end

    # e.g. at 10pm on every Monday
    get /(\d{1,2})([ap]m)?\s+(?:on )?every #{weekday}/i do
                                              |raw_hrs, meridiem, wday|
      hrs = in24hrs(raw_hrs, meridiem)

      puts 'ChronicCron#expressions 100' if @debug

      "0 %s * * %s" % [hrs , wday]
    end

    # e.g. every 10 minutes
    get(/every (\d{1,2}) min(?:ute)?s?/){|mins| "*/%s * * * *" % [mins]}
    get(/every min(?:ute)?/){"* * * * *"}

    # e.g. every 2 hours
    get(/every (\d{1,2}) h(?:ou)?rs?/){|hrs| "* */%s * * *" % [hrs]}
    get(/every hour/){ "0 * * * *"}

    # e.g. every 2 days
    get(/every (\d{1,2}) days?/) do |days|

      log.info 'ChronicCron/expressions/get: r130' if log
      puts 'ChronicCron#expressions 150' if @debug

      "* * */%s * *" % [days]
    end

    get(/#{daily}/){ "0 0 * * *"}

    get /(?:any\s?time)?(?: today)? between (\S+) and (\S+)/ do |s1, s2|
      self.instance_eval %Q(
      def next()
        t = TimeToday.between('#{s1}','#{s2}') + DAY
        @cf = CronFormat.new("%s %s %s %s *" % t.to_a[1..4])
        t
      end
      )

      puts 'ChronicCron#expressions 170' if @debug

      "%s %s %s %s *" % TimeToday.between(s1,s2).to_a[1..4]
    end

    get /any\s?time today/ do
      self.instance_eval %q(
      def next()
        t = TimeToday.any + DAY
        @cf = CronFormat.new("%s %s %s %s *" % t.to_a[1..4])
        t
      end
      )
      puts 'ChronicCron#expressions 180' if @debug

      "%s %s %s %s *" % TimeToday.future.to_a[1..4]
    end

    # e.g. first thursday of each month at 7:30pm
    nday = '(\w+(?:st|rd|nd))\s+' + weekday + '\s+'
    get /#{nday}(?:of\s+)?(?:the|each|every)\s+month(?:\s+at\s+([^\s]+))?/i do
                                              |nth_week, day_of_week, raw_time|

      month = @now.month

      h = {
            /first|1st/i       => '1-7',
            /second|2nd/i      => '8-14',
            /third|3rd/i       => '15-21',
            /fourth|4th|last/i => '22-28'
      }

      _, day_range = h.find{|k,_| nth_week[k]}
      a = %w(sunday monday tuesday wednesday thursday friday saturday)
      wday = a.index(a.grep(/#{day_of_week}/i).first)

      raw_time ||= '6:00am'

      minute, hour = Chronic.parse(raw_time).to_a[1,2]

      puts 'ChronicCron#expressions 190' if @debug

      "%s %s %s * %s" % [minute, hour, day_range, wday]

    end

    # e.g. every tuesday at 4pm
    get /every\s+#{weekday}\s+(?:at\s+)?(\d{1,2})([ap]m)/i do
                                              |wday, raw_hrs, meridiem, |

      hrs = in24hrs(raw_hrs, meridiem)

      puts 'ChronicCron#expressions 200' if @debug

      "0 %s * * %s" % [hrs , Date::DAYNAMES.index(wday.capitalize)]
    end


    # e.g. last sunday of March at 1am

    get /last (#{Date::DAYNAMES.join('|')}) (?:of|in) \
(#{MONTHS})\s+at\s+(\d{1,2})(?::(\d{1,2}))?\
([ap]m)/i do |day, month,  raw_hrs, mins, meridiem|

      now = Chronic.parse(month, now: @now)
      puts ('now: ' + now.inspect).debug if @debug

      d = last_wdayofmonth(day, now)
      puts ('d: ' + d.inspect).debug if @debug

      hrs = in24hrs(raw_hrs, meridiem)

      puts 'ChronicCron#expressions 210' if @debug

      "%s %s %s %s *" % [mins.to_i, hrs, d.day, d.month]
    end

    # e.g. last sunday of October

    get /last (#{Date::DAYNAMES.join('|')}) (?:of|in) \
(#{MONTHS})/i do |day, month|

      now = Chronic.parse(month, now: @now)

      d = last_wdayofmonth(day, now)

      puts 'ChronicCron#expressions 220' if @debug

      "* * %s %s *" % [d.day, d.month]
    end


    # e.g. every 2nd tuesday at 4:40pm
    #
    get /every\s+2nd\s+#{weekday}\s+at\s+(\d{1,2})(?::(\d{1,2}))?([ap]m)(.*)/i do
                                    |wday, raw_hrs, mins, meridiem, remaining|

      log.info 'ChronicCron/expressions/get: r225' if log
      puts 'ChronicCron#expressions 225' if @debug

      hrs = in24hrs(raw_hrs, meridiem)
      puts 'remaining: ' + remaining.inspect if @debug

      if remaining =~ /#{MONTHS}/i then

        t = Chronic.parse(remaining.gsub(/[\(\)]/,''), :now => @now)
        "%s %s * * %s/2" % [mins.to_i, hrs, t.wday]

      else

        "%s %s * * %s/2" % [mins.to_i, hrs , wday]

      end

    end

    # e.g. every tuesday at 4:40pm
    get /every\s+#{weekday}\s+at\s+(\d{1,2}):(\d{1,2})([ap]m)/i do
                                            |wday, raw_hrs, mins, meridiem, |
      hrs = in24hrs(raw_hrs, meridiem)

      puts 'ChronicCron#expressions 230' if @debug

      "%s %s * * %s" % [mins, hrs , wday]
    end


    # e.g. every 2nd week at 6am starting from 7th Jan
    get /every 2nd week\s+at\s+([^\s]+)/ do |raw_time|

      t = Chronic.parse(raw_time, :now => @now)
      log.info 'ChronicCron/expressions/get: r240' if log
      puts 'ChronicCron#expressions 240' if @debug

      "%s %s * * %s/2" % [t.min,t.hour,t.wday]

    end


    # e.g. every 2nd monday
    get /every 2nd #{weekday}/ do |wday|

      puts 'ChronicCron#expressions 250' if @debug
      "* * * * %s/2" % [wday]

    end


    # e.g.  every 2 weeks (starting 7th Jan 2020)
    get /^every (\w+) weeks \(starting ([^\)]+)/ do |interval, raw_date|

      if @debug then
        puts ('raw_date: ' + raw_date.inspect).debug
        puts ('now: ' + @now.inspect).debug
      end

      t = raw_date ? Chronic.parse(raw_date, :now => @now) : @now
      t += WEEK * interval.to_i until t > @now
      mins, hrs = t.to_a.values_at(1,2)

      log.info 'ChronicCron/expressions/get: r260' if log
      if @debug then
        puts 'ChronicCron#expressions 260'
        puts ('t: ' + t.inspect).debug
      end

      "%s %s * * %s/%s" % [mins, hrs, t.wday, interval]
    end

    # e.g.  every 2 weeks at 6am starting from 7th Jan
     get /^every (\w+) weeks(?:\s+at\s+([^\s]+))?/ do |interval, raw_time|

      if @debug then
        puts ('raw_time: ' + raw_time.inspect).debug
        puts ('now: ' + @now.inspect).debug
      end

      t = raw_time ? Chronic.parse(raw_time, :now => @now) : @now
      t += WEEK * interval.to_i until t > @now
      mins, hrs = t.to_a.values_at(1,2)

      log.info 'ChronicCron/expressions/get: r270' if log
      if @debug then
        puts 'ChronicCron#expressions 270'
        puts ('t: ' + t.inspect).debug
      end

      "%s %s * * %s/%s" % [mins, hrs, t.wday, interval]
    end


    # e.g. starting 05-Aug@15:03 every 2 weeks
    get /(.*) every (\d) weeks/ do |raw_date, interval|

      t = Chronic.parse(raw_date, :now => @now)
      mins, hrs = t.to_a.values_at(1,2)
      puts 'ChronicCron#expressions 280' if @debug

      "%s %s * * %s/%s" % [mins, hrs, t.wday, interval]
    end

    # e.g. from 05-Aug@12:34 fortnightly
    get /(.*)\s+(?:biweekly|fortnightly)/ do |raw_date|

      t = Chronic.parse(raw_date, :now => @now)
      mins, hrs, day, month, year = t.to_a.values_at(1,2,3,4,5)
      puts 'ChronicCron#expressions 290' if @debug

      "%s %s %s %s %s/2 %s" % [mins, hrs, day, month, t.wday, year]
    end

    # e.g. from 06-Aug@1pm every week
    get /(.*)\s+(?:weekly|every week)/ do |raw_date|

      t = Chronic.parse(raw_date, :now => @now)
      mins, hrs, day, month, year = t.to_a.values_at(1,2,3,4,5)
      puts 'ChronicCron#expressions 300' if @debug

      "%s %s %s %s %s %s" % [mins, hrs, day, month, t.wday, year]
    end

    # e.g. every sunday
    get /every\s+#{weekday}/ do |wday|

      puts 'ChronicCron#expressions 310' if @debug

      "0 12 * * %s" % wday
    end

    # e.g. 04-Aug@12:34
    get '*' do

      t = Chronic.parse(params[:input], :now => @now)
      puts 'ChronicCron#expressions 330' if @debug
      puts 't: ' + t.inspect if @debug
      if t then
        "%s %s %s %s * %s" % t.to_a.values_at(1,2,3,4,5)
      end
    end

    def in24hrs(raw_hrs, meridiem)

      puts 'raw_hrs: ' + raw_hrs.inspect if @debug

      hrs = if meridiem == 'pm' then
        raw_hrs.to_i < 12 ? raw_hrs.to_i + 12 : raw_hrs.to_i
      else
        raw_hrs.to_i == 12 ? 0 : raw_hrs
      end
    end
  end


  alias find_expression run_route

  private

  def last_wdayofmonth(day, now)

    wday = Date::DAYNAMES.map(&:downcase).index(day)

    d2 = Date.today
    date = Date.civil(now.year, now.month, -1)
    date -= 1 until date.wday == wday

    return date

  end

end
