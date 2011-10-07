class DocHelper

  class RequestLogger
    def self.record_next_request(url_key, params_key)
      request_recordians << [url_key, params_key]
    end
    def self.request_recordians
      @request_recordians ||= []
    end

    def initialize(app) @app = app end
    def call(env)
      url_key, params_key = RequestLogger.request_recordians.pop
      if url_key
        request = Rack::Request.new(env)
        DocHelper.save(url_key, request.url)
      end
      if params_key
        DocHelper.save(params_key, JSON::parse(env["rack.input"].string))
      end
      @app.call env
    end
  end

  def self.save(key, obj)
    string = obj.inspect
    if obj.is_a?(Hash)
      if obj.keys.first.is_a?(String)
        max_key_length = obj.keys.sort_by{|k| k.to_s.length}.last.to_s.length
        string.gsub!(", \"", ", \n  \"")
        string.gsub!("{", "{\n  ")
        string.gsub!("}", "\n}")
        string.gsub!("=>", " => ")
        obj.keys.each{|k| string.gsub!("\"#{k}\"", "\"#{(k.to_s + '"').ljust(max_key_length+1)}") }
      else
        max_key_length = obj.keys.sort_by{|k| k.to_s.length}.last.to_s.length
        string.gsub!(", :", ", \n  :")
        string.gsub!("{", "{\n  ")
        string.gsub!("}", "\n}")
        string.gsub!("=>", " => ")
        obj.keys.each{|k| string.gsub!(":#{k}", ":#{k.to_s.ljust(max_key_length)}") }
      end
    end
    snippets[key] = string
  end

  def self.snippets
    @snippets ||= {}
  end

end