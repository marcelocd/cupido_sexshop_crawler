class Product 
	attr_accessor :name, :cash_price, :credit_card_price, :category, :description, :images

	@name
	@weight
	@cash_price
	@credit_card_price
	@category
	@description
	@images

	def initialize category
		@category = category
		@images = []
	end

	def to_json
		return product_json = {
			name: @name,
			cash_price: @cash_price,
			credit_card_price: @credit_card_price,
			category: @category,
			description: @description
		}
	end

	def to_s
		aux_string = "Nome: #{@name}"
		aux_string += "\nPreço à vista: #{@cash_price}"
		aux_string += "\nPreço no crédito: #{@credit_card_price}"
		aux_string += "\nCategoria: #{@category}"
		aux_string += "\nDescrição: #{@description}\n"
	end

	def print_info
		puts '-' * 99
		puts self.to_s
		puts '-' * 99
	end
end