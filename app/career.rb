class App::Career
  def self.apply_to_jobs
    while job = get_job_suggestion
      log job
      log job.abstract.blue
    end
  end

  def self.get_job_suggestion

  end
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

  attr_reader :window, :pid
  def initialize
    log "loading email and pass from .env"
    @email = ENV.fetch("AngelListEmail")
    @password = ENV.fetch("AngelListPassword")
  end

  def search(keyword, locations: nil, headless: true, async: true, &callback)
    log 'starting new thread and headless browser'
    async_fn = Proc.new do
      browser_fn = Proc.new do
        log "opening angel.co"
        @window = browser.new.open "http://angel.co/login"
        login
        locations ||= ["151282-San Francisco Bay Area, CA"]
        query = CGI.escape({
            "locations" => locations,
            "keywords" => [keyword],
        }.to_json)
        log "entering query"
        url = "https://angel.co/jobs#find/f!#{query}"
        window.open url
        log "looping over infinite scroll"
        spam_infinite_scroll do
          process_results(keyword)
          callback&.call
        end
      end
      if headless
        Headless.ly { browser_fn.call }
      else
        browser_fn.call
      end
    end
    if async
      in_new_thread do |pid|
        @pid = pid
        log "ANGEL LIST SEARCH PID: #{pid}".green
        log "use remove_pid('#{pid}') to stop if it doesn't end"
        async_fn.call
      end
    else
      async_fn.call
    end
  end

  def login
    form = @window.css("#new_user")[0]
    log "finding login inputs"
    email_input = form.find_element(css: "#user_email")
    password_input = form.find_element(css: "#user_password")
    email_input.send_keys @email
    password_input.send_keys @password
    log "submitting login form"
    form.submit
    self
  end


  private

  def spam_infinite_scroll(scroll_height: 9000, &callback)
    idx = 0
    loop do
      log "infinite scroll idx: #{idx}"
      num_hits = window.script "return $('.browse_startups_table_row').length"
      log "#{num_hits} hits"
      break if pid_closed?(pid)
      break if window.elem_exists? ".end_notice"
      window.script "scrollTo(0, #{scroll_height * (idx + 1)})"
      idx += 1
    end
    callback&.call
  end

  def process_results(keyword)
    text_blocks = window.css(".header-info").map(&:text)
    text_blocks.map do |text|
      Job.create(
        category: keyword,
        title: text.match(/(.+)\n/)[1],
        details: text,
        source: "angel_list"
      )
    end.tap do |jobs|
      log "created #{jobs.length} jobs"
      log "done", :green
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

  attr_reader :window, :pid

  def initialize
  end

  # Shows index of results and prompts for selection
  def search_sync(query, opts={})
    search(query, {async: false, select_first: false, headless: true}.merge(opts))
  end

  # Searches crunchbase, optionally async.
  # :select_first must be true if :async is true
  def search(query, async: true, select_first: true, headless: true)
    log! "searching crunchbase"
    img_path = nil
    search_fn = Proc.new do
      browser_fn = Proc.new do
        log "opening crunchbase search page"
        url = "https://www.crunchbase.com/app/search?query=#{URI.escape query}"
        @window = browser.new.open url
        log "checking for warning shown to mobile devices"
        if window.elem_exists?("[aria-label='Proceed Anyway']")
          log "proceeding to desktop version"
          btn = window.css("[aria-label='Proceed Anyway']")[0]
          btn.click
        end
        log "checking for search button"
        if window.elem_exists? "[md-svg-icon='search']"
          log "clicking search button"
          window.css("[md-svg-icon='search']")[0].click
        end
        log "finding text input"
        input = window.css("[aria-label^='Look up a specific company']").last
        log "typing query"
        input.send_keys "#{query}\n"
        log "getting results"
        img_path = get_results(select_first: select_first)
        window.close_all
        log "IMAGE PATH: #{img_path}"
        log "to open: Launchy.open('#{img_path}')"
        log "done", :green
        img_path
      end
      if headless
        log "launching headless browser"
        Headless.ly { browser_fn.call }
      else
        browser_fn.call
      end
    end
    if async
      in_new_thread do |pid|
        @pid = pid
        log "CRUNCHBASE PID: #{pid}"
        search_fn.call
      end
    else
      search_fn.call
    end
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
        log "#{i}: #{results[i].text}"
      end
      log "which result to select? (enter index) "
      num = gets.chomp.to_i
      results[num]
    end
    log "clicking result"
    result.click
    log "switching tab"
    window.switch_to_tab(-1)
    log "taking screenshot"
    window.tmp_screenshot_path
  end
end

