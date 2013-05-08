ENV["REDIS_URL"] ||= "redis://127.0.0.1:6379/9"

require 'bundler/setup'
require 'rspec'
require 'heroku/scalr'