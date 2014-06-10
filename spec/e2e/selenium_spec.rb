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

  describe 'request interceptor' do
    it "modifies request" do
      proxy.new_har("1", :capture_headers => true)
      proxy.request_interceptor = 'request.getMethod().setHeader("foo", "bar");'

      driver.get url_for("1.html")
      wait.until { driver.title == '1' }

      entry = proxy.har.entries.first
      header = entry.request.headers.find { |h| h['name'] == "foo" }
      header['value'].should == "bar"
    end
  end

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

  it "should fetch a HAR and capture content" do
    proxy.new_har("2", :capture_content => true)

    driver.get url_for("2.html")
    wait.until { driver.title == '2' }

    entry = proxy.har.entries.first
    entry.should_not be_nil

    entry.response.content.size.should be > 0
    entry.response.content.text.should == File.read("spec/fixtures/2.html")
  end

  it "should fetch a HAR and capture binary content as Base64 encoded string" do
    proxy.new_har("binary", :capture_binary_content => true)

    driver.get url_for("empty.gif")

    entry = proxy.har.entries.first
    entry.should_not be_nil

    entry.response.content.size.should be > 0
    require 'base64'
    expected_content = Base64.encode64(File.read("spec/fixtures/empty.gif")).strip
    entry.response.content.text.should == expected_content
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

    it "can be cleared" do
      proxy.new_har('whitelist')
      proxy.whitelist('foo\.bar\.com', 404)

      proxy.clear_whitelist
      driver.get url_for('2.html')
      proxy.har.entries.first.response.status.should_not == 404
    end
  end

  describe 'blacklist' do
    it "disallows access to urls in blacklist" do
      proxy.new_har('blacklist')

      dest = url_for('1.html')
      proxy.blacklist(Regexp.quote(dest), 404)
      driver.get dest

      entry = proxy.har.entries.find { |e| e.request.url == dest }
      entry.should_not be_nil
      entry.response.status.should == 404
    end

    it "allows access to urls outside blacklist" do
      proxy.blacklist('foo\.bar\.com', 404)
      driver.get url_for('2.html')

      wait.until { driver.title == '2' }
    end

    it "can be cleared" do
      proxy.new_har('blacklist')

      dest = url_for('1.html')
      proxy.blacklist(Regexp.quote(dest), 404)

      proxy.clear_blacklist
      driver.get dest

      entry = proxy.har.entries.find { |e| e.request.url == dest }
      entry.should_not be_nil
      entry.response.status.should_not == 404
    end
  end

  describe 'rewrite rules' do

    let(:uri) { URI.parse url_for('1.html') }

    before do
      proxy.rewrite(%r{1\.html}, '2.html')
    end

    it 'fetches the rewritten url' do
      driver.get uri

      wait.until { driver.title == '2' }
    end

    it 'can be cleared' do
      proxy.clear_rewrites
      driver.get uri

      wait.until { driver.title == '1' }
    end

  end

  it 'should set timeouts' do
    proxy.timeouts(read: 0.001)
    driver.get url_for('slow')
    wait.until { driver.title == 'Problem loading page' } # This title appears in Firefox
  end

  it "should set headers" do
    proxy.headers('Content-Type' => "text/html")
  end

  it "should set limits" do
    proxy.limit(:downstream_kbps => 100, :upstream_kbps => 100, :latency => 2)
  end

  it 'should remap given DNS hosts' do
    uri = URI.parse url_for('1.html')
    host = 'plus.google.com'

    proxy.remap_dns_hosts(host => uri.host)
    uri.host = host

    driver.get uri
    wait.until { driver.title == '1' }
  end

end
