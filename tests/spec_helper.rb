# frozen_string_literal: true

require 'capybara'
require 'capybara/rspec'
require 'selenium-webdriver'
require 'rspec'

require_relative 'cappuccino_helper'

CHROME_HOSTNAME = ENV.fetch('CHROME_HOSTNAME')
TEST_HOST       = ENV.fetch('TEST_HOST')
TEST_PORT       = ENV.fetch('TEST_PORT', '4444')

Capybara.register_driver(:remote_chrome) do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-notifications')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--window-size=1280,800')

  Capybara::Selenium::Driver.new(
    app,
    browser: :remote,
    url:     "http://#{CHROME_HOSTNAME}:4444/wd/hub",
    options: options
  )
end

Capybara.default_driver    = :remote_chrome
Capybara.javascript_driver = :remote_chrome
Capybara.app_host          = "http://#{TEST_HOST}:#{TEST_PORT}"
Capybara.run_server        = false
Capybara.default_max_wait_time = 15

RSpec.configure do |config|
  config.include CappuccinoHelper
  config.include Capybara::DSL

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed
end
