class App::Google
end

class App::Google::Search
  attr_reader :results
  def initialize(search_term)
    @results = JSON.parse `googler #{search_term} --json`
  end
end

class App::Google::Hit

  include App::Formatter

  def inspect
    format_attrs(attributes, %i{title})
  end

  attr_accessor :abstract, :title, :url

  # indicates that this is not a DB record
  def id; nil; end

  def initialize(hit)
    @abstract, @title, @url = hit.with_indifferent_access.values_at(
      :abstract, :title, :url
    )
  end

  def attributes
    {
      abstract: abstract,
      title: title,
      url: url,
    }.merge(!persisted? ? {} : {
      comments: comments,
      tags: tags,
      linked: linked, 
      linkbacks: linkbacks
    })
  end

  def page
    Page.first(url: url) || raise(RuntimeError, "page not saved")
  end

  def persisted?
    !!Page.first(url: url)
  end

  def comments; page.comments; end
  def tags; page.tags; end
  def linked; page.linked; end
  def linkbacks; page.linkbacks; end

end