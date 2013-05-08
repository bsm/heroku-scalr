require 'heroku/api'
require 'logger'

module Heroku::Scalr

  # @see Heroku::Scalr::Runner#initialize
  def self.run!(*args)
    EM.run do
      Heroku::Scalr::Runner.new(*args).run!
    end
  end

end

%w|config app runner|.each do |name|
  require "heroku/scalr/#{name}"
end