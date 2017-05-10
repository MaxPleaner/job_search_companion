class App::Google
end

class App::Google::Search
  attr_reader :results
  def initialize(search_term)
    @results = JSON.parse `googler #{search_term} --json`
  end
end

class App::Google::NewsSearch
  def initialize(search_term)
  end
end

class App::Google::Hit
  attr_accessor :abstract, :title, :url
  def initialize(hit)
    @abstract, @title, @url = hit.with_indifferent_access.values_at(
      :abstract, :title, :url
    )
  end
  def comments
    Comment.all(url: url)
  end
  def tags
    Tag.all(url: url)
  end
  def page
    Page.first(url: url)
  end
end

module App::Google::Helpers

  # --------------------------------------------------
  # Methods with return value (and possibly side effects)
  # --------------------------------------------------

  def results
    @results ||= {}
  end

  def selected
    @selected
  end

  def comment(content, url=nil)
    url ||= get_selected.url
    Comment.create url: url, content: content
  end

  def save
    Page.create_from_google_hit get_selected
  end

  def tag(name, url=nil)
    url ||= get_selected.url
    Tag.create url: url, name: name
  end

  # --------------------------------------------------
  # Methods with no return value, just side effects
  # --------------------------------------------------

  def install!
    puts installers::Google.new
  end

  def search!(term)
    width = screen_width
    google::Search.new(term).results.tap do |search_results|
      (search_results.length-1).downto(0).each do |idx|
        hit = search_results[idx]
        results[idx] = google_hit.new(hit)
        result = results[idx]
        puts display_result(result, idx)
      end
    end
    nil    
  end

  def pick!(idx)
    puts "selected: ##{idx}\n".yellow
    @selected = results[idx]
    puts display_result(@selected, idx)
    puts display_selected_result(@selected, idx)
    puts selection_options 
  end

  def open!(url=nil)
    url ||= get_selected.url
    Launchy open url: url
  end

  # --------------------------------------------------
  # Private stuff
  # --------------------------------------------------

  private

  def get_selected
    return @selected if @selected
    raise RuntimeError, "no selected link".red
  end

  def display_result(result, idx)
    "
      (#{idx.to_s.red})

      #{result.title.green}
      #{result.url.blue}
      #{result.abstract.chomp}
    ".lchomp.chomp.strip_heredoc
  end

  def display_selected_result(result, idx)
    comments = result.comments
    tags = result.tags
    "
      #{"Comments:".yellow}
      #{comments.map(&:content).join("\n")}
      
      #{"Tags:".yellow}
      #{result.tags.map(&:name).join("\n")}
    ".lchomp.chomp.strip_heredoc
    # includes a little more detail
  end

  def selection_options
    "
      #{"The following commands can be used with the selection:".yellow}
      #{"open!".green}
      #{"comment".green}
      #{"save".green}
      #{"tag".green}
    ".lchomp.chomp.strip_heredoc
  end

  def installers; App::Installers; end
  def google; App::Google; end
  def screen_width; TermInfo.screen_width; end
  def google_hit; App::Google::Hit; end  

end