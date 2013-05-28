require 'spec_helper'
require 'tempfile'

describe Logger do

  describe "#reopen" do

    let(:path) { Tempfile.new(["heroku-scalr", "logger"]).path }
    subject    { Logger.new(path) }

    it "should reopen files" do
      subject.info "Line 1"
      FileUtils.mv(path, "#{path}.1")
      subject.info "Line 2"
      subject.reopen.should be(subject)
      subject.info "Line 3"

      File.read("#{path}.1").should have(2).lines
      File.read(path).should have(1).lines
    end

    it "should skip streams" do
      logger = Logger.new(STDERR)
      logger.reopen.should be_nil
    end

  end

end