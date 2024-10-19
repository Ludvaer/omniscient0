# require "test_helper"
#
# class TranslationSetsControllerTest < ActionDispatch::IntegrationTest
#   setup do
#     @translation_set = translation_sets(:one)
#   end
#
#   test "should get index" do
#     get translation_sets_url
#     assert_response :success
#   end
#
#   test "should get new" do
#     get new_translation_set_url
#     assert_response :success
#   end
#
#   test "should create translation_set" do
#     assert_difference("TranslationSet.count") do
#       post translation_sets_url, params: { translation_set: {  } }
#     end
#
#     assert_redirected_to translation_set_url(TranslationSet.last)
#   end
#
#   test "should show translation_set" do
#     get translation_set_url(@translation_set)
#     assert_response :success
#   end
#
#   test "should get edit" do
#     get edit_translation_set_url(@translation_set)
#     assert_response :success
#   end
#
#   test "should update translation_set" do
#     patch translation_set_url(@translation_set), params: { translation_set: {  } }
#     assert_redirected_to translation_set_url(@translation_set)
#   end
#
#   test "should destroy translation_set" do
#     assert_difference("TranslationSet.count", -1) do
#       delete translation_set_url(@translation_set)
#     end
#
#     assert_redirected_to translation_sets_url
#   end
# end
