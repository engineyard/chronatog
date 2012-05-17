class DocHelper

  class RequestLogger
    def self.record_next_request(url_key = nil, params_key = nil, response_json_key = nil)
      request_recordians << [url_key, params_key, response_json_key]
    end
    def self.request_recordians
      @request_recordians ||= []
    end

    def initialize(app) @app = app end
    def call(env)
      url_key, params_key, response_json_key = RequestLogger.request_recordians.shift
      if url_key
        request = Rack::Request.new(env)
        DocHelper.save(url_key, request.url)
      end
      if params_key
        begin
          DocHelper.save(params_key, JSON::parse(env["rack.input"].string), :json)
        rescue JSON::ParserError => e
          DocHelper.save(params_key, env["rack.input"].string)
        end
      end
      tuple = @app.call(env)
      if response_json_key
        res_body = ""
        tuple.last.each{|v| res_body << v.to_s }
        DocHelper.save(response_json_key, JSON::parse(res_body), :json)
      end
      tuple
    end
  end

  def self.save(key, obj, format = :ruby)
    string = obj.inspect
    if obj.is_a?(String)
      string = obj
    end
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
          prev_was = prev
          prev = ""
          line + prev_was
        elsif line.match(/^\{|\}/)
          prev = ""
          line
        else
          prev = (line + prev).strip
          nil
        end
      end.compact.reverse.join("\n")
      if format == :json
        string.gsub!(/[ ]*\=\>/, ":")
        string.gsub!(": nil",": null")
      end
    end
    snippets[key] = string.split("\n").map{|x| x.rstrip }.join("\n")
  end

  def self.snippets
    @snippets ||= {}
  end

end