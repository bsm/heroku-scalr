require 'spec_helper'

describe Heroku::Scalr::Runner do

  subject do
    described_class.new fixture_path("config_a.rb")
  end

  its(:config) { should be_instance_of(Heroku::Scalr::Config) }
  its(:timers) { should be_instance_of(Timers) }
  its(:timers) { should have(2).items }

end