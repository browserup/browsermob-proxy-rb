require 'spec_helper'

module BrowserMob
  module Proxy

    describe Client do
      let(:resource)      { mock(RestClient::Resource) }
      let(:client)        { Client.new(resource, "localhost", 9091) }

      before do
        {
          "har"           => mock("resource[har]"),
          "har/pageRef"   => mock("resource[har/pageRef]"),
          "har/whitelist" => mock("resource[har/whitelist]"),
          "har/blacklist" => mock("resource[har/blacklist]")
        }.each do |path, mock|
          resource.stub!(:[]).with(path).and_return(mock)
        end
      end

      it "creates a new har" do
        resource['har'].should_receive(:put).
                        with(:initialPageRef => "foo").
                        and_return('')

        client.new_har("foo").should be_nil
      end

      it "returns the previous archive if one exists" do
        resource['har'].should_receive(:put).
                        with(:initialPageRef => "foo").
                        and_return(fixture("google.har"))

        client.new_har("foo").should be_kind_of(HAR::Archive)
      end

      it "gets the current har" do
        resource['har'].should_receive(:get).
                        and_return(fixture("google.har"))

        client.har.should be_kind_of(HAR::Archive)
      end

      it "creates a new page" do
        resource['har/pageRef'].should_receive(:put).
                                with :pageRef => "foo"

        client.new_page "foo"
      end

      it "sets the blacklist" do
        resource['har/blacklist'].should_receive(:put).
                                  with(:regex => "http://example.com", :status => 401)

        client.blacklist(%r[http://example.com], 401)
      end

      it "sets the whitelist" do
        resource['har/whitelist'].should_receive(:put).
                                  with(:regex => "http://example.com", :status => 401)

        client.whitelist(%r[http://example.com], 401)
      end
    end

  end
end