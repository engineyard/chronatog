module Chronos
  module Server
    class Job < Model
      belongs_to :scheduler
    end
  end
end
