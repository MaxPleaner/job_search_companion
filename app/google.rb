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
end