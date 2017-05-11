class App::Career
end

class App::Career::JobSearch
end

class App::Career::JobSearchEngine

  attr_reader :search_engine

  def initialize(type)
    @search_engine = {
      angel_list: self.class::AngelList,
      stack_overflow: self.class::StackOverflow,
      whos_hiring: self.class::WhosHiring
    }
  end

  def search(query)
    @search_engine.search query
  end

end

class App::Career::JobSearchEngine::AngelList
  include App::ConstGetters

  attr_reader :window
  def initialize
    @email = ENV.fetch("AngelListEmail")
    @password = ENV.fetch("AngelListPassword")
    @window = browser.new.open "http://angel.co/login"
  end

  def login
    form = window.css("#new_user")
    email_input = form.css("#user_email")[0]
    password_input = form.css("#user_password")[0]
    email_input.send_keys @email
    password_input.send_keys @password
    form.submit
    self
  end

  def search(*keywords, locations: nil)
    locations ||= ["151282-San Francisco Bay Area, CA"]
    query = CGI.escape({
        "locations" => locations,
        "keywords" => keywords
    }.to_json)
    url = "https://angel.co/jobs#find/f!#{query}"
    window.open url
    spam_infinite_scroll
    read_results
  end

  private

  def spam_infinite_scroll(scroll_height: 9000)
    idx = 0
    until window.elem_exists? ".end_notice"
      window.script "scrollTo(0, #{scroll_height * (idx + 1)})"
      idx += 1
    end
  end

  def read_results
    byebug
    false
    # .header-info
  end

end

class App::Career::JobSearchEngine::StackOverflow
  def search(query)
  end
end

class App::Career::JobSearchEngine::WhosHiring
  def search(query)
  end
end

class App::Career::JobSearchEngine::Crunchbase
  def search(query)
  end
end

