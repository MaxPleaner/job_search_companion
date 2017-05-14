class App::Career
  def self.apply_to_jobs
    while job = get_job_suggestion
      puts job
      puts job.abstract.blue
    end
  end

  def self.get_job_suggestion
  end
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
  include App::PID

  attr_reader :window
  def initialize
    @email = ENV.fetch("AngelListEmail")
    @password = ENV.fetch("AngelListPassword")
    @window = browser.new.open "http://angel.co/login"
  end

  def login
    form = window.css("#new_user")[0]
    email_input = form.find_element(css: "#user_email")
    password_input = form.find_element(css: "#user_password")
    email_input.send_keys @email
    password_input.send_keys @password
    form.submit
    self
  end

  def search(keyword, locations: nil)
    locations ||= ["151282-San Francisco Bay Area, CA"]
    query = CGI.escape({
        "locations" => locations,
        "keywords" => [keyword],
    }.to_json)
    url = "https://angel.co/jobs#find/f!#{query}"
    window.open url
    spam_infinite_scroll do
      process_results(keyword)
    end
  end

  private

  def spam_infinite_scroll(scroll_height: 9000, &callback)
    idx = 0
    in_new_thread do |pid|
      puts "ANGEL LIST INFINITE SCROLL PID: #{pid}".green
      loop do
        break if window.elem_exists? ".end_notice"
        break if pid_closed?(pid)
        window.script "scrollTo(0, #{scroll_height * (idx + 1)})"
        idx += 1
      end
      callback.call
    end
  end

  def process_results(keyword)
    text_blocks = window.css(".header-info").map(&:text)
    text_blocks.map do |text|
      Job.create(
        category: keyword,
        title: text.match(/(.+)\n/)[1],
        details: text
      )
    end.tap do |jobs|
      puts "created #{jobs.length} jobs"
    end
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

  include App::ConstGetters

  attr_reader :window

  def initialize
  end

  # the same as #search but selects the first result instead
  # of prompting for selection
  def search!(query)
    search(query, select_first: true)
  end

  def search(query, select_first: false)
    img_path = nil
    Headless.ly do
      url = "https://www.crunchbase.com/app/search?query=#{URI.escape query}"
      @window = browser.new.open url
      if window.elem_exists?("[aria-label='Proceed Anyway']")
        btn = window.css("[aria-label='Proceed Anyway']")[0]
        btn.click
      end
      if window.elem_exists? "[md-svg-icon='search']"
        window.css("[md-svg-icon='search']")[0].click
      end
      input = window.css("[aria-label^='Look up a specific company']").last
      input.send_keys "#{query}\n"
      img_path = get_results(select_first: select_first)
      window.close_all
    end
    img_path
  end

  private

  def get_results(select_first: false)
    results = window.wait.until do
      hits = window.css(".cb-overflow-ellipsis").reject do |hit|
        hit.text.blank? || hit.text.in?([
          'Companies', 'Headquarters Location',
          'Company Name', 'Category Groups',
          'Headquarters', 'Description',
          'Crunchbase Rank'
        ])
      end
      hits unless hits.empty?
    end
    result = if select_first
      results[0]
    else
      (results.length-1).downto(0).each do |i|
        puts "#{i}: #{results[i].text}"
      end
      puts "which result to select? (enter index) "
      num = gets.chomp.to_i
      results[num]
    end
    result.click
    window.switch_to_tab(-1)
    window.tmp_screenshot_path
  end
end

