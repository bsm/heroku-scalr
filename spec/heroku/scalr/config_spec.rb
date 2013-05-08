require 'spec_helper'

describe Heroku::Scalr::Config do

  subject { described_class.new(fixture_path("config_a.rb")) }

  its(:apps)     { should be_a(Array) }
  its(:defaults) { should eq({:api_key=>"API_KEY"}) }

  it "has to contain App object" do
    subject.apps[0].should be_instance_of(Heroku::Scalr::App)
  end
end