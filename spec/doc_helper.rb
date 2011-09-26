class DocHelper

  def self.save(key, string)
    snippets[key] = string
  end

  def self.snippets
    @snippets ||= {}
  end

end