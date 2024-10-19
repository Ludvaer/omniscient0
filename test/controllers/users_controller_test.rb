require "test_helper"
require 'nokogiri'

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user_params = controller_signup 'user_test'
    @user = User.find_by(name: @user_params[:name])
  end

  test "should get index" do
    get users_url(default_test_url_options)
    assert_response :success
  end

  test "should get new" do
    get new_user_url(default_test_url_options)
    assert_response :success
  end

  test "should create user" do
    user_params = {}
    assert_difference("User.count") do
      user_params = controller_signup 'signup_test'
    end
    assert_redirected_to user_url(User.find_by(name: user_params[:name]))
  end

  test "should show user" do
     get user_url(@user)
     assert_response :success
  end

  test "should get edit" do
    get edit_user_url(@user)
    assert_response :success
  end

  test "should update user" do
    get edit_user_url(@user)
    pass = standart_pass 'edit_test'
    mail = standart_mail 'edit_test'
    patch user_url(@user), params: { user: {salt: user_salt, email: mail, name: @user_params[:name], password: pass, password_confirmation: pass, old_password: @user_params[:password] } }
    assert_redirected_to user_url(@user)
    delete logout_path
    get login_path(default_test_url_options)
    post login_path, params: {  user: { name: @user_params[:name], password: pass, salt: user_salt }, login: {remember: true}, redirect_url: user_url(@user) }
    assert_redirected_to user_url(@user)
    user = @user.reload
    assert_equal(user[:email], mail)
  end

  test "should destroy user" do
    assert_difference("User.count", -1) do
      delete user_url(@user)
    end
    assert_redirected_to users_url
    assert !User.where(id: @user.id).exists?
  end
end
