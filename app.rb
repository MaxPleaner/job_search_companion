require 'ostruct'
require 'json'
require 'awesome_print'
require 'byebug'
require 'terminfo'
require 'active_support/all'
require 'data_mapper'
require 'launchy'
require 'pru'
require 'selenium-webdriver'
require 'dotenv'
require 'yaml/store'

Dotenv.load

require_relative './patches.rb'

# don't include './' in the relative path
def build_absolute_path(relative_path)
  "#{File.expand_path('.')}/#{relative_path}"
end

db_path = build_absolute_path("app.sqlite")
DataMapper.setup(:default, "sqlite3://#{db_path}")

class App
end

require './app/const_getters.rb'
require './app/formatter.rb'
require './app/text_document.rb'
require './app/browser.rb'
require './models.rb'

require './app/career.rb'
require_relative "./app/google.rb"
require_relative "./app/cli_helpers.rb"
require_relative "./app/installers.rb"

def load_helpers
  include App::CliHelpers
end

def autotest
  # search "foo"
  # pick 0
  
  # page = chrome "http://angel.co/login"
  # input = page.css "#user_email"
  # input.send_keys "foo"
  # input.attribute "value"

  search_angel_list "ruby"
rescue => e
  puts e
  puts e.backtrace
end