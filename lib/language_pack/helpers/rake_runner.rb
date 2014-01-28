class LanguagePack::Helpers::RakeRunner
  include LanguagePack::ShellHelpers

  class RakeTask
    ALLOWED = [:pass, :fail, :no_load, :not_found]
    include LanguagePack::ShellHelpers

    attr_accessor :output, :time, :task, :status, :task_defined, :rakefile_can_load

    alias :rakefile_can_load? :rakefile_can_load
    alias :task_defined?      :task_defined
    alias :is_defined?        :task_defined

    def initialize(task, options = {})
      @task            = task
      @default_options = {user_env: true}.merge(options)
      @status          = :nil
      @output          = ""
    end

    def success?
      status == :pass
    end

    def status?
      @status && @status != :nil
    end

    def status
      raise "Status not set for #{self.inspect}" if @status == :nil
      raise "Not allowed status: #{@status} for #{self.inspect}" unless ALLOWED.include?(@status)
      @status
    end

    def invoke(options = {})
      options = @default_options.merge(options)
      puts "Running: rake #{task}"
      time = Benchmark.realtime do
        self.output = pipe("rake #{task}", options)
      end
      self.time = time

      if $?.success?
        self.status = :pass
      else
        self.status = :fail
      end
      return self
    end
  end

  def initialize(has_rake_gem = true)
    @has_rake = has_rake_gem && has_rakefile?
    if @has_rake
      load_rake_tasks
    else
      @rake_tasks    = ""
      @rakefile_can_load = false
    end
  end

  def cannot_load_rakefile?
    !rakefile_can_load?
  end

  def rakefile_can_load?
    @rakefile_can_load
  end

  def instrument(*args, &block)
    LanguagePack::Instrument.instrument(*args, &block)
  end

  def load_rake_tasks
    instrument "ruby.rake_task_defined" do
      @rake_tasks        ||= run("bundle exec rake -P --trace", user_env: true)
      @rakefile_can_load ||= $?.success?
      @rake_tasks
    end
  end

  def load_rake_tasks!
    out =  load_rake_tasks
    msg =  "Could not detect rake tasks\n"
    msg << "ensure you can run `$ bundle exec rake -P` against your app with no environment variables present\n"
    msg << "and using the production group of your Gemfile.\n"
    msg << "This may be intentional, if you expected rake tasks to be run\n"
    msg << "cancel the build (CTRL+C) and fix the error then commit the fix:\n"
    msg << out
    puts msg if cannot_load_rakefile?
    return self
  end

  def task_defined?(task)
    return false if cannot_load_rakefile?
    @task_available ||= Hash.new {|hash, key| hash[key] = @rake_tasks.match(/\s#{key}\s/) }
    @task_available[task]
  end

  def not_found?(task)
    !task_defined?(task)
  end

  def task(rake_task, options = {})
    t = RakeTask.new(rake_task, options)
    t.task_defined      = task_defined?(rake_task)
    t.rakefile_can_load = rakefile_can_load?
    t
  end

  def invoke(task, options = {})
    self.task(task, options).invoke
  end

private

  def has_rakefile?
    %W{ Rakefile rakefile  rakefile.rb Rakefile.rb}.detect {|file| File.exist?(file) }
  end
end
