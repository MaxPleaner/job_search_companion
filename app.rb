require 'ostruct'
require 'json'
require 'awesome_print'
require 'byebug'
require 'terminfo'
require 'active_support/all'
require 'data_mapper'
require 'launchy'

require_relative './patches.rb'

def build_absolute_path(relative_path) # don't include './' in the relative path
  "#{File.expand_path('.')}/#{relative_path}"
end

db_path = build_absolute_path("app.sqlite")
DataMapper.setup(:default, "sqlite3://#{db_path}")

# DataMapper.setup(:default, 'sqlite://app.db')

class App
end

require './app/formatter.rb'
require './models.rb'

require_relative "./app/google.rb"
require_relative "./app/installers.rb"

def load_helpers
  include App::Google::Helpers
end

def autotest
  search! "foo"
  pick! 0
end