class App::Career

  include App::ConstGetters

  def self.apply_to_jobs(auto_open:, shuffle: true)
    jobs = Job.all(status: nil)
    (jobs = jobs.shuffle) if shuffle
    idx = 0
    loop do
      job = jobs[idx]
      if !job
        log "out of jobs".red
        break
      end
      if auto_open
        process_input(job, "gj")
      end
      log "num seen: #{idx}"
      result = prompt_for_job_update(job)
      break if result == :done
      if result == :prev_job
        if jobs[idx-1]
          idx -= 1
        else
          log "no previous jobs left", :red
        end
      else
        if jobs[idx+1]
          idx +=1
        else
          log "no next jobs left", :ref
        end
      end
    end
  end

  def self.prompt_for_job_update(job)
    loop do
      log job.reload.public_attributes.to_yaml.blue
      log <<-TXT.strip_heredoc
        --------------------------------------------------
        enter one of the following:
          - #{"done".green} to stop apply_to_jobs
          - #{"n".green} to skip to next job
          - #{"p".green} to go back to previous job
          - #{"a".green} to update status as 'applied'
          - #{"u".green} to update status as 'uninterested'
          - #{"w".green} to wipe status (set it to nil)
          - #{"c".green} to add a comment
          - #{"t".green} to tag
          - #{"cr".green} to search crunchbase
          - #{"g".green} to search google
          - #{"gj".green} to search google for "<company> jobs"
          - #{"irb".green} to drop into a sub-REPL, in order to do whatever
          - #{"d".green} to delete the job record
          - #{"title".green} to edit the title
          - #{"details".green} to edit the details
        --------------------------------------------------
      TXT
      log "input: ".blue
      input = gets.chomp
      result = process_input(job, input)
      break(result) if result.in? [:next_job, :prev_job, :done]
    end
  end

  def self.process_input(job, input)
    case input
    when "done"
      :done
    when "p"
      :prev_job
    when "n"
      :next_job
    when 'a'
      job.update status: "applied"
    when 'u'
      job.update status: "uninterested"
    when 'w'
      job.update status: nil
    when 'c'
      log "enter comment text (newline terminates)".blue
      Comment.create(job_id: job.id, content: gets.chomp)
    when 't'
      log "enter tag name (newline terminates)".blue
      Tag.create(job_id: job.id, name: gets.chomp)
    when 'cr'
      crunchbase.new.search(job.title) do |img_url|
        Launchy.open img_url
      end
    when 'g'
      App.launch_new "google_search(%{#{job.title}})"
    when 'gj'
      App.launch_new "google_search(%{#{job.title} jobs})"
    when "irb"
      log "control+D to exit sub-REPL".red
      IRB.start
    when "d"
      log "ARE YOU SURE?(y to proceed)"
      if gets.chomp == "y"
        job.destroy
      else
        log "cancelled".blue
      end
    when "title"
      log "enter new title (newline terminated)"
      title = gets.chomp
      job.update title: title
    when "details"
      log "enter new details (newline terminates)"
      details = gets.chomp
      job.update details: details
    else
      log "unknown command", :red
    end
  end
end

class App::Career::JobSearchEngine

  attr_reader :search_engine

  def initialize(type)
    @search_engine = {
      angel_list: self.class::AngelList,
      stack_overflow: self.class::StackOverflow,
      whos_hiring: self.class::WhosHiring,
      crunchbase: self.class::Crunchbase,
      github: self.class::Github
    }
  end

  def search(query)
    @search_engine.new.search query
  end

end

require_relative "./career/angel_list.rb"
require_relative "./career/stack_overflow.rb"
require_relative "./career/whos_hiring.rb"
require_relative "./career/crunchbase.rb"
require_relative "./career/github.rb"


