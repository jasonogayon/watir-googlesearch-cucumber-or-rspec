require 'rspec'
require 'page-object'
require 'fig_newton'
require 'require_all'
require 'parallel_tests'
require 'selenium-webdriver'
require 'watir'
require 'rest-client'
require 'nokogiri'
require 'open-uri'
require 'net/http'
require 'uri'
require 'webdriver-user-agent'
require 'date'
require 'gmail'
require 'csv'



def browser
  (ENV['BROWSER'] ||= 'chrome').downcase.to_sym
end

def environment
  (ENV['ENV'] ||= 'local').downcase.to_sym
end

def mobile
  (ENV['MOBILE'] ||= 'false').downcase.to_sym
end

def mac
  (ENV['MAC'] ||= 'false').downcase.to_sym
end

def do_assertion
  (ENV['ASSERT'] ||= 'true').downcase.to_sym
end



# Add chromedriver.exe directory to
BROWSERS_DIRECTORY = File.absolute_path('../..', File.dirname(__FILE__))
chromedriver_path = File.join(BROWSERS_DIRECTORY,"browsers","chromedriver") if mac == :true
chromedriver_path ||= File.join(BROWSERS_DIRECTORY,"browsers","chromedriver.exe")
geckodriver_path = File.join(BROWSERS_DIRECTORY,"browsers","geckodriver.exe")

# Add SSL certificate file to the path
ENV['SSL_CERT_FILE'] = "#{File.expand_path(File.dirname(__FILE__))}/cacert.pem"

# Set browser capabilities
if environment == :local
    capabilities = Selenium::WebDriver.for :firefox, driver_path: geckodriver_path if browser == :firefox
    capabilities = Webdriver::UserAgent.driver(:browser => browser, :agent => :iphone, :orientation => :portrait, :driver_path => chromedriver_path) if mobile == :true
else
    arguments = "--ignore-certificate-errors --disable-popup-blocking --disable-translate --disable-web-security"
    capabilities = Selenium::WebDriver::Remote::Capabilities.firefox :profile => 'default', driver_path: geckodriver_path if browser == :firefox
    capabilities ||= Selenium::WebDriver::Remote::Capabilities.chrome :chromeOptions => { :args => [ arguments ]}, driver_path: chromedriver_path
end

# Start browser on a desired environment
unless browser == :none
    unless environment == :local
        case environment
            when :webdriver1 then remote_ip = "10.1.2.140"
        end
        browser = Watir::Browser.new :remote, :url => "http://#{remote_ip}:5555/wd/hub", :desired_capabilities => capabilities
    end
    browser = Watir::Browser.new :chrome, driver_path: chromedriver_path if environment == :local && mobile == :false
    browser ||= Watir::Browser.new capabilities
end



RSpec.configure do |config|

    config.include PageObject::PageFactory

    # Terminal Display
    config.color = true
    config.tty = true
    config.formatter = :documentation

    # Always  Run Focused Tests
    config.filter_run focus: true
    config.run_all_when_everything_filtered = 

    config.before(:all, :chrome => true) do
    end

    # Run Before Test
    config.before do
        begin
            tries ||= 3
            unless browser == :none
                @browser = browser
                @browser.driver.manage.window.maximize
                @browser.cookies.clear
            end
        rescue
            retry unless (tries -= 1).zero?
        end
    end

    # Run After Test
    config.after do
        @browser.close unless @browser.nil?
    end

end