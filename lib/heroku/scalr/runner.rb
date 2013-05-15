class Heroku::Scalr::Runner
  SIGNALS = %w[HUP INT TERM] & Signal.list.keys

  attr_reader :config

  # @param [String] config_path configuration file location
  def initialize(config_path)
    @config = Heroku::Scalr::Config.new(config_path)
  end

  # @return [Timers] recurring timers
  def timers
    @timers ||= Timers.new.tap do |t|
      config.apps.each do |app|
        app.log :info, "monitoring every #{app.interval}s"
        t.every(app.interval) { app.scale! }
      end
    end
  end

  # Start the runner
  def run!
    SIGNALS.each do |sig|
      Signal.trap(sig) { stop! }
    end

    loop { timers.wait }
  end

  # Stop execution
  def stop!
    Heroku::Scalr.logger.info "Exiting ..."
    exit(0)
  end

end