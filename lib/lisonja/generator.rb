class Array
  def rand
    self[Kernel.rand(self.size)]
  end
end

class PartiallyStolenComplimentGenerator
  VOWELS = ['a', 'e', 'i', 'o', 'u']
  ADJ1 = ['elegant', 'hearty', 'beautiful', 'fine', 'fabulous', 'pretty',
          'good', 'strong', 'indomitable', 'perfect', 'excellent', 'undaunted',
          'brilliant', 'heroic', 'confident', 'superlative', 'happy', 'diligent',
          'lovely', 'outstanding', 'jovial', 'courteous', 'hot-swappable', 'smart',
          'clever', 'gentle', 'generous', 'punctual', 'accomplished', 'expert',
          'skillful', 'consummate', 'talented', 'gifted', 'adept', 'capable',
          'amazing', 'impressive', 'remarkable', 'magnificent', 'superb',
          'stunning', 'outstanding', 'excellent', 'spectacular', 'splendid',
          'brilliant', 'fantastic', 'poised', 'excellent', 'exceptional',
          'pleasing', 'quite', 'rather', 'unusually', 'handsome', 'absolutely',
          'actually', 'altogether', 'considerably', 'entirely', 'fully',
          'perfectly', 'positively', 'purely', 'really', 'thoroughly',
          'totally', 'truly', 'utterly', 'wholly', 'clearly', 'performant']
  ADJ2 = ['broad-minded', 'big-hearted', 'quick-witted', 'open-minded',
          'success-oriented', 'strong-willed', 'heavy-hitting',
          'results-oriented', 'high-tech', 'cutting-edge', 'bi-coastal',
          'old-school', 'warm-hearted', 'fashion-forward', 'hands-on',
          'lean-and-mean', 'far-out', 'self-assured', 'go-getter',
          'web-savvy', 'socially-conscious', 'awe-inspiring', 'customer-oriented',
          'self-confident', 'well-balanced', 'easy-going', 'well-respected',
          'well-dressed', 'first-class', 'first-rate', 'well-behaved',
          'well-rounded', 'happy-go-lucky', 'self-assured', 'fun-loving', 'high-bandwidth',
          'high-cpu', 'highly-available', 'load-tested', 'battle-tested', 'multi-regional']
  NOUN = ['environment', 'server', 'IP', 'volume', 'disk-drive', 'floppy',
          'spool', 'database', 'router', 'instance', 'hostname', 'hash-table', 'firewall',
          'application', 'codebase', 'interface', 'collaborator', 'user', 'webmaster',
          'website', 'domain', 'processor', 'CPU']
  PREFIX_ANY = [ "Everyone admires your", 'I envy your', "Congratulations on your", "Kudos on the", "Job well done with the"]
  PREFIX_A = ["You have a",'I think you have a'] + PREFIX_ANY
  PREFIX_AN = ["You have an",'I think you have an'] + PREFIX_ANY

  def self.log
    @log ||= []
  end

  def self.run!
    noun = NOUN.rand
    adj1 = ADJ1.rand
    adj2 = ADJ2.rand
    prefix = VOWELS.include?(adj1.chars.first) ? PREFIX_AN.rand : PREFIX_A.rand
    generated = "#{prefix} #{adj1} #{adj2} #{noun}"
    log << generated
    generated
  end
  
end