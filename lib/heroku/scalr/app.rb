class Heroku::Scalr::App

  DEFAULTS = {
    interval: 30,
    min_dynos: 1,
    max_dynos: 2,
    wait_low: 10,
    wait_high: 100,
    ping_low: 200,
    ping_high: 500,
    metric: :ping,
    min_frequency: 60
  }.freeze

  attr_reader :name, :url, :api, :interval, :min_dynos, :max_dynos,
              :metric, :wait_low, :wait_high, :ping_low, :ping_high,
              :min_frequency, :last_scaled_at

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
  # @option opts [String] :api_key
  #   the Heroku account's API key
  def initialize(name, opts = {})
    @name = name.to_s

    opts = DEFAULTS.merge(opts)
    fail("no API key given") unless opts[:api_key]
    fail("min_dynos must be at least 1") unless opts[:min_dynos] >= 1
    fail("max_dynos must be at least 1") unless opts[:max_dynos] >= 1
    fail("interval must be at least 10") unless opts[:interval] >= 10

    @url = opts[:url] || "http://#{@name}.herokuapp.com/robots.txt"
    @api = Heroku::API.new api_key: opts[:api_key]

    @interval  = opts[:interval].to_i
    @min_dynos = opts[:min_dynos].to_i
    @max_dynos = opts[:max_dynos].to_i
    @wait_low  = opts[:wait_low].to_i
    @wait_high = opts[:wait_high].to_i
    @ping_low  = opts[:ping_low].to_i
    @ping_high = opts[:ping_high].to_i
    @metric    = Heroku::Scalr::Metric.new(opts[:metric], self)
    @min_frequency  = opts[:min_frequency].to_i
    @last_scaled_at = Time.at(0)
  end

  # Scales the app
  def scale!
    scale_at = next_scale_attempt
    if Time.now < scale_at
      log :debug, "skip scaling, next attempt in #{(scale_at - Time.now).to_i}s"
      return
    end

    do_scale(metric.by)
  rescue => e
    msg = "#{e.class}: #{e.to_s}"
    msg << "\n\t" << e.backtrace.join("\n\t") if e.backtrace
    log :error, msg
    nil
  end

  # @param [Symbol] level
  # @param [String] message
  def log(level, message)
    Heroku::Scalr.logger.send(level, "[#{name}] #{message}")
  end

  protected


    # @return [Time] the next scale attempt
    def next_scale_attempt
      last_scaled_at + min_frequency
    end

    def do_scale(by)
      return if by.zero?

      info = api.get_app(name)
      unless info.status == 200
        log :warn, "error fetching app info, responded with #{info.status}"
        return
      end

      current = info.body["dynos"].to_i
      target  = current + by
      target  = max_dynos if target > max_dynos
      target  = min_dynos if target < min_dynos

      if target == current
        log :debug, "skip scaling, keep #{current} dynos"
        return
      end

      log :info, "scaling to #{target} dynos"
      result = api.post_ps_scale(name, "web", target)
      unless result.status == 200
        log :warn, "error scaling app, responded with #{result.status}"
        return
      end

      @last_scaled_at = Time.now
      target
    end

  private

    def fail(message)
      raise ArgumentError, "Invalid options: #{message}"
    end

end