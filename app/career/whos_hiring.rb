class App::Career::JobSearchEngine::WhosHiring

  include App::PID

  attr_reader :window
  attr_reader :pid

  def search(query, location:, async:, headless:)
    log "searching whos hiring"
    query_string = {
      location: CGI.escape(location),
      search: query
    }.to_param
    url = "https://whoishiring.io/search/37.7749/-122.4194/10?#{query_string}"
    async_fn = Proc.new do
      browser_fn = Proc.new do
        @window = browser.new.open url
        spam_infinite_loop
        process_results(query)
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
        log "WHOS HIRING SEARCH PID: #{pid}"
        async_fn.call
      end
    else
      async_fn.call
    end
  end

  def spam_infinite_loop
    window.send_jquery # # lazy
    idx = 0
    loop do
      break if pid_closed?(pid)
      break if window.elem_exists?(".status .text")
      window.script <<-JS
        $items_list = $(".ItemsList");
        $items_list.scrollTop($items_list[0].scrollHeight);
      JS
      sleep 1 # allow them to do their thing
      log "infinite scroll idx: #{idx}"
      log "num hits: #{window.css(".Item").length}"
      idx += 1
    end
  end

  def process_results(query)
    log "parsing DOM info for jobs"
    job_datas = window.css(".Item").map do |hit|
      job_title = hit.find_element(css: ".info [itemprop='title']").text
      company_name = hit.find_element(css: ".info h2").text
      byebug
      location = hit.find_element(css: "[itemprop='addressLocality']")
      url = begin
        hit.find_element(css: "a").attribute("href").value
      rescue Selenium::WebDriver::Error::NoSuchElementError
        ""
      end 
      {
        title: company_name,
        details: "#{job_title} - #{location} - #{url}",
        source: "whos_hiring",
        category: query
      }
    end
    log "creating job records"
    jobs = job_datas.map &Job.method(:create)
    log "done", :green
    jobs
  end

end
