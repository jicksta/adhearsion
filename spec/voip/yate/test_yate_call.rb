require File.join(File.dirname(__FILE__), *%w[.. .. test_helper])
require 'adhearsion/voip/yate/yate_call'

context "YateCall variable coercions" do
  test "should convert booleans to actual booleans" do
    Adhearsion::VoIP::Yate::YateCall.coerce_variables("foobar" => "true").should == {"foobar" => true}
  end
end