require File.dirname(__FILE__) + "/../../test_helper"
require 'adhearsion/voip/yate/yate_interface'

context "The YateMessage protocol parser" do
  
  include YateTestHelper  
  
  test "A message needing unescaping" do
    line = "%%<message:myapp55251:true:app.job:Restart required:path=/bin%Z/usr/bin%Z/usr/local/bin"
    parse_protocol_line(line).should == %w[
      message myapp55251 true app.job Restart\ required path=/bin:/usr/bin:/usr/local/bin
    ]
  end
  
  test "should ignore trailing newlines" do
    line = "%%<message:myapp55251:true:app.job:Restart required:path=/bin%Z/usr/bin%Z/usr/local/bin\n"
    parse_protocol_line(line).each do |segment|
      segment.should.not.include "\n"
    end
  end
  
  test "the from_protocol_text method should return a YateMessage" do
    line = "%%<message:myapp55251:true:app.job:Restart required:path=/bin%Z/usr/bin%Z/usr/local/bin\n"
    message_from_protocol_text(line).should.be.kind_of(Adhearsion::VoIP::Yate::YateMessage)
  end
  
end

context "Handling a new call" do
  
  include YateTestHelper
  
  test 'it should instantiate a new YateCall when receive_line gets a new call message' do
    the_following_code {
      flexmock(Adhearsion::VoIP::Yate::YateCall).should_receive(:new).once.and_throw :new_yate_call
      interface = new_yate_interface
      # TOOD: Fully implement this.
    }.should.throw :new_yate_call
  end
  test 'it should start a new Thread' do
    flexmock(Thread).should_receive(:new).once.and_yield
    interface = new_yate_interface
    flexmock(interface.send(:instance_variable_get, :@thread_group)).should_receive(:add).once.and_return
    flexmock(interface).should_receive(:handle_call).once.and_return
    interface.spawn_call_handler_for flexmock("mock YateCall")
  end
  test "#handle_thread"
end

context "Handling messages" do
  test "should recover from exceptions raised"
end

context "Sending commands" do
  
  include YateTestHelper
  
  test "installing a simple 'test' handler with priority" do
    expected = "%%<install:50:test\n"
    interface = new_yate_interface
    flexmock(interface).should_receive(:send_data).once.with expected
    interface.send_message 'test', :action_id => "install", :priority => 50
  end
  
  test "installing a simple engine.timer without a priority" do
    expected = "%%<install::engine.timer\n"
    interface = new_yate_interface
    flexmock(interface).should_receive(:send_data).once.with expected
    interface.send_message "engine.timer", :action_id => "install"
  end
end

BEGIN {
  module YateTestHelper
    def new_yate_interface
      Adhearsion::VoIP::Yate::YateInterface.new 'does_not_matter'
    end
    
    def parse_protocol_line(line)
      Adhearsion::VoIP::Yate::YateMessage.parse_line line
    end
    
    def message_from_protocol_text(text)
      Adhearsion::VoIP::Yate::YateMessage.from_protocol_text text
    end
  end
}