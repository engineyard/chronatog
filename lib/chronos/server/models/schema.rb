module Chronos
  module Server
    class Schema
      def self.setup!
        conn = Model.connection
        unless conn.table_exists?(:customers)

          conn.create_table "customers", :force => true do |t|
            t.references :service
            t.string   "name"
            t.datetime "created_at"
            t.datetime "updated_at"
          end

          conn.create_table "schedulers", :force => true do |t|
            t.references :customer
            t.string   "auth_username"
            t.string   "auth_password"
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