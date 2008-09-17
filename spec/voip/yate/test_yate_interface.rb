require File.dirname(__FILE__) + "/../../test_helper"
require 'adhearsion/voip/yate/yate_interface'

context "The YateMessage protocol parser" do
  
  test "A message needing unescaping" do
    line = "%%<message:myapp55251:true:app.job:Restart required:path=/bin%Z/usr/bin%Z/usr/local/bin"
    Adhearsion::VoIP::Yate::YateMessage.parse_line(line).should == %w[
      message myapp55251 true app.job Restart\ required path=/bin:/usr/bin:/usr/local/bin
    ]
  end
  
  test "should ignore trailing newlines" do
    line = "%%<message:myapp55251:true:app.job:Restart required:path=/bin%Z/usr/bin%Z/usr/local/bin\n"
    Adhearsion::VoIP::Yate::YateMessage.parse_line(line).each do |segment|
      segment.should.not.include "\n"
    end
  end
  
  test "the from_protocol_text method should return a YateMessage" do
    line = "%%<message:myapp55251:true:app.job:Restart required:path=/bin%Z/usr/bin%Z/usr/local/bin\n"
    Adhearsion::VoIP::Yate::YateMessage.from_protocol_text(line).should.be.kind_of(Adhearsion::VoIP::Yate::YateMessage)
  end
  
end

context "Handling a new call" do
  test 'it should instantiate a new YateCall'
  test 'it should start a new Thread'
  test "#handle_thread"
end

context "Sending commands" do
  test "installing a simple 'test' handler with priority" do
    expected = "%%<install:50:test\n"
    interface = Adhearsion::VoIP::Yate::YateInterface.new 'wtf'
    flexmock(interface).should_receive(:send_data).once.with expected
    interface.send_message 'test', :action_id => "install", :priority => 50
  end
  
  test "installing a simple engine.timer without a priority" do
    expected = "%%<install::engine.timer\n"
    interface = Adhearsion::VoIP::Yate::YateInterface.new 'wtf'
    flexmock(interface).should_receive(:send_data).once.with expected
    interface.send_message "engine.timer", :action_id => "install"
  end
end