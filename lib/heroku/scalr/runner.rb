class Heroku::Scalr::Runner
  attr_reader :config

  # @param [String] config_path configuration file location
  # @param [Hash] opts options
  # @option opts [String] log_file log file path
  # @option opts [Integer] log_level log level
  def initialize(config_path, opts = {})
    @config = Heroku::Scalr::Config.new(config_path, @logger)
  end

  # @return [Array<Heroku::Scalr::App>] configured apps
  def apps
    config.apps
  end

  # Start the runner
  def run!
    return false if @_running

    apps.each do |app|
      EM.add_periodic_timer(app.interval) { app.scale! }
    end

    @_running = true
  end

end