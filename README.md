# cupido_sexshop_crawler
This crawler accesses the following sexshop web page and downloads its products images and main informations:
https://www.cupidodistribuidora.com.br/index.html

The instructions bellow assume you're using Debian/Ubuntu.

Instructions:

  1) Create a folder called "products" (or any other name, it doesn't matter)
  2) Inside the folder you've just created, create another folder called "cupido_sexshop_crawler"
     (or any other name, it doesn't matter also)
  3) Download the following files from https://github.com/marcelocd/cupido_sexshop_crawler:
     - product.rb
     - scrape_products.rb
  4) Open your terminal in the folder you've created in step 2 and install the ruby compiler with these commands:

sudo apt-get install ruby-full

  5) Install the mechanize gem with these commands:

gem install mechanize
  
  6) Install the nokogiri gem with these commands:

sudo apt-get install build-essential patch ruby-dev zlib1g-dev liblzma-dev

gem install nokogiri

  7) Install the byebug gem with these commands:

gem install byebug

  8) Install the i18n gem with these commands:

gem install i18n

  9) Finally, to execute the crawler, run these commands:

ruby scrape_products.rb

  and... DONE!

It'll take a while. ;-)
  
  
  
  


