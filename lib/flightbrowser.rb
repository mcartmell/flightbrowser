class FlightBrowser
	require 'date'
	require 'json'
	require 'open-uri'
	require 'dalli'
	require 'memcachier'

	RootPath = File.expand_path(File.dirname(__FILE__) + '/..')
	@latlong_source = RootPath + '/latlong.json'
	begin
	rescue
		@cache = Dalli::Client.new
	end

	def cache
		self.class.cache
	end

	def self.cache
		@cache
	end

	def get_data(city, month)
		city.downcase!
		month.downcase!
		year = DateTime.now.year
		key = "data-#{city}-#{month}"
		if (cache && data = cache.get(key))
			return data
		end
		places = []
		url = "http://www.skyscanner.net/flights-from/man/#{month}-#{year}/#{month}-#{year}/cheapest-flights-from-#{city}-in-#{month}-#{year}.html";
		places = []
		open(url) do |f|
			str = f.read
			str.match(%r#SS\.data\.browse =.*?results:\s+(\[[^\]]+\])#m) do |json|
				hash = JSON.parse(%Q{{"results": #{json[1]}}})
				hash['results'].each do |row|
					places.push({
						name: row['placeName'],
						price: row['price'],
						url: row['url']
					})
				end
			end
		end
		add_latlong_to_prices(places)
		cache.set(key, places) if cache
		return places
	end

	def self.latlong
		return @ll_json if @ll_json
		@ll_json = JSON.parse(File.read(@latlong_source))
		return @ll_json
	end

	def add_latlong_to_prices(prices)
		ll = self.class.latlong
		prices.select! {|e| e[:price] && e[:price] < 1000}
		max_price = prices.map {|e| e[:price]}.max
		prices.each do |price|
			country = price[:name]
			next unless ll.has_key?(country)
			lat = ll[country]['lat']
			long = ll[country]['long']
			price[:lat] = lat.to_f
			price[:long] = long.to_f
			price_pct = price[:price] / max_price.to_f
			red = (price_pct * 255).round
			green = 255 - red
			price[:rgb] = sprintf("%02x%02x%02x", red, green, 0)
		end
	end
end
