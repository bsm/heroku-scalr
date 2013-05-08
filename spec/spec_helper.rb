require 'bundler/setup'
require 'rspec'
require 'webmock/rspec'
require 'heroku/scalr'

WebMock.disable_net_connect!

module Heroku::Scalr::SpecHelper

  def fixture_path(name)
    File.join File.expand_path("../fixtures", __FILE__), name
  end

end

RSpec.configure do |c|
  c.before { Heroku::Scalr.logger.stub(:add) }
  c.include Heroku::Scalr::SpecHelper
end