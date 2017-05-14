class App::Career::JobSearchEngine::Github

  def search(query, location:, async: true)
    param_string = {
      description: query,
      location: CGI.escape(location)
    }.to_param
    async_fn = Proc.new do
      log "searching github JSON API"
      url = "https://jobs.github.com/positions.json?#{param_string}"
      results = JSON.parse Mechanize.new.get(url).body
      process_results(results, query)
    end
    if async
      in_new_thread do |pid|
        log "GITHUB PID: #{pid}"
        async_fn.call
      end
    else
      async_fn.call
    end
  end

  def process_results(results, query)
    log "creating #{results.length} jobs"
    results.each do |result|
      Job.create(
        category: query,
        title: result["company"],
        details: "#{result['title']} - #{result['location']} - #{result['company_url']}",
        source: "github"
      )
    end
    log "done"
  end

end
