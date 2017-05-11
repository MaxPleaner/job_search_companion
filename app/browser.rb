class App::Browser

  attr_reader :driver

  def initialize
    @driver = Selenium::WebDriver.for :chrome
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
      element && element.displayed?
    end
  rescue Selenium::WebDriver::Error::TimeOutError
  end

  private

  # this shouldn't be used to check if an element exists; the timeout is too long
  # for that, use elem_exists?
  def wait(timeout: 3)
    Selenium::WebDriver::Wait.new(:timeout => timeout)
  end

end