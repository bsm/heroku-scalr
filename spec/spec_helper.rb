require 'bundler/setup'
require 'rspec'
require 'webmock/rspec'
require 'heroku/scalr'

WebMock.disable_net_connect!

RSpec.configure do |c|
  c.before { Heroku::Scalr.logger.stub(:add) }
end