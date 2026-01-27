source 'https://rubygems.org'
gem 'rails', '8.1.2'

require 'erb'
require 'uri'
require 'yaml'

# DB
gem 'sqlite3', '< 3.0'

group :mysql do
  gem 'mysql2'
end

group :postgres do
  gem 'pg'
end

gem 'addressable', require: 'addressable/uri'
gem 'feedjira'
gem 'feed_searcher', git: 'https://github.com/fastladder/feed_searcher'
gem 'jbuilder', '~> 2.13'
gem 'mini_magick'
gem 'nokogiri'
gem 'opml', git: 'https://github.com/ssig33/opml'

group :test do
  gem 'capybara'
  gem "minitest-rails", "~> 8.0"
  gem 'minitest-retry'
  gem 'selenium-webdriver'
  gem 'webmock'
end

group :development, :test do
  gem 'brakeman', require: false
  gem 'bullet'
  gem 'bundler-audit', require: false
  gem 'rubocop', require: false
  gem 'rubocop-capybara', require: false
  gem 'rubocop-minitest', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
end

gem "rails-controller-testing", "~> 1.0"

gem "puma", "~> 7.1"

gem "settings_cabinet", "~> 1.1.0"

gem "nkf", "~> 0.2.0"

gem "http", "~> 5.3"

gem "propshaft", "~> 1.3.1"

# Hotwire (Turbo + Stimulus)
gem "importmap-rails", "~> 2.1"
gem "stimulus-rails", "~> 1.3"
gem "turbo-rails", "~> 2.0"

gem "ostruct", "~> 0.6.3"

gem "stringio", "3.2.0"
