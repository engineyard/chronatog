require 'rack/tunnel'
use Rack::Tunnel, 'http://root@ec2-50-112-49-218.us-west-2.compute.amazonaws.com'

require 'rack/reverse_proxy'
use Rack::ReverseProxy do
  # Set :preserve_host to true globally (default is true already)
  reverse_proxy_options :preserve_host => true

  # Forward the path /test* to http://example.com/test*
  reverse_proxy '/', 'http://localhost:8080'
end

app = proc do |env|
  [ 200, {'Content-Type' => 'text/plain'}, ["b"] ]
end
run app
