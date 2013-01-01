class FlightBrowser
	require 'date'
	require 'json'
	require 'open-uri'
	require 'mechanize'

	# for the cache
	require 'dalli'
	require 'memcachier'

	# set the root path
	RootPath = File.expand_path(File.dirname(__FILE__) + '/..')
	@latlong_source = RootPath + '/latlong.json'
	@cache = Dalli::Client.new

	def cache
		self.class.cache
	end

	def self.cache
		@cache
	end

# Run cache code with or without a working cache
	def safe_cache (&block)
		begin
			return block.call()
		rescue Dalli::RingError
		end
	end

# Return a Mechanize agent for this instance
	def agent
		return @agent if @agent
		a = Mechanize.new
		a.user_agent = 'flightbrowser.mikec.me/0.1';
		@agent = a
	end

# Returns the city code to use in SkyScanner urls
# Does this by submitting the basic form and checking the second url
	def get_code_for_city(city)
		city.downcase!
		key = "code-#{city}"
		if (code = safe_cache { cache.get(key) }) 
				return code
		end
		code = nil
		a = agent
		a.get('http://www.skyscanner.net') do |page|
			res = page.form_with(:name => 'sc_form') do |form|
				form.from=city
			end.submit
			if (m = res.uri.path.match(%r{flights/([^/]+)}))
				code = m[1]
				safe_cache { cache.set(key, code) }
			end
			return code
		end

	end

# Retrieves flight prices and returns an arrayref of places and prices
#
# @param city [String] The starting city
# @param month [String] The month to search in
#
# @return Array<Hash>
	def get_data(city, month)
		city.downcase!
		city.tr!(' ','-')
		month.downcase!
		year = DateTime.now.year
		key = "data-#{city}-#{month}"
		if (data = safe_cache { cache.get(key) })
			return data
		end
		places = []
		code = get_code_for_city(city)
		return [] unless code
		url = "http://www.skyscanner.net/flights-from/#{code}/#{month}-#{year}/#{month}-#{year}/cheapest-flights-from-#{city}-in-#{month}-#{year}.html";
		places = []
		open(url, "User-Agent" => agent.user_agent) do |f|
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
		safe_cache { cache.set(key, places) }
		return places
	end

	def self.latlong
		return @ll_json if @ll_json
		@ll_json = JSON.parse(File.read(@latlong_source))
		return @ll_json
	end

# Inserts location data and colour for each place/price combo. Modifies
# prices in-place.
#
# @param prices Array<Hash>
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
