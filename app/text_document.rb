class App::TextDocument

  attr_reader :path

  def initialize(path)
    @path = path
  end

  def create
    if File.exists?(path)
      raise(RuntimeError, "#{path} already exists")
    end
    File.open(path, 'w')
  end

  def read
    unless File.exists?(path)
      raise(RuntimeError, "#{path} doesnt exist")
    end
    File.read path
  end

  def write(text)
    if File.exists?(path)
      raise(RuntimeError, "#{path} already exists (use append)")
    end
    File.open(path, 'w') { |f| f.write text }
  end

  def append(text='')
    File.open(path, 'a') { |f| f.write text }
  end

end