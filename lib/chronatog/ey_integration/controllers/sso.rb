require 'chronatog/ey_integration/controllers/base'

module Chronatog
  module EyIntegration
    module Controller
      class SSO < Base
        set :views, File.expand_path('../../views', __FILE__)

        #############################
        # EY facing SSO/Customer UI #
        #############################

        use Rack::Session::Cookie, :secret => [rand.to_s].pack("m")

#{sso_before_filter{
        before do
          if session["ey_user_name"]
            #already logged in
          elsif EY::ApiHMAC::SSO.authenticated?(request.url,
                                                Chronatog::EyIntegration.api_creds.auth_id,
                                                Chronatog::EyIntegration.api_creds.auth_key)
          then
            session["ey_return_to_url"] = params[:ey_return_to_url]
            session["ey_user_name"] = params[:ey_user_name]
          else
            halt 401, "SSO authentication failed. <a href='#{params[:ey_return_to_url]}'>Go back</a>."
          end
        end
#}sso_before_filter}

        get "/customers/logout" do
          url = session["ey_return_to_url"]
          session.clear
          redirect url
        end

        get "/customers/:customer_id" do |customer_id|
          @customer = Chronatog::Server::Customer.find(customer_id)
          @redirect_to = params[:ey_return_to_url]
          haml :customer_view
        end
        
        post "/customers/:customer_id/change_plan" do |customer_id|
          @customer = Chronatog::Server::Customer.find(customer_id)
          @customer.update_attributes!(:plan_type => params["plan_type"])
          haml :customer_view
        end

        get "/customers/:customer_id/schedulers/:scheduler_id" do |customer_id, scheduler_id|
          @customer = Chronatog::Server::Customer.find(customer_id)
          @redirect_to = params[:ey_return_to_url]
          "TODO: you have SSO'd in to customer #{@customer.inspect} for scheduler_id"
        end

      end
    end
  end
end
