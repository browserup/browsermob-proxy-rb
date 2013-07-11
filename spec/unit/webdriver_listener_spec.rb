require 'spec_helper'

module BrowserMob
  module Proxy

    describe WebDriverListener do
      let(:client)   { double(Client) }
      let(:driver)   { double(Selenium::WebDriver::Driver, :current_url => 'http://foo') }
      let(:listener) { WebDriverListener.new(client) }
      let(:element)  { double(Selenium::WebDriver::Element, :ref => "some-id")}
      let(:har)      { double(HAR::Archive) }
      let(:url)      { "http://example.com" }

      it 'creates a new har on navigate.to' do
        client.should_receive(:new_har).with("navigate-to-http://example.com", {})
        client.should_receive(:har).and_return(:har)

        listener.before_navigate_to(url, driver)
        listener.before_quit(driver)
        listener.hars.size.should == 1
      end

      it 'creates a new page on navigate.back' do
        client.should_receive(:new_page).with(/^navigate-back/)

        listener.before_navigate_back(driver)
      end

      it 'creates a new page on navigate.forward' do
        client.should_receive(:new_page).with(/^navigate-forward/)

        listener.before_navigate_forward(driver)
      end

      it 'creates a new page on click' do
        client.should_receive(:new_page).with(/^click-element/)

        listener.before_click(element, driver)
      end

      it 'saves har before quit' do
        client.should_receive(:har).and_return(har)

        listener.before_quit(driver)
        listener.hars.size.should == 1
      end

      it 'passes the :capture_headers option' do
        listener = WebDriverListener.new(client, :capture_headers => true)
        client.should_receive(:new_har).with("navigate-to-http://example.com", :capture_headers => true)

        listener.before_navigate_to(url, driver)
      end
    end
  end
end
