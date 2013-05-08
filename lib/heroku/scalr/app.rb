class Heroku::Scalr::App

  DEFAULTS = {
    interval: 30,
    min_dynos: 1,
    max_dynos: 2,
    wait_low: 10,
    wait_high: 100,
    min_frequency: 60
  }.freeze

  # @param [String] name Heroku app name
  # @param [Hash] opts options
  # @option opts [Integer] :interval
  #   perform checks every `interval` seconds, default: 60
  # @option opts [Integer] :min_dynos
  #   the minimum number of dynos, default: 1
  # @option opts [Integer] :max_dynos
  #   the maximum number of dynos, default: 2
  # @option opts [Integer] :wait_low
  #   lowers the number of dynos if queue wait time is less than `wait_low` ms, default: 10
  # @option opts [Integer] :wait_high
  #   lowers the number of dynos if queue wait time is more than `wait_high` ms, default: 100
  # @option opts [Integer] :min_frequency
  #   leave at least `min_frequency` seconds before scaling again, default: 60
  # @option opts [String] :email
  #   the Heroku account's email address
  # @option opts [String] :token
  #   the Heroku account's API token
  def initialize(name, opts = {})
    @name = name.to_s
    @opts = DEFAULTS.merge(opts)

    fail("number of 'min_dynos' must be > 0") unless @opts[:min_dynos] > 0
    fail("number of 'max_dynos' must be > 0") unless @opts[:max_dynos] > 0
    fail("no email address given") unless @opts[:email]
    fail("no API token given") unless @opts[:token]
  end

  private

    def fail(message)
      raise ArgumentError, "Invalid options: #{message}"
    end

end