require 'spec_helper'

describe Heroku::Scalr::App do

  subject    { described_class.new('name', api_key: 'key', max_dynos: 3, heat_freq: 30) }

  def mock_response(status, body)
    mock "APIResponse", status: status, headers: {}, body: body
  end

  its(:name)            { should == 'name' }
  its(:url)             { should == 'http://name.herokuapp.com/robots.txt' }
  its(:api_key)         { should == 'key' }
  its(:metric)          { should be_instance_of(Heroku::Scalr::Metric::Ping) }

  its(:interval)        { should be(30) }
  its(:min_dynos)       { should be(1) }
  its(:max_dynos)       { should be(3) }
  its(:wait_low)        { should be(10) }
  its(:wait_high)       { should be(100) }
  its(:ping_low)        { should be(200) }
  its(:ping_high)       { should be(500) }
  its(:heat_freq)       { should be(30) }
  its(:cool_freq)       { should be(180) }
  its(:last_scaled_at)  { should == Time.at(0)}


  describe "failures" do
    it "should raise error when there's no API key" do
      expect { described_class.new("name") }.to raise_error(ArgumentError)
    end

    it "should raise error when min_dynos < 1" do
      expect { described_class.new("name", {:api_key => 'key', :min_dynos => 0}) }.to raise_error(ArgumentError)
    end

    it "should raise error when max_dynos < 1" do
      expect { described_class.new("name", {:api_key => 'key', :max_dynos => 0}) }.to raise_error(ArgumentError)
    end

    it "should raise error when interval < 10" do
      expect { described_class.new("name", {:api_key => 'key', :interval => 9}) }.to raise_error(ArgumentError)
    end
  end

  describe "scaling" do

    let :mock_api do
      mock "Heroku::API", get_app: mock_response(200, { "dynos" => 2 }), post_ps_scale: mock_response(200, "")
    end

    before do
      Heroku::API.stub new: mock_api
      subject.metric.stub by: -1
    end

    it "should skip if scaled too recently" do
      subject.instance_variable_set :@last_scaled_at, Time.now
      subject.scale!.should be_nil
    end

    it "should log errors" do
      mock_api.should_receive(:get_app).and_raise(RuntimeError, "API Error")
      Heroku::Scalr.logger.should_receive(:error)
      subject.scale!.should be_nil
    end

    it "should determine scale through metric" do
      subject.metric.should_receive(:by).and_return(-1)
      subject.scale!.should == 1
    end

    it "should skip when there is no need" do
      subject.metric.should_receive(:by).and_return(0)
      subject.scale!.should be_nil
    end

    it "should check current number of dynos" do
      mock_api.should_receive(:get_app).with("name").and_return mock_response(200, { "dynos" => 2 })
      subject.scale!.should == 1
    end

    context "down" do

      it "should return the new number of dynos" do
        subject.instance_variable_set :@last_scaled_at, (Time.now - 185)
        mock_api.should_receive(:post_ps_scale).with("name", "web", 1).and_return mock_response(200, "")
        subject.scale!.should == 1
      end

      it "should skip if min number of dynos reached" do
        mock_api.should_receive(:get_app).with("name").and_return mock_response(200, { "dynos" => 1 })
        mock_api.should_not_receive(:post_ps_scale)
        subject.scale!.should be_nil
      end

      it "should skip if scaled too recently" do
        subject.instance_variable_set :@last_scaled_at, (Time.now - 175)
        mock_api.should_not_receive(:post_ps_scale)
        subject.scale!.should be_nil
      end

    end

    context "up" do

      before { subject.metric.stub by: 1 }

      it "should return the new number of dynos" do
        subject.instance_variable_set :@last_scaled_at, (Time.now - 35)
        mock_api.should_receive(:post_ps_scale).with("name", "web", 3).and_return mock_response(200, "")
        subject.scale!.should == 3
      end

      it "should skip if max number of dynos reached" do
        mock_api.should_receive(:get_app).with("name").and_return mock_response(200, { "dynos" => 3 })
        mock_api.should_not_receive(:post_ps_scale)
        subject.scale!.should be_nil
      end

      it "should skip if scaled too recently" do
        subject.instance_variable_set :@last_scaled_at, (Time.now - 25)
        mock_api.should_not_receive(:post_ps_scale)
        subject.scale!.should be_nil
      end

    end

  end
end