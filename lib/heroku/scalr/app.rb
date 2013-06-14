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
    cool_freq: 180,
    heat_freq: 60,
  }.freeze

  attr_reader :name, :url, :api_key, :interval, :min_dynos, :max_dynos,
              :metric, :wait_low, :wait_high, :ping_low, :ping_high,
              :cool_freq, :heat_freq, :last_scaled_at

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
  # @option opts [Integer] :ping_low
  #   lowers the number of dynos if ping time is less than `ping_low` ms, default: 200
  # @option opts [Integer] :ping_high
  #   lowers the number of dynos if ping time is more than `ping_high` ms, default: 500
  # @option opts [Integer] :cool_freq
  #   leave at least `cool_freq` seconds before scaling down again, default: 180
  # @option opts [Integer] :heat_freq
  #   leave at least `heat_freq` seconds before scaling up again, default: 60
  # @option opts [String] :api_key
  #   the Heroku account's API key
  def initialize(name, opts = {})
    @name = name.to_s

    opts = DEFAULTS.merge(opts)
    fail("no API key given") unless opts[:api_key]
    fail("min_dynos must be at least 1") unless opts[:min_dynos] >= 1
    fail("max_dynos must be at least 1") unless opts[:max_dynos] >= 1
    fail("interval must be at least 10") unless opts[:interval] >= 10

    @url       = opts[:url] || "http://#{@name}.herokuapp.com/robots.txt"
    @api_key   = opts[:api_key]
    @interval  = opts[:interval].to_i
    @min_dynos = opts[:min_dynos].to_i
    @max_dynos = opts[:max_dynos].to_i
    @wait_low  = opts[:wait_low].to_i
    @wait_high = opts[:wait_high].to_i
    @ping_low  = opts[:ping_low].to_i
    @ping_high = opts[:ping_high].to_i
    @metric    = Heroku::Scalr::Metric.new(opts[:metric], self)
    @cool_freq = opts[:cool_freq].to_i
    @heat_freq = opts[:heat_freq].to_i
    @last_scaled_at = Time.at(0)
  end

  # Scales the app
  def scale!
    scale_at = last_scaled_at + [cool_freq, heat_freq].min
    now      = Time.now
    if now < scale_at
      log :debug, "skip check, next attempt in #{(scale_at - now).to_i}s"
      return
    end

    by = metric.by
    do_scale(by) if must_scale?(by, now)
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

    def must_scale?(by, now)
      scale_dn = last_scaled_at + cool_freq
      scale_up = last_scaled_at + heat_freq

      if by < 0 && now < scale_dn
        log :debug, "skip scaling, next down attempt in #{(scale_dn - now).to_i}s"
        return false
      elsif by > 0 && now < scale_up
        log :debug, "skip scaling, next up attempt in #{(scale_up - now).to_i}s"
        return false
      elsif by == 0
        log :debug, "no scaling required"
        return false
      end

      true
    end

    def do_scale(by)
      api  = Heroku::API.new(api_key: api_key)
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