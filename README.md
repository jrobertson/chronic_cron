# Introducing the chronic_cron gem

This gem which is under development aims to facilitate plain english for cron times. 

e.g.

    require 'chronic_cron'

    Time.now          #=> 2013-07-07 18:35:49 +0100
    cc = ChronicCron.new('Fire at 10:15am every day')
    cc.to_time        #=> 2013-07-08 10:15:00 +0100

    cc.to_expression  #=> => "15 10 * * *"
    cc.next           #=> 2013-07-09 10:15:00 +0100
    cc.to_time        #=> 2013-07-09 10:15:00 +0100

    cc = ChronicCron.new 'at 11:00 and 16:00 on every day'
    cc.to_time        #=> 2013-07-08 11:00:00 +0100
    cc.to_expression  #=> "00 11,16 * * *"

chronic_cron gem cron time expression
