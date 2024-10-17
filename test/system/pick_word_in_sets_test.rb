require "application_system_test_case"

class PickWordInSetsTest < ApplicationSystemTestCase
  setup do
    @pick_word_in_set = pick_word_in_sets(:one)
  end

  test "visiting the index" do
    visit pick_word_in_sets_url
    assert_selector "h1", text: "Pick word in sets"
  end

  test "should create pick word in set" do
    visit pick_word_in_sets_url
    click_on "New pick word in set"

    fill_in "Correct", with: @pick_word_in_set.correct_id
    fill_in "Picked", with: @pick_word_in_set.picked_id
    fill_in "Set", with: @pick_word_in_set.set_id
    fill_in "Version", with: @pick_word_in_set.version
    click_on "Create Pick word in set"

    assert_text "Pick word in set was successfully created"
    click_on "Back"
  end

  test "should update Pick word in set" do
    visit pick_word_in_set_url(@pick_word_in_set)
    click_on "Edit this pick word in set", match: :first

    fill_in "Correct", with: @pick_word_in_set.correct_id
    fill_in "Picked", with: @pick_word_in_set.picked_id
    fill_in "Set", with: @pick_word_in_set.set_id
    fill_in "Version", with: @pick_word_in_set.version
    click_on "Update Pick word in set"

    assert_text "Pick word in set was successfully updated"
    click_on "Back"
  end

  test "should destroy Pick word in set" do
    visit pick_word_in_set_url(@pick_word_in_set)
    click_on "Destroy this pick word in set", match: :first

    assert_text "Pick word in set was successfully destroyed"
  end
end
