require 'test_helper'

class SessionsControllerTest < ActionController::TestCase

  def setup
    @user = stub :login => "me", :id => 123
    @client_hex = 'a123'
    @client_rnd = @client_hex.hex
    @server_hex = 'b123'
    @server_rnd = @server_hex.hex
    @server_rnd_exp = 'e123'.hex
    @salt = 'stub user salt'
    @server_handshake = stub :aa => @client_rnd, :bb => @server_rnd, :b => @server_rnd_exp
    @server_auth = 'adfe'
  end

  test "should get login screen" do
    get :new
    assert_response :success
  end

  test "should perform handshake" do
    @user.expects(:initialize_auth).
      with(@client_rnd).
      returns(@server_handshake)
    @server_handshake.expects(:to_json).
     returns({'B' => @server_hex, 'salt' => @salt}.to_json)
    User.expects(:find_by_param).with(@user.login).returns(@user)
    post :create, :login => @user.login, 'A' => @client_hex
    assert_equal @server_handshake, session[:handshake]
    assert_response :success
    assert_json_response :B => @server_hex, :salt => @salt
  end

  test "should report user not found" do
    unknown = "login_that_does_not_exist"
    User.expects(:find_by_param).with(unknown).raises(RECORD_NOT_FOUND)
    post :create, :login => unknown
    assert_response :success
    assert_json_response :errors => {"login" => ["unknown user"]}
  end

  test "should authorize" do
    session[:handshake] = @server_handshake
    @server_handshake.expects(:authenticate!).
      with(@client_rnd).
      returns(@user)
    @server_handshake.expects(:to_json).
      returns({:M2 => @server_auth}.to_json)
    post :update, :id => @user.login, :client_auth => @client_hex
    assert_nil session[:handshake]
    assert_json_response :M2 => @server_auth
    assert_equal @user.id, session[:user_id]
  end

  test "should report wrong password" do
    session[:handshake] = @server_handshake
    @server_handshake.expects(:authenticate!).
      with(@client_rnd).
      raises(WRONG_PASSWORD)
    post :update, :id => @user.login, :client_auth => @client_hex
    assert_nil session[:handshake]
    assert_nil session[:user_id]
    assert_json_response :errors => {"password" => ["wrong password"]}
  end

  test "logout should reset sessions user_id" do
    session[:user_id] = "set"
    delete :destroy
    assert_nil session[:user_id]
    assert_response :redirect
    assert_redirected_to root_url
  end

end
