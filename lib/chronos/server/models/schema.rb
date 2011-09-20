module Chronos
  module Server
    class Schema
      def self.setup!
        conn = Model.connection
        unless conn.table_exists?(:creds)
          # TODO :move these:

          # EY-integration tables:
          # conn.create_table "creds", :force => true do |t|
          #   t.string   "auth_id"
          #   t.string   "auth_key"
          #   t.datetime "created_at"
          #   t.datetime "updated_at"
          # end
          # conn.create_table "services", :force => true do |t|
          #   t.string   "name"
          #   t.string   "state"
          #   t.string   "url"
          #   t.datetime "created_at"
          #   t.datetime "updated_at"
          # end

          conn.create_table "customers", :force => true do |t|
            t.references :service
            t.string   "name"
            # t.string   "api_url"
            # t.string   "messages_url"
            # t.string   "invoices_url"
            # t.string   "plan_type"
            # t.datetime "last_billed_at"
            t.datetime "created_at"
            t.datetime "updated_at"
          end
          conn.create_table "schedulers", :force => true do |t|
            t.references :customer
            # t.string   "environment_name"
            # t.string   "app_name"
            t.string   "auth_username"
            t.string   "auth_password"
            # t.string   "messages_url"
            # t.text     "job"
            # t.datetime "decomissioned_at"
            # t.datetime "last_billed_at"
            t.datetime "created_at"
            t.datetime "updated_at"
          end
          conn.create_table "jobs", :force => true do |t|
            t.references :scheduler
            t.string     "callback_url"
            t.string     "schedule"
          end
        end
      end

      def self.teardown!
        conn = Model.connection
        conn.tables.each do |table_name|
          conn.drop_table(table_name)
        end
      end
    end
  end
end