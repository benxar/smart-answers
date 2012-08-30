source 'http://rubygems.org'
source 'https://gems.gemfury.com/vo6ZrmjBQu5szyywDszE/'

gem 'gds-warmup-controller'

gem 'unicorn', '4.3.1'
gem 'rails', '~> 3.2.8'
gem 'rails-i18n'
gem 'json'
gem 'plek', '~> 0.1'
gem 'rummageable'
gem 'aws-ses', :require => 'aws/ses' # Needed by exception_notification
gem 'exception_notification'
gem 'lograge'
if ENV['API_DEV']
  gem 'gds-api-adapters', :path => '../gds-api-adapters'
else
  gem 'gds-api-adapters', '0.2.0'
end
gem 'htmlentities', '~> 4'

if ENV['SLIMMER_DEV']
  gem 'slimmer', :path => '../slimmer'
else
  gem 'slimmer', '1.2.4'
end

if ENV['GOVSPEAK_DEV']
  gem 'govspeak', :path => '../govspeak'
else
  gem 'govspeak', '~> 0.8.15'
end

group :test do
  gem 'capybara', '~> 1.1.2'
  gem 'ci_reporter'
  gem 'mocha', :require => false
  gem "shoulda", "~> 2.11.3"
  gem 'webmock', :require => false
  gem "simplecov", "~> 0.6.4", :require => false
  gem "simplecov-rcov", "~> 0.2.3", :require => false
  gem 'capybara-webkit', "~> 0.12.1"
end

group :assets do
  gem "therubyracer", "~> 0.9.4"
  gem 'uglifier'
end

if ENV['RUBY_DEBUG']
  gem 'ruby-debug19'
end

group :analytics do
  gem "google-api-client", :require => 'google/api_client'
end
