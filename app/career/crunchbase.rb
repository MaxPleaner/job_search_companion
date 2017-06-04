class App::Career::JobSearchEngine::Crunchbase

  include App::ConstGetters

  attr_reader :window, :pid

  def initialize
  end

  # Shows index of results and prompts for selection
  def search_sync(query, opts={}, &callback)
    search(query, {async: false, select_first: false, headless: true}.merge(opts), &callback)
  end

  # Searches crunchbase, optionally async.
  # :select_first must be true if :async is true
  def search(query, async: true, select_first: true, headless: true, &callback)
    log! "searching crunchbase"
    img_path = nil
    search_fn = Proc.new do
      browser_fn = Proc.new do
        log "opening crunchbase search page"
        url = "https://www.crunchbase.com/app/search?query=#{URI.escape query}"
        @window = browser.new.open url
        byebug
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
        callback&.call(img_path)
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
