# require "test_helper"
#
# class PickWordInSetsControllerTest < ActionDispatch::IntegrationTest
#   setup do
#     @pick_word_in_set = pick_word_in_sets(:one)
#   end
#
#   test "should get index" do
#     get pick_word_in_sets_url
#     assert_response :success
#   end
#
#   test "should get new" do
#     get new_pick_word_in_set_url
#     assert_response :success
#   end
#
#   test "should create pick_word_in_set" do
#     assert_difference("PickWordInSet.count") do
#       post pick_word_in_sets_url, params: { pick_word_in_set: { correct_id: @pick_word_in_set.correct_id, picked_id: @pick_word_in_set.picked_id, set_id: @pick_word_in_set.set_id, version: @pick_word_in_set.version } }
#     end
#
#     assert_redirected_to pick_word_in_set_url(PickWordInSet.last)
#   end
#
#   test "should show pick_word_in_set" do
#     get pick_word_in_set_url(@pick_word_in_set)
#     assert_response :success
#   end
#
#   test "should get edit" do
#     get edit_pick_word_in_set_url(@pick_word_in_set)
#     assert_response :success
#   end
#
#   test "should update pick_word_in_set" do
#     patch pick_word_in_set_url(@pick_word_in_set), params: { pick_word_in_set: { correct_id: @pick_word_in_set.correct_id, picked_id: @pick_word_in_set.picked_id, set_id: @pick_word_in_set.set_id, version: @pick_word_in_set.version } }
#     assert_redirected_to pick_word_in_set_url(@pick_word_in_set)
#   end
#
#   test "should destroy pick_word_in_set" do
#     assert_difference("PickWordInSet.count", -1) do
#       delete pick_word_in_set_url(@pick_word_in_set)
#     end
#
#     assert_redirected_to pick_word_in_sets_url
#   end
# end
