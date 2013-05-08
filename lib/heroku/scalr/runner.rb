class Heroku::Scalr::Runner

  attr_reader :config, :logger

  # @param [String] config_path configuration file location
  # @param [Hash] opts options
  # @option opts [String] log_file log file path
  # @option opts [Integer] log_level log level
  def initialize(config_path, opts = {})
    @config = Heroku::Scalr::Config.new(config_path)
    @logger = Logger.new(opts[:log_file] || STDOUT)
    @logger.level = opts[:log_level] if opts[:log_level]
  end

  # @return [Array<Heroku::Scalr::App>] configured apps
  def apps
    config.apps
  end

  # TODO!
  def run!
  end

end