module Heroku::Scalr::Metric

  # @param [Symbol] type the metric type
  # @param [Heroku::Scalr::App] app the application
  # @return [Heroku::Scalr::Metric::Abstract] a metric instance
  def self.new(type, app)
    case type
    when :wait, "wait"
      Wait.new(app)
    else
      Ping.new(app)
    end
  end

  class Abstract

    # @param [Heroku::Scalr::App] app the application
    def initialize(app)
      @app = app
    end

    # @return [Integer] number of dynos to adjust by
    def by
      0
    end

    protected

      def http_get
        Excon.head(@app.url)
      rescue Excon::Errors::Timeout
        Excon::Response.new(status: 598)
      rescue Excon::Errors::Error
        Excon::Response.new(status: 444)
      end

      def compare(ms, low, high)
        ms <= low ? -1 : (ms >= high ? 1 : 0)
      end

      def log(*args)
        @app.log(*args)
      end

  end

  class Ping < Abstract

    # @see Heroku::Scalr::Metric::Abstract#by
    def by
      status = nil

      real = Benchmark.realtime do
        status = http_get.status
      end

      unless status == 200
        log :warn, "unable to ping, server responded with #{status}"
        return 0
      end

      ms = (real * 1000).floor
      log :debug, "current ping time: #{ms}ms"

      compare(ms, @app.ping_low, @app.ping_high)
    end

  end

  class Wait < Abstract

    # @see Heroku::Scalr::Metric::Abstract#by
    def by
      ms = http_get.headers["X-Heroku-Queue-Wait"]
      unless ms
        log :warn, "unable to determine queue wait time"
        return 0
      end

      ms = ms.to_i
      log :debug, "current queue wait time: #{ms}ms"

      compare(ms, @app.wait_low, @app.wait_high)
    end

  end


end
