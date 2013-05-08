# Loads a config file and evaluates the stored configuration
#
# @example of a config file
#
#   defaults email: "me@gmail.com", token: "d728201893d47607ec382", interval: 60
#   app "lonely-warrior-45", url: "http://cnamed.host/robots.txt"
#
class Heroku::Scalr::Config

  attr_reader :apps

  # @param [String] path file path containing a configuration
  def initialize(path)
    @defaults = {}
    @apps     = []
    instance_eval File.read(path)
  end

  # @param [Hash] opts updates for defaults
  # @see Heroku::Scalr::App#initialize for a full set of options
  def defaults(opts = {})
    @defaults.update(opts)
  end

  # @param [String] name the Heroku app name
  # @param [Hash] opts configuration options
  # @see Heroku::Scalr::App#initialize for a full set of options
  def app(name, opts = {})
    opts = @defaults.merge(opts)
    @apps << Heroku::Scalr::App.new(name, opts)
  end

end