class App::Tests

  extend App::CliHelpers

  def self.google_search
    search "foo"
    pick 0
  end

  def self.selenium_form
    page = chrome "http://angel.co/login"
    input = page.css "#user_email"
    input.send_keys "foo"
    input.attribute "value"
  end

  def self.get_jobs_from_angellist
    search_angel_list "coffeescript"
  end

  def self.lookup_company_on_crunchbase
    search_crunchbase "pivotal"
  end

end
