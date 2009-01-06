#!/usr/bin/ruby

require 'drb'
require 'thread'
require 'rubygems'
require 'icalendar'
require 'lib/yaml'

unless File.exists?(File.config_path("config"))
	puts "Please run `rake setup' before running this!"
end

def load_cals
	@events = []
	@events.extend DRb::DRbUndumped

	Dir[File.join(File.config_path("calendars"), '*')].each do |calfile|
		Icalendar.parse(File.read(calfile)).each do |cal|
			cal.events.each do |event|
				@events << event
			end
		end
	end
	puts "Loaded calendars"
	today = Date.today
	@events = @events.map{|event| event.dtend.day if event.dtend and event.dtend.month == today.month }.select {|days| not days.nil? }.sort.uniq
end
# Run it on start
load_cals()
# Spawn a watcher thread that updates @events every 10 secs only if the calendars
# have themselves been changed first.
cal_thread = Thread.new do
	@last_updated = File.mtime(File.config_path("calendars"))
	while true
		sleep 10 # 10 secs
		if File.mtime(File.config_path("calendars")) > @last_updated
			load_cals()
			@last_updated = File.mtime(File.config_path("calendars"))
			DRb.to_id @events
		end
	end

end

DRb.start_service nil, @events

druby = File.join(File.config_path("config"), "druby")

f = File.open(druby, "w+")
f.puts(DRb.uri.to_s)
f.close

trap :INT, proc {
	puts "Killing DRb server..."
	DRb.thread.kill
	cal_thread.kill
	puts "Cheeiro!"
}
DRb.thread.join

File.unlink druby
