class App::Installers

  def self.default_info
    log "run the following in shell"
  end

  def self.all
    {
      google: App::Installers::Google,
      chromedriver: App::Installers::ChromeDriver,
    }
  end

end

class App::Installers::Google

  def self.get_script
    "
      sudo add-apt-repository ppa:twodopeshaggy/jarun
      sudo apt-get update
      sudo apt-get install googler
    "
  end

end

class App::Installers::ChromeDriver

  def self.get_script
    "
      sudo apt-get install unzip

      wget -N http://chromedriver.storage.googleapis.com/2.29/chromedriver_linux64.zip
      unzip chromedriver_linux64.zip
      rm chromedriver_linux64.zip

      chmod +x chromedriver

      sudo mv -f chromedriver /usr/local/share/chromedriver
      sudo ln -s /usr/local/share/chromedriver /usr/local/bin/chromedriver
      sudo ln -s /usr/local/share/chromedriver /usr/bin/chromedriver
    "
  end

end
