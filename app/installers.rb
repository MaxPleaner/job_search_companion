class App::Installers

  def self.default_info
    puts "run the following in shell".yellow
  end

end

class App::Installers::Google

  def initialize(silent: false)
    str = "
      sudo add-apt-repository ppa:twodopeshaggy/jarun
      sudo apt-get update
      sudo apt-get install googler
    "
    puts str unless silent
    str
  end

end
