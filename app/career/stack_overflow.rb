class App::Career::JobSearchEngine::StackOverflow
  def search(query, location:, distance:, async: true, &callback)
    query_string = {
      q: query,
      location: CGI.escape(location),
      d: distance,
      u: "Miles"
    }.to_param
    async_fn = Proc.new do
      log "Fetching XML page"
      url = "http://stackoverflow.com/jobs/feed?#{query_string}"
      results = Nokogiri.parse Mechanize.new.get(url).body
      process_results(results, query, &callback)
    end
    if async
      in_new_thread do |pid|
        log "STACK OVERFLOW SEARCH PID: #{pid}"
        async_fn.call
      end
    else
      async_fn.call
    end
  end
  def process_results(results, query, &callback)
    hits = results.xpath("//item")
    log "creating #{hits.length} jobs"
    jobs = hits.map do |hit|
      company_name = hit.xpath("./a10:author").text
      job_title = hit.xpath("./title").text
      link = hit.xpath("./link").text
      job = {
        title: company_name,
        details: "#{job_title} - #{link}",
        category: query,
        source: "stack_overflow"
      }
      Job.create job
    end
    log "done", :green
    callback&.call
    jobs
  end
end
