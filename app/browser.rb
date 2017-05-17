class App::Browser

  attr_reader :driver

  def initialize
    @driver = Selenium::WebDriver.for :chrome
  end

  def close
    driver.close
  end

  def close_all
    driver.window_handles.each do
      switch_to_tab 0
      close
    end
  end

  def switch_to_tab(index)
    driver.switch_to.window driver.window_handles[index]
  end

  def get_page_width
    script <<-JS
      return Math.max(
        document.body.scrollWidth,
        document.body.offsetWidth,
        document.documentElement.clientWidth,
        document.documentElement.scrollWidth,
        document.documentElement.offsetWidth
      );
    JS
  end

  def get_page_height
    script <<-JS
      return Math.max(
        document.body.scrollHeight,
        document.body.offsetHeight,
        document.documentElement.clientHeight,
        document.documentElement.scrollHeight,
        document.documentElement.offsetHeight
      );
    JS
  end

  def get_page_dimensions
    [get_page_width, get_page_height]
  end

  def tmp_screenshot_path
    path = Tempfile.create.tap(&:close).path
    width, height = get_page_dimensions
    driver.manage.window.resize_to(width, height)
    driver.save_screenshot path
    path
  end

  def send_jquery
    jquery = File.read("./js/jquery.min.js")
    script jquery
  end

  def open(url)
    driver.navigate.to url
    self
  end

  def script(js)
    driver.execute_script js
  end

  def css(selector)
    wait.until do
      elements = driver.find_elements(css: selector)
      elements if elements.any? &:displayed?
    end
  rescue Selenium::WebDriver::Error::NoSuchElementError
  end

  def elem_exists?(selector)
    wait(timeout: 0.25).until do
      element = driver.find_element(css: selector)
      element if element && element.displayed?
    end
  rescue Selenium::WebDriver::Error::TimeOutError
  end

  # this shouldn't be used to check if an element exists; the timeout is too long
  # for that, use elem_exists?
  def wait(timeout: 6)
    Selenium::WebDriver::Wait.new(:timeout => timeout)
  end

end