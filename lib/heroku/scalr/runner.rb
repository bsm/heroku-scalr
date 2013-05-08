class Heroku::Scalr::Runner

  attr_reader :config, :timers

  # @param [String] config_path configuration file location
  def initialize(config_path)
    @config = Heroku::Scalr::Config.new(config_path)
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