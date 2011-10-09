require 'spec_helper'

describe "Proxy + WebDriver" do
  let(:driver)  { Selenium::WebDriver.for :firefox, :profile => profile }
  let(:proxy) { new_proxy }

  let(:profile) {
    pr = Selenium::WebDriver::Firefox::Profile.new
    pr.proxy = proxy.selenium_proxy

    pr
  }

  after {
    driver.quit
    proxy.close
  }

  it "should fetch a HAR" do
    proxy.new_har("1")
    driver.get url_for("1.html")

    proxy.new_page "2"
    driver.get url_for("2.html")

    har = proxy.har

    har.should be_kind_of(HAR::Archive)
    har.pages.size.should == 2
  end

  it "should set whitelist and blacklist" do
    proxy.whitelist(/example\.com/, 201)
    proxy.blacklist(/bad\.com/, 404)
  end

  it "should set limits" do
    proxy.limit(:downstream_kbps => 100, :upstream_kbps => 100, :latency => 2)
  end

end