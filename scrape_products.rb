# Author: Marcelo Dias
# Last modified: 23/06/2020

# REQUIREMENTS -----------------------------------
load    "product.rb"
require "mechanize.rb"
require "nokogiri.rb"
require "byebug"
require "i18n"

# ------------------------------------------------

# PROBLEM SOLVING FUNCTIONS ----------------------
def adjust_images_partial_urls images_partial_urls
	total_number_of_images = images_partial_urls.size

	for i in 0..(total_number_of_images - 1)
		images_partial_urls[i].gsub!(/width=640/, "width=1280")
		images_partial_urls[i].gsub!(/height=480/, "height=960")
	end
end

def format_text name
	return I18n.transliterate(name).gsub(/[\-\(\)\'\/\\\?\!\@\#\$\%\&]/, '').gsub(/\s+/, ' ').gsub(' ', '_').downcase
end

def get_categories_urls initial_page
	images_partial_urls = initial_page.body.scan(/\/categoria[^\"]+/).uniq

	total_categories_number = images_partial_urls.size

	categories_urls = []

	for i in 0..(total_categories_number - 1)
		categories_urls << base_url() + images_partial_urls[i]
	end

	return categories_urls, total_categories_number
end

def there_are_still_more_pages flag, current_page_number
	if flag == nil
		return false
	end

	return true
end

def theres_a_product text
	if text == 'Visualização rápida'
		return true
	end

	return false
end

# ------------------------------------------------

# SAVING FUNCTIONS -------------------------------
def download_image(url, path)
  image = @ag.get(url).body

  file = File.open(path, "w") { |f| f << image }

  file.close()

  return image
end

def save_page page, path
	file = File.new(path, 'w')
	file.puts page.body.unpack('C*').pack('U*')
	file.close
end

def save_file path, content
	file = File.open(path, "w") { |f| f << content }

	file.close()
end

# ------------------------------------------------

# URL FUNCTIONS ----------------------------------
def base_url
	return 'https://www.cupidodistribuidora.com.br'
end

# ------------------------------------------------

# PATH FUNCTIONS ---------------------------------
def file_path file_name
	return `pwd`.chomp + '/../cupido/' + file_name
end

# ------------------------------------------------

# PRINTING FUNCTIONS -----------------------------
def log message
	puts '-' * 99
	puts message
	puts '-' * 99
end

def print_page_number page_number
	log "PÁGINA #{page_number}"
end

# ------------------------------------------------

# SETTINGS ---------------------------------------
# Requeried by the transliterate method 
# (which excludes the accents of a given word)
I18n.config.available_locales = :en

# ------------------------------------------------

@ag = Mechanize.new()

# Makes a directory (cupido_sexshop_crawler's sibling) called "cupido"
system('mkdir -p ../cupido')

initial_page_url = base_url() + '/index.html'

log 'REQUISITANDO PÁGINA INICIAL'
initial_page = @ag.get(initial_page_url)
log 'PRONTO'

# Gets the urls for all categories
categories_urls, total_categories_number = get_categories_urls(initial_page)

for i in 0..(total_categories_number - 1)
	# Gets the current category name
	category = categories_urls[i].match(/categoria,\d+,([^\.]+)/)[1].gsub(/-/, ' ')

	log "CATEGORIA #{category.upcase} (#{(i + 1).to_s} de #{total_categories_number})"

	# Makes a directory with the formatted current category name
	system("mkdir -p ../cupido/#{format_text(category)}")

	# Accesses the current category page
	category_page = @ag.get(categories_urls[i])

	current_page_number = 1

	loop do
		print_page_number(current_page_number)

		# Gets the total number of links in the current category page
		number_of_links = category_page.links.size

		for j in 0..(number_of_links - 1)
			# Checks if the current link in the current category is associated with an existing product
			if theres_a_product(category_page.links[j].text)
				product = Product.new(category)

				product.name = category_page.links[j - 1].text

				# Creates a folder for the current product
				system("mkdir -p ../cupido/#{format_text(product.category)}/#{format_text(product.name)}")

				# This product id is necessary only for composing its respective url.
				product_id = category_page.links[j - 1].attributes.attributes.first.last.text.match('\d+')[0]

				product_partial_url = category_page.body.match("/produto\,#{product_id}\,[^\"]+")[0]
				
				product_url = base_url() + product_partial_url
			
				product_page = @ag.get(product_url)

				# Here we put the partial url of each image of the current product in an array. But,
				# to download the larger picture, we need to adjust the url's width and height values.
				images_partial_urls = product_page.body.scan(/\/uploads\/#{product_id}[^\?]+\?width=640&height=480&scale=both/).uniq

				adjust_images_partial_urls(images_partial_urls)

				total_number_of_images = images_partial_urls.size

				# If the current product has only one image, call it "image.jpg".
				# Else, if it has more than one image, call'em "image1.jpg", "image2.jpg",
				# and so forth.
				if total_number_of_images == 1
					image_path = file_path("#{format_text(product.category)}/#{format_text(product.name)}/imagem.jpg")

					image_url = base_url() + images_partial_urls.first

					product.images << download_image(image_url, image_path)
				elsif total_number_of_images > 1
					for k in 0..(total_number_of_images - 1)
						image_path = file_path("#{format_text(product.category)}/#{format_text(product.name)}/imagem#{(k + 1).to_s}.jpg")

					 	image_url = base_url() + images_partial_urls[k]

					 	product.images << download_image(image_url, image_path)
					end
				end

				#save_page(product_page, file_path('page.html'))

				# Here we're using Nokogiri for text formatting purposes.
				product_page = Nokogiri::HTML(product_page.body, nil, Encoding::UTF_8.to_s)

				product.cash_price = product_page.text.match(/(R\$ \d+\,\d{2}) à vista/)[1].gsub(/,/, '.').gsub(/\s+/, '')

				product.credit_card_price = product_page.text.match(/(R\$ \d+,\d{2}) nos cartões de crédito/)[1].gsub(/,/, '.').gsub(/\s+/, '')

				product.description = product_page.css("#desc").text.strip

				# For some reason, sometimes the pop-up window does not show the product description.
				# So, when this happens, we need to access the actual product page.
				if product.description.empty?
					product_url = base_url() + category_page.links[j - 1].attributes.first.last

					product_page = @ag.get(product_url)

					product_page = Nokogiri::HTML(product_page.body, nil, Encoding::UTF_8.to_s)

					product.description = product_page.css("#desc").text.strip
				end

				# Concatenates a specific warning information to the product's
				# description in case its images are merely illustrative.
				if aux = product_page.to_s.match('Atenção: Imagens meramente ilustrativas, o produto pode divergir da imagem apresentada')
					product.description += ("\n" + aux[0])
				end

				product.print_info()

				product_info_path = file_path("#{format_text(product.category)}/#{format_text(product.name)}/info.txt")

				system("rm -f #{product_info_path}")

				save_file(product_info_path, product.to_s)

				product_json_path = file_path("#{format_text(product.category)}/#{format_text(product.name)}/info.json")

				system("rm -f #{product_json_path}")

				save_file(product_json_path, product.to_json)
			end
		end

		aux = category_page.body.match(/\/categoria[^\?]+\?pagina=#{(current_page_number + 1).to_s}/)

		if !there_are_still_more_pages(aux, current_page_number)
			break
		end

		next_category_page_url = base_url() + aux[0]

		category_page = @ag.get(next_category_page_url)

		current_page_number += 1
	end
end
