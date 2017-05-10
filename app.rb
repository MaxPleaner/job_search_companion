require 'ostruct'
require 'json'
require 'awesome_print'
require 'byebug'
require 'terminfo'
require 'active_support/all'

require_relative './patches.rb'

class App
end

require_relative "./app/google.rb"
require_relative "./app/installers.rb"

module App::Helpers

  def last_results
    @last_results ||= {}
  end

  def install_googler
    puts installers::Google.new
  end

  def search_google(term)
    width = screen_width
    google::Search.new(term).results.tap do |results|
      (results.length-1).downto(0).each do |idx|
        hit = results[idx]
        last_results[idx] = result = google_hit.new(hit)
        puts "
          (#{idx.to_s.red})

          #{result.title.green}
          #{result.url.blue}
          #{result.abstract.chomp}
        ".lchomp.chomp.strip_heredoc
      end
    end
    nil
  end

  def select_result(idx)
  end

  private

  def installers; App::Installers; end
  def google; App::Google; end
  def screen_width; TermInfo.screen_width; end
  def google_hit; App::Google::Hit; end

end

def load_helpers
  include App::Helpers
end
