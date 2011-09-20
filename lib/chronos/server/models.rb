require 'chronos/server/models/model'
require 'chronos/server/models/schema'
#TODO: just traverse the directory?
%w( creds service customer scheduler job ).each do |model_name|
  require "chronos/server/models/#{model_name}"
end
