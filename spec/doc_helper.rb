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
      string.gsub!(", \"", ", \n\"")
      string.gsub!(", :", ", \n:")
      string.gsub!("{", "{\n")
      string.gsub!("}", "\n}")
      string.gsub!("=>", " => ")
      max_key_length = obj.keys.sort_by{|k| k.to_s.length}.last.to_s.length
      obj.keys.each{|k| string.gsub!("\"#{k}\"", "\"#{(k.to_s + '"').ljust(max_key_length+1)}") }
      obj.keys.each{|k| string.gsub!(":#{k}", ":#{k.to_s.ljust(max_key_length)}") }
      depth = 0
      string = string.split("\n").map do |line|
        if line.match(/\}/)
          depth -= 1
        end
        transformed = ("  " * depth) + line
        if line.match(/\]/)
          depth -= 1
        end
        if line.match(/\{|\[/)
          depth += 1
        end
        transformed
      end.join("\n")
      prev = ""
      string = string.split("\n").reverse.map do |line|
        if line.match(/\=\>/)
          line + prev
        elsif line.match(/^\{|\}/)
          line
        else
          prev = (line + prev).strip
          nil
        end
      end.compact.reverse.join("\n")
    end
    snippets[key] = string
  end

  def self.snippets
    @snippets ||= {}
  end

end