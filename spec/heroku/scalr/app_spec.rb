require 'spec_helper'

describe Heroku::Scalr::App do

  subject    { described_class.new('name', api_key: 'key') }

  def mock_response(status, body)
    mock "APIResponse", status: status, headers: {}, body: body
  end

  its(:name)            { should == 'name' }  
  its(:http)            { should be_instance_of(Excon::Connection) }
  its(:api)             { should be_instance_of(Heroku::API) }

  its(:interval)        { should be(30) }
  its(:min_dynos)       { should be(1) }
  its(:max_dynos)       { should be(2) }
  its(:wait_low)        { should be(10) }
  its(:wait_high)       { should be(100) }
  its(:min_frequency)   { should be(60) }
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

  describe "scale!" do

    context "when low wait time" do
      before do
        subject.api.stub get_app: mock_response(200, { "dynos" => 2 }), put_dynos: mock_response(200, "")
      end

      let! :app_request do
        stub_request(:get, "http://name.herokuapp.com/robots.txt").        
          to_return(body: "", headers: { "X-Heroku-Queue-Wait" => 3 })
      end

      it "should skip if scaled too recently" do
        subject.instance_variable_set :@last_scaled_at, Time.now
        subject.scale!.should be_nil
      end

      it "should query the queue wait time from the app" do
        subject.scale!.should == 1
        app_request.should have_been_made
      end
      
      it "should check current number of dynos" do
        subject.api.should_receive(:get_app).with("name").and_return mock_response(200, { "dynos" => 2 })
        subject.scale!.should == 1
      end

      it "should update dynos" do
        subject.api.should_receive(:put_dynos).with("name", 1).and_return mock_response(200, "")
        subject.scale!.should == 1
      end

      it "should not scale down if min number of dynos is reached" do
        subject.api.should_receive(:get_app).with("name").and_return mock_response(200, { "dynos" => 1 })
        subject.api.should_not_receive(:put_dynos)
        subject.scale!.should be_nil
      end
    end

    context "when high wait time" do
      before do
        subject.api.stub get_app: mock_response(200, { "dynos" => 1 }), put_dynos: mock_response(200, "")
      end

      let! :app_request do
        stub_request(:get, "http://name.herokuapp.com/robots.txt").        
          to_return(body: "", headers: { "X-Heroku-Queue-Wait" => 101 })
      end

      it "should update dynos" do
        subject.api.should_receive(:get_app).with("name").and_return mock_response(200, { "dynos" => 1 })
        subject.scale!.should == 2
      end

      it "should not scale up if max number of dynos is reached" do
        subject.api.should_receive(:get_app).with("name").and_return mock_response(200, { "dynos" => 2 })
        subject.api.should_not_receive(:put_dynos)
        subject.scale!.should be_nil
      end
    end
  end

end