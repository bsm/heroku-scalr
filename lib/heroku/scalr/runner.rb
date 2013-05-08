class Heroku::Scalr::Runner

  attr_reader :config

  # @param [String] config_path configuration file location
  def initialize(config_path)
    @config = Heroku::Scalr::Config.new(config_path)
  end

  # @return [Timers] recurring timers
  def timers
    @timers ||= Timers.new.tap do |t|
      config.apps.each do |app|
        t.every(app.interval) { app.scale! }
      end
    end
  end

  # Start the runner
  def run!
    loop { timers.wait }
  end

end