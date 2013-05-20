require 'spec_helper'

describe Heroku::Scalr::Config do

  subject { described_class.new(fixture_path("config_a.rb")) }

  its(:apps)     { should be_instance_of(Array) }
  its(:apps)     { should have(2).items }
  its(:defaults) { should eq(api_key: "API_KEY") }

  it 'should merge defaults into app configurations' do
    app = subject.apps.first
    app.should be_instance_of(Heroku::Scalr::App)
    app.api_key.should == "API_KEY"
  end

end