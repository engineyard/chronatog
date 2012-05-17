module Chronatog
  module EyIntegration
    class Schema
      def self.setup!
        conn = Chronatog::Server::Model.connection
        unless conn.table_exists?(:schema_v2)

          conn.create_table "schema_v2", :force => true do |t|
          end

          conn.add_column "customers", "api_url",        :string
          conn.add_column "customers", "messages_url",   :string
          conn.add_column "customers", "invoices_url",   :string
          conn.add_column "customers", "plan_type",      :string
          conn.add_column "customers", "last_billed_at", :datetime

          conn.add_column "schedulers", "api_url",        :string
          conn.add_column "schedulers", "environment_name", :string
          conn.add_column "schedulers", "app_name",         :string
          conn.add_column "schedulers", "messages_url",     :string
          conn.add_column "schedulers", "decomissioned_at", :datetime
          conn.add_column "schedulers", "usage_calls",      :integer

        end
        unless conn.table_exists?(:schema_v3)
          conn.create_table "schema_v3", :force => true do |t|
          end

          conn.create_table "ey_credentials", :force => true do |t|
            t.string   "auth_id"
            t.string   "auth_key"
            t.datetime "created_at"
            t.datetime "updated_at"
          end

          conn.create_table "ey_services", :force => true do |t|
            t.string   "url"
            t.datetime "created_at"
            t.datetime "updated_at"
          end
        end
      end
    end
  end
end