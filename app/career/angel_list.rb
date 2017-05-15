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
        log "use remove_pid(#{pid}) to stop if it doesn't end"
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
    last_num_hits = nil
    num_iterations_unchanged = 0
    loop  do
      log "infinite scroll idx: #{idx}"
      num_hits = window.script "return $('.browse_startups_table_row').length"
      log "#{num_hits} hits"
      if last_num_hits == num_hits
        num_iterations_unchanged += 1
      else
        num_iterations_unchanged = 0
      end
      last_num_hits = num_hits
      break if num_iterations_unchanged > 10
      break if pid_closed?(pid)
      break if window.elem_exists? ".end_notice"
      window.script "scrollTo(0, #{scroll_height * (idx + 1)})"
      idx += 1
    end
    callback&.call
  end

  def process_results(keyword)
    text_blocks = window.css(".header-info").map(&:text)
    log "creating #{text_blocks.length} jobs"
    text_blocks.map do |text|
      Job.create(
        category: keyword,
        title: text.match(/(.+)\n/)[1],
        details: text,
        source: "angel_list"
      )
    end.tap do |jobs|
      log "done", :green
    end
  end

end
