require "test_helper"

class DialectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @dialect = dialects(:one)
  end

  test "should get index" do
    get dialects_url
    assert_response :success
  end

  test "should get new" do
    get new_dialect_url
    assert_response :success
  end

  test "should create dialect" do
    assert_difference("Dialect.count") do
      post dialects_url, params: { dialect: { language_id: @dialect.language_id, name: @dialect.name } }
    end

    assert_redirected_to dialect_url(Dialect.last)
  end

  test "should show dialect" do
    get dialect_url(@dialect)
    assert_response :success
  end

  test "should get edit" do
    get edit_dialect_url(@dialect)
    assert_response :success
  end

  test "should update dialect" do
    patch dialect_url(@dialect), params: { dialect: { language_id: @dialect.language_id, name: @dialect.name } }
    assert_redirected_to dialect_url(@dialect)
  end

  test "should destroy dialect" do
    assert_difference("Dialect.count", -1) do
      delete dialect_url(@dialect)
    end

    assert_redirected_to dialects_url
  end
end
