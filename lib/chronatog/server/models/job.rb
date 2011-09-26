module Chronatog
  module Server
    class Job < Model
      belongs_to :scheduler

      def api_attributes
        {:callback_url => callback_url, :schedule => schedule}
      end

    end
  end
end
