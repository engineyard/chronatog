module Chronos
  module EyIntegration
    class Schema
      def self.setup!
        conn = Chronos::Server::Model.connection
        unless conn.table_exists?(:creds)

          conn.create_table "creds", :force => true do |t|
            t.string   "auth_id"
            t.string   "auth_key"
            t.datetime "created_at"
            t.datetime "updated_at"
          end

          conn.create_table "services", :force => true do |t|
            t.string   "name"
            t.string   "state"
            t.string   "url"
            t.datetime "created_at"
            t.datetime "updated_at"
          end

          conn.add_column "customers", "api_url",        :string
          conn.add_column "customers", "messages_url",   :string
          conn.add_column "customers", "invoices_url",   :string
          conn.add_column "customers", "plan_type",      :string
          conn.add_column "customers", "last_billed_at", :datetime

          conn.add_column "schedulers", "environment_name", :string
          conn.add_column "schedulers", "app_name",         :string
          conn.add_column "schedulers", "messages_url",     :string
          conn.add_column "schedulers", "decomissioned_at", :datetime
          conn.add_column "schedulers", "last_billed_at",   :datetime

        end
      end
    end
  end
end