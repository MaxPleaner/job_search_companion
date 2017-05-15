module App::CliHelpers

  include App::ConstGetters

  include App::PID

  # # Searches all available sites for a term
  # Not working flawlessly yet
  #
  # def search_all(term)
  #   search_angel_list(term) do
  #     search_whos_hiring(term) do
  #       search_github(term) do
  #         search_stack_overflow(term)
  #       end
  #     end
  #   end
  # end

  def results
    @results ||= {}
  end

  def selected
    @selected
  end

  def selected_idx
    @selected_idx
  end

  def comment(content)
    reload_after do
      Comment.create(page_id: get_selected_id, content: content)
    end
  end

  def save(custom_attrs={})
    new_page = Page.create_from_google_hit get_selected, custom_attrs
    update_selected(selected_idx, new_page)
    new_page
  end

  def tag(name)
    reload_after do
      Tag.create(page_id: get_selected_id, name: name)
    end
  end

  def tags
    require_persisted
    get_selected.tags
  end

  def comments
    require_persisted
    get_selected.comments
  end

  def link(type, identifier)
    page = case type
    when :id
      Page.first(id: identifier)
    when :idx
      found_page = results[identifier]
      linked_page = if found_page.id
        found_page
      else
        Page.create_from_google_hit found_page
      end
      linked_page.tap do
        update_results identifier, linked_page
      end
    when :url
      Page.first_or_create(url: identifier)
    when :title
      Page.first_or_create(title: identifier)
    end
    raise(RuntimeError, "page not found") unless page
    reload_after do
      PageLink.first_or_create(
        linked_id: page.id,
        page_id: get_selected_id
      )
    end
  end

  def linked
    require_persisted
    get_selected.linked
  end

  def linkbacks
    require_persisted
    get_selected.linkbacks
  end

  def install(type=nil)
    installers.all.tap do |installers|
      selected = type ? { type: installers[type] } : installers
      selected.values.map(&:get_script).each &method(:log)
    end
  end

  def google_search(term)
    width = screen_width
    google::Search.new(term).results.tap do |search_results|
      (search_results.length-1).downto(0).each do |idx|
        hit = search_results[idx]
        results[idx] = google_hit.new(hit)
        result = results[idx]
        log display_result(result, idx)
      end
    end
    log "call 'pick(<index>) to choose a result", :green
    nil    
  end

  def pick(idx)
    log "selected: ##{idx}\n".blue
    @selected_idx = idx
    @selected = results[idx]
    unless @selected.id
      existing_record = Page.first(url: @selected.url)
      if existing_record
        update_selected(idx, existing_record)
      end
    end 
    log display_result(@selected, idx)
    log display_selected_result(@selected, idx)
    log selection_options 
  end

  def unpick
    @selected = nil
    results.each do |idx, result|
      log display_result(result, idx)
    end
    nil
  end

  def chrome(url=nil)
    browser.new.tap do |window|
      window.open url || get_selected.url
    end
  end

  def lynx(url=nil, useragent: "la policia L_y_n_x")
    lynx_config_file = ENV.fetch "LynxConfigFile", nil
    config_cmd = lynx_config_file ? "-cfg=#{lynx_config_file}" : ""
    url ||= get_selected.url
    ssl_config = "SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt"
    cmd = %{
      lynx \
      -useragent='#{useragent}' \
      #{config_cmd} \
      '#{url}'
    }
    pid = spawn %{
      #{ssl_config} gnome-terminal -e "#{cmd}"
    }
    Process.detach pid
  end

  def search_angel_list(term, opts={}, &callback)
    angel_list.new.search term, opts, &callback
  end

  # Displays first result
  def search_crunchbase term, opts={}, &callback
    crunchbase.new.search term, opts, &callback
  end

  # Displays index of potential results and prompts for selection
  def search_crunchbase_sync term, opts={}, &callback
    crunchbase.new.search_sync term, opts, &callback
  end

  def search_github(query, opts={}, &callback)
    opts = {location: "san francisco"}.merge opts
    github.new.search query, opts, &callback
  end

  def search_stack_overflow(
    query,
    opts={},
    &callback
  )
    opts = {
      location: 'San Francisco, CA, United States',
      distance: 20,
      async: true
    }.merge opts

    stack_overflow.new.search(query,
      location: location,
      distance: distance,
      async: async,
      &callback
    )
  end

  def search_whos_hiring(query, location: "san francisco", async: true, headless: true, &callback)
    whos_hiring.new.search(query,
      location: location,
      async: async,
      headless: headless,
      &callback
    )
  end

  def apply_to_jobs
    career.apply_to_jobs
  end

  # --------------------------------------------------
  # Private stuff
  # --------------------------------------------------

  private

  def selection_options
    "
      #{"The following commands can be used with the selection:".blue}
      #{"unpick".green}
      #{"chrome".green}
      #{"lynx".green}
      #{"save".green}
      #{"comment".green}
      #{"comments".green}
      #{"tag".green}
      #{"tags".green}
      #{"link".green}
      #{"linked".green}
      #{"linkbacks".green}
    ".lchomp.chomp.strip_heredoc
  end

  def reload_after(&blk)
    blk.call.tap { selected.reload }
  end

  def update_selected(idx, page)
    @selected_idx = idx
    update_results idx, page
    @selected = page
  end

  def update_results(idx, page)
    results[idx] = page
  end

  def get_selected
    return @selected if @selected
    raise RuntimeError, "no selected link".red
  end

  def require_persisted
    raise(RuntimeError,
      "page not persisted. call save first"
    ) unless get_selected&.id
  end

  def get_selected_id
    require_persisted
    get_selected.id
  end

  def display_result(result, idx)
    "
      #{idx.to_s}
      #{result.title.green}
      #{result.url.blue}
      #{result.abstract.chomp}
    ".lchomp.chomp.strip_heredoc
  end

  def display_selected_result(result, idx)
    # includes a little more detail
    return "" unless @selected&.id
    "
#{"Comments:".blue}
#{result.comments.map(&:content).join("\n")}

#{"Tags:".blue}
#{result.tags.map(&:name).join("\n")}
    ".lchomp.chomp.strip_heredoc
  end

end