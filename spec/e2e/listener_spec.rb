require 'spec_helper'

describe "Proxy + WebDriverListener" do
  let(:proxy) { new_proxy }
  let(:listener) { BrowserMob::Proxy::WebDriverListener.new(proxy) }

  let(:driver)  { Selenium::WebDriver.for :firefox, :profile => profile, :listener => listener }
  let(:wait) { Selenium::WebDriver::Wait.new(:timeout => 10) }

  let(:profile) {
    pr = Selenium::WebDriver::Firefox::Profile.new
    pr.proxy = proxy.selenium_proxy

    pr
  }

  after { proxy.close }

  it "should record events" do
    driver.get url_for("1.html")
    wait.until { driver.title == '1' }
    driver.find_element(:link_text => "2").click
    driver.quit

    hars = listener.hars
    hars.size.should == 1

    hars.first.pages.size.should == 2
  end
end