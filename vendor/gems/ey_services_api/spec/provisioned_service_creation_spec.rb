require 'spec_helper'
require 'sinatra'

describe EY::ServicesAPI::ProvisionedServiceCreation do
  include_context 'tresfiestas setup'

  describe "with a service account" do
    before do
      @service_account_hash = @tresfiestas.create_service_account
      @creation_request = @tresfiestas.provisioned_service_creation_request(@service_account_hash)
      @provisioned_service = EY::ServicesAPI::ProvisionedServiceCreation.from_request(@creation_request.to_json)
    end

    it "can handle a provisioned service creation request" do
      @provisioned_service.url.should eq @creation_request[:url]
      @provisioned_service.messages_url.should eq @creation_request[:messages_url]
      @provisioned_service.environment.id.should eq @creation_request[:environment][:id]
      @provisioned_service.environment.name.should eq @creation_request[:environment][:name]
      @provisioned_service.environment.framework_env.should eq @creation_request[:environment][:framework_env]
      @provisioned_service.app.id.should eq @creation_request[:app][:id]
      @provisioned_service.app.name.should eq @creation_request[:app][:name]
    end

    it "can produce a response body hash for provisioned service creation requests" do
      response_hash = @provisioned_service.creation_response_hash do |presenter|
        # presenter.provisioned_services_url = "some provision url"
        presenter.url = "some resource url"
        presenter.vars = {"SOME_ENV_VAR" => "value", "OTHER_VAR" => "blah"}
        presenter.configuration_required = true
        presenter.configuration_url = "some config url" #doesn't even have to be valid here!
        presenter.message = EY::ServicesAPI::Message.new(:message_type => "status", :subject => "some messages")
      end
    
      provisioned_service_response = response_hash[:provisioned_service]
      provisioned_service_response[:configuration_required].should be true
      provisioned_service_response[:configuration_url].should eq "some config url"
      provisioned_service_response[:vars].should eq({"SOME_ENV_VAR" => "value", "OTHER_VAR" => "blah"})
      provisioned_service_response[:url].should eq "some resource url"
      response_hash[:message].should eq({:message_type => 'status', :subject => "some messages", :body => nil})
    end
  end

end