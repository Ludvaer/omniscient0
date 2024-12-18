require "test_helper"

class MixTrainControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get mix_train_new_url
    assert_response :success
  end

  test "should get update" do
    get mix_train_update_url
    assert_response :success
  end
end
