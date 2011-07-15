require 'spec_helper'

module BrowserMob
  module Proxy

    describe Client do
      let(:resource)      { mock(RestClient::Resource) }
      let(:client)        { Client.new(resource, "localhost", 9091) }
      let(:har_resource)  { mock("resource[har]") }
      let(:page_ref_resource)  { mock("resource[har/pageRef]") }

      before do
        resource.stub!(:[]).with("har").and_return(har_resource)
        resource.stub!(:[]).with("har/pageRef").and_return(page_ref_resource)
      end

      it "creates a new har" do
        har_resource.should_receive(:put).with(:initialPageRef => "foo").and_return('')

        client.new_har("foo").should be_nil
      end

      it "returns the previous archive if one exists" do
        har_resource.should_receive(:put).with(:initialPageRef => "foo").and_return(fixture("google.har"))

        client.new_har("foo").should be_kind_of(HAR::Archive)
      end

      it "gets the current har" do
        har_resource.should_receive(:get).and_return(fixture("google.har"))

        client.har.should be_kind_of(HAR::Archive)
      end
      
      it "creates a new page" do
        page_ref_resource.should_receive(:put).with :pageRef => "foo"
        
        client.new_page("foo")
      end
    end

  end
end