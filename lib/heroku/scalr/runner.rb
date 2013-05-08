class Heroku::Scalr::Runner

  attr_reader :config, :timers

  # @param [String] config_path configuration file location
  # @param [Hash] opts options
  # @option opts [String] log_file log file path
  # @option opts [Integer] log_level log level
  def initialize(config_path, opts = {})
    @config = Heroku::Scalr::Config.new(config_path, @logger)
    @timers = Timers.new
  end

  # @return [Array<Heroku::Scalr::App>] configured apps
  def apps
    config.apps
  end

  # Start the runner
  def run!
    apps.each do |app|
      timers.every(app.interval) { app.scale! }
    end

    loop { timers.wait }
  end

end