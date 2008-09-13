require File.dirname(__FILE__) + "/../../test_helper"
require 'adhearsion/voip/yate/yate_interface'

context "The protocol parser" do
  test "A message needing unescaping" do
    line = "%%<message:myapp55251:true:app.job:Restart required:path=/bin%Z/usr/bin%Z/usr/local/bin"
    Adhearsion::VoIP::Yate::YateInterface.parse_line(line).should == %w[
      message myapp55251 true app.job Restart\ required path=/bin:/usr/bin:/usr/local/bin
    ]
  end
end

context "Handling a new call" do
  test 'it should instantiate a new YateCall'
  test 'it should start a new Thread'
  test "#handle_thread"
end

context "Sending commands" do
  test "installing a simple 'test' handler with priority" do
    expected = "%%>install:50:test\n"
    interface = Adhearsion::VoIP::Yate::YateInterface.new 'wtf'
    flexmock(interface).should_receive(:send_data).once.with expected
    interface.send_message "install", :handler => "test", :priority => 50
  end
  
  test "installing a simple engine.timer" do
    expected = "%%>install::engine.timer\n"
    interface = Adhearsion::VoIP::Yate::YateInterface.new 'wtf'
    flexmock(interface).should_receive(:send_data).once.with expected
    interface.send_message "install", :handler => "engine.timer"
  end
end