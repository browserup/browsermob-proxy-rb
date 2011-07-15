require 'spec_helper'

describe "Proxy + WebDriver" do
  let(:driver)  { Selenium::WebDriver.for :firefox, :profile => profile }
  let(:proxy) { BrowserMob::Proxy.create("http://localhost:8080") }
  let(:profile) {
    pr = Selenium::WebDriver::Firefox::Profile.new
    pr.proxy = proxy.selenium_proxy

    pr
  }

  after { driver.quit }
  after { proxy.close }

  it "should fetch a HAR" do
    proxy.new_har "google.com"
    driver.get "http://google.com"

    har = proxy.har

    har.should be_kind_of(HAR::Archive)
    har.pages.size.should == 1
  end
end