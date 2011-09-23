class DocHelper

  def self.save(key, string)
    puts "saving #{key} #{string}"
    snippets[key] = string
    puts "snippets now " + snippets.inspect
  end

  def self.snippets
    @snippets ||= {}
  end

end