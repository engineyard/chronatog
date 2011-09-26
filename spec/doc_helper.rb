class DocHelper

  def self.save(key, obj)
    string = obj.inspect
    if obj.is_a?(Hash)
      max_key_length = obj.keys.sort_by{|k| k.to_s.length}.last.to_s.length
      string.gsub!(", :", ", \n  :")
      string.gsub!("{", "{\n  ")
      string.gsub!("}", "\n}")
      string.gsub!("=>", " => ")
      obj.keys.each{|k| string.gsub!(":#{k}", ":#{k.to_s.ljust(max_key_length)}") }
    end
    snippets[key] = string
  end

  def self.snippets
    @snippets ||= {}
  end

end