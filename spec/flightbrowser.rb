require 'rspec'
require 'flightbrowser'

describe FlightBrowser do
	it "can get flight data" do
		fb = FlightBrowser.new
		data = fb.get_data('Manchester', 'April')
		data[0].keys.should include(:name, :price, :url)
	end

	it "can get latlong json", :quick => true do
		FlightBrowser.latlong.keys.should include('Albania')
	end

	it "can add latlong to prices", :quick => true do
		fb = FlightBrowser.new
		prices = [
			{
				name: 'Sweden',
				price: 500,
			}
		]
		fb.add_latlong_to_prices(prices)
		prices[0].should include(:rgb => 'ff0000', :lat => 62, :long => 15)
	end

	it "can get the code for london", :quick => true do
		fb = FlightBrowser.new
		code = fb.get_code_for_city("London")
		code.should == 'lond'
	end
end
