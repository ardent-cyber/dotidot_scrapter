class ScraperController < ApplicationController
  require 'selenium-webdriver'
  require 'nokogiri'

  def data
    json = params.to_unsafe_h

    url = json['url']
    fields = json['fields']

    if url.blank? || fields.blank? || !fields.is_a?(Hash)
      return render json: { error: 'Invalid input' }, status: :bad_request
    end

    # Set up Selenium using headless Chrome
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless=new')
    options.add_argument('--disable-gpu')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('--disable-blink-features=AutomationControlled') # less detectable as bot
    options.add_argument('--window-size=1280,800')
    options.add_argument('--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36')

    driver = Selenium::WebDriver.for :chrome, options: options

    begin
      driver.navigate.to(url)
      sleep 2 # wait for JS to run, tweak as needed

      # Parse the page with Nokogiri
      doc = Nokogiri::HTML(driver.page_source)

      result = {}
      fields.each do |field, selector|
        el = doc.at_css(selector)
        result[field] = el ? el.text.strip : nil
      end

      render json: result
    rescue => e
      render json: { error: "Server error: #{e.message}" }, status: 500
    ensure
      driver.quit if driver
    end
  end
end