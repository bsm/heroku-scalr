require 'optparse'
require 'logger'

module Heroku
  module Scalr
    module CLI

      def self.run!(argv = ARGV)
        new(argv).run!
      end

      def initialize(argv)
        super()
        @config_path = "./config.rb"
        @options     = {}
        parser.parse!(argv)
      end

      def run!
        require 'heroku/scalr'
        Heroku::Scalr.run!(@redis_url, @config_path, self)
      end

      def parser
        @parser ||= OptionParser.new do |o|
          o.banner = "Usage: heroku-scalr [options]"
          o.separator ""

          o.on("-C", "--config PATH", "Configuration file path. Default: ./config.rb") do |path|
            @config_path = path
          end

          o.on("-l", "--log PATH", "Custom log file path. Default: STDOUT") do |path|
            @options.update log_file: path
          end

          o.on("-v", "--verbose", "Enable verbose logging.") do
            @options.update log_level: ::Logger::DEBUG
          end

          o.separator ""
          o.on_tail("-h", "--help", "Show this message") do
            puts o
            exit
          end
        end
      end

    end
  end
end
