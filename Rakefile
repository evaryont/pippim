task :setup do
	require 'lib/yaml'
	unless File.exists? File.config_path("config")
		Dir.mkdir File.config_path("config")
	end
	cp "event.template", File.config_path("template")
	cp_r "calendars", File.config_path("calendars")
end
