class App::Career
  def self.apply_to_jobs
    while job = get_job_suggestion
      log job
      log job.abstract.blue
    end
  end

  def self.get_job_suggestion

  end
end

class App::Career::JobSearchEngine

  attr_reader :search_engine

  def initialize(type)
    @search_engine = {
      angel_list: self.class::AngelList,
      stack_overflow: self.class::StackOverflow,
      whos_hiring: self.class::WhosHiring
    }
  end

  def search(query)
    @search_engine.search query
  end

end

require_relative "./career/angel_list.rb"
require_relative "./career/stack_overflow.rb"
require_relative "./career/whos_hiring.rb"
require_relative "./career/crunchbase.rb"
require_relative "./career/github.rb"


