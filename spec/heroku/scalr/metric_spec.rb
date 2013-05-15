require 'spec_helper'

describe Heroku::Scalr::Metric do

  let(:app) { Heroku::Scalr::App.new('name', api_key: 'key') }

  it 'should create metric instances' do
    described_class.new(:wait, app).should be_instance_of(described_class::Wait)
    described_class.new("wait", app).should be_instance_of(described_class::Wait)
    described_class.new(:ping, app).should be_instance_of(described_class::Ping)
    described_class.new(:any, app).should be_instance_of(described_class::Ping)
  end

end

describe Heroku::Scalr::Metric::Abstract do

  let!(:http_request) { stub_request(:head, "http://name.herokuapp.com/robots.txt") }
  let(:app) { Heroku::Scalr::App.new('name', api_key: 'key') }
  subject   { described_class.new(app) }

  its(:by)  { should == 0 }

  it "should perform HTTP pings" do
    res = subject.send(:http_get)
    res.status.should == 200
    http_request.should have_been_made
  end

  it "should catch HTTP errors" do
    Excon.stub!(:head).and_raise(Excon::Errors::Timeout)
    res = subject.send(:http_get)
    res.status.should == 598
  end

end

describe Heroku::Scalr::Metric::Ping do

  let(:app)           { Heroku::Scalr::App.new('name', api_key: 'key') }
  let(:ping_time)     { 0.250 }
  let!(:http_request) { stub_request(:head, "http://name.herokuapp.com/robots.txt") }

  subject   { described_class.new(app) }
  before    { Benchmark.stub(:realtime).and_yield.and_return(ping_time) }

  describe "low ping time" do
    let(:ping_time) { 0.150 }

    it 'should scale down' do
      subject.by.should == -1
      http_request.should have_been_made
    end
  end

  describe "high ping time" do
    let(:ping_time) { 0.550 }

    it 'should scale up' do
      subject.by.should == 1
      http_request.should have_been_made
    end
  end

  describe "normal ping time" do
    it 'should not scale' do
      subject.by.should == 0
      http_request.should have_been_made
    end
  end

  describe "failed requests" do

    let! :http_request do
      stub_request(:head, "http://name.herokuapp.com/robots.txt").to_return(status: 404)
    end

    it 'should not scale' do
      Heroku::Scalr.logger.should_receive(:warn)
      subject.by.should == 0
      http_request.should have_been_made
    end

  end

end

describe Heroku::Scalr::Metric::Wait do

  let(:app) { Heroku::Scalr::App.new('name', api_key: 'key') }
  subject   { described_class.new(app) }

  describe "low queue wait time" do

    let! :http_request do
      stub_request(:head, "http://name.herokuapp.com/robots.txt").to_return(body: "", headers: { "X-Heroku-Queue-Wait" => 3 })
    end

    it 'should scale down' do
      subject.by.should == -1
      http_request.should have_been_made
    end

  end

  describe "high queue wait time" do

    let! :http_request do
      stub_request(:head, "http://name.herokuapp.com/robots.txt").to_return(body: "", headers: { "X-Heroku-Queue-Wait" => 300 })
    end

    it 'should scale up' do
      subject.by.should == 1
      http_request.should have_been_made
    end

  end

  describe "normal queue wait time" do

    let! :http_request do
      stub_request(:head, "http://name.herokuapp.com/robots.txt").to_return(body: "", headers: { "X-Heroku-Queue-Wait" => 20 })
    end

    it 'should not scale' do
      subject.by.should == 0
      http_request.should have_been_made
    end

  end

  describe "queue wait unretrievable" do

    let! :http_request do
      stub_request(:head, "http://name.herokuapp.com/robots.txt")
    end

    it 'should not scale' do
      Heroku::Scalr.logger.should_receive(:warn)
      subject.by.should == 0
      http_request.should have_been_made
    end

  end

end