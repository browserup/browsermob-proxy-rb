require 'spec_helper'

describe "Proxy + WebDriver" do
  let(:driver)  { Selenium::WebDriver.for :firefox, :profile => profile }
  let(:proxy) { new_proxy }
  let(:wait) { Selenium::WebDriver::Wait.new(:timeout => 10) }

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
    wait.until { driver.title == '1' }

    proxy.new_page "2"
    driver.get url_for("2.html")
    wait.until { driver.title == '2' }

    har = proxy.har

    har.should be_kind_of(HAR::Archive)
    har.pages.size.should == 2
  end

  it "should fetch a HAR and capture headers" do
    proxy.new_har("2", :capture_headers => true)

    driver.get url_for("2.html")
    wait.until { driver.title == '2' }

    entry = proxy.har.entries.first
    entry.should_not be_nil

    entry.request.headers.should_not be_empty
  end

  describe 'whitelist' do
    it "allows access to urls in whitelist" do
      dest = url_for('1.html')

      proxy.whitelist(Regexp.quote(dest), 404)
      driver.get dest
      wait.until { driver.title == '1' }
    end

    it "disallows access to urls outside whitelist" do
      proxy.new_har('whitelist')
      proxy.whitelist('foo\.bar\.com', 404)
      driver.get url_for('2.html')
      proxy.har.entries.first.response.status.should == 404
    end
  end

  describe 'blacklist' do
    it "disallows access to urls in blacklist" do
      proxy.new_har('blacklist')

      dest = url_for('1.html')
      proxy.blacklist(Regexp.quote(dest), 404)
      driver.get dest

      proxy.har.entries.first.response.status.should == 404
    end

    it "allows access to urls outside blacklist" do
      proxy.blacklist('foo\.bar\.com', 404)
      driver.get url_for('2.html')

      wait.until { driver.title == '2' }
    end
  end

  it "should set headers" do
    proxy.headers('Content-Type' => "text/html")
  end

  it "should set limits" do
    proxy.limit(:downstream_kbps => 100, :upstream_kbps => 100, :latency => 2)
  end

  it 'should remap given DNS hosts' do
    proxy.remap_dns_hosts('plus.google.com' => '127.0.0.2')
    uri = URI(url_for('1.html'))
    uri.host = 'plus.google.com'
    driver.get uri
    wait.until { driver.title == '1' }
  end

end
