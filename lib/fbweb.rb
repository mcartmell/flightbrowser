require 'date'
require 'json'
require 'sinatra/base'
require 'flightbrowser'

# The web app.
class FlightBrowserWeb < Sinatra::Base

	set :reload_templates, false
	set :show_exceptions, false
	set :static, true
	set :root, FlightBrowser::RootPath
	
	get '/ajax/:city/:month' do |city, month|
		return get_data(city, month)
	end

	def get_data(city, month)
		fb = FlightBrowser.new
		return fb.get_data(city, month).to_json
	end

	get '/' do
		fb = FlightBrowser.new
		dt = DateTime.now
		month = dt.strftime("%B")
		months = %w{January February March April May June July August September October November December}
		months.drop_while {|e| e != month}
		erb :index, :locals => { :json => get_data('Manchester', month), :months => months }
	end
end
