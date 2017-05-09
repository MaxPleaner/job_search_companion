require 'ostruct'

class App
end

require_relative "./app/google.rb"
require_relative "./app/installers.rb"

module Helpers

  def installers; App::Installers; end
  def google; App::Google; end

  def install_googler
    installers.Google.new
  end

  def search_google(term)
    google.Search.new(term)
  end

end