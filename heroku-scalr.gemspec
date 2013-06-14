# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.required_ruby_version = '>= 1.9.1'
  s.required_rubygems_version = ">= 1.8.0"

  s.name        = File.basename(__FILE__, '.gemspec')
  s.summary     = "Watch and scale your dynos!"
  s.description = "Issues recurring 'pings' to your Heroku apps and scales dynos up or down depending on pre-defined rules"
  s.version     = "0.2.4"

  s.authors     = ["Black Square Media"]
  s.email       = "info@blacksquaremedia.com"
  s.homepage    = "https://github.com/bsm/heroku-scalr"

  s.require_path = 'lib'
  s.executables  = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.files        = `git ls-files`.split("\n")
  s.test_files   = `git ls-files -- {test,spec,features}/*`.split("\n")

  s.add_dependency "timers"
  s.add_dependency "heroku-api", '~> 0.3.12'

  s.add_development_dependency "rake"
  s.add_development_dependency "bundler"
  s.add_development_dependency "rspec"
  s.add_development_dependency "yard"
  s.add_development_dependency "webmock"
end
