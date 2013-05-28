require 'heroku/api'
require 'logger'
require 'excon'
require 'timers'
require 'benchmark'

module Heroku::Scalr
  extend self

  # @see Heroku::Scalr::Runner#initialize
  def run!(*args)
    Heroku::Scalr::Runner.new(*args).run!
  end

  # @param [Hash] opts
  # @options opts [String] :log_file custom log file path
  # @options opts [String] :log_level custom log level
  def configure(opts = {})
    @logger = Logger.new(opts[:log_file]) if opts[:log_file]
    logger.level = opts[:log_level] if opts[:log_level]
    self
  end

  # @return [Logger] the logger instance
  def logger
    @logger ||= Logger.new(STDOUT)
  end

end

%w|core_ext config app runner metric|.each do |name|
  require "heroku/scalr/#{name}"
end