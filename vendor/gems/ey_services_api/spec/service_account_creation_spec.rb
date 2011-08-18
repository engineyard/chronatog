require 'spec_helper'
require 'sinatra'

describe EY::ServicesAPI::ServiceAccountCreation do
  include_context 'tresfiestas setup'

  describe "with a service account" do
    before do
      @service_account_hash = @tresfiestas.create_service_account
      @creation_request = @tresfiestas.service_account_creation_request(@service_account_hash)
      @service_account = EY::ServicesAPI::ServiceAccountCreation.from_request(@creation_request.to_json)
    end

    it "can handle a service account creation request" do
      @service_account.url.should eq @creation_request[:url]
      @service_account.messages_url.should eq @creation_request[:messages_url]
      @service_account.invoices_url.should eq @creation_request[:invoices_url]
      @service_account.name.should eq @creation_request[:name]
    end

    it "can produce a response body hash for service account creation requests" do
      response_hash = @service_account.creation_response_hash do |presenter|
        presenter.provisioned_services_url = "some provision url"
        presenter.url = "some resource url"
        presenter.configuration_required = true
        presenter.configuration_url = "some config url" #doesn't even have to be valid here!
        presenter.message = EY::ServicesAPI::Message.new(:message_type => "status", :subject => "some messages")
      end

      service_account_response = response_hash[:service_account]
      service_account_response[:configuration_required].should be true
      service_account_response[:configuration_url].should eq "some config url"
      service_account_response[:provisioned_services_url].should eq "some provision url"
      service_account_response[:url].should eq "some resource url"
      response_hash[:message].should eq({:message_type => 'status', :subject => "some messages", :body => nil})
    end
  end

end