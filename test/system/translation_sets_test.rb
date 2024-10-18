require "application_system_test_case"

class TranslationSetsTest < ApplicationSystemTestCase
  setup do
    @translation_set = translation_sets(:one)
  end

  test "visiting the index" do
    visit translation_sets_url
    assert_selector "h1", text: "Translation sets"
  end

  test "should create translation set" do
    visit translation_sets_url
    click_on "New translation set"

    click_on "Create Translation set"

    assert_text "Translation set was successfully created"
    click_on "Back"
  end

  test "should update Translation set" do
    visit translation_set_url(@translation_set)
    click_on "Edit this translation set", match: :first

    click_on "Update Translation set"

    assert_text "Translation set was successfully updated"
    click_on "Back"
  end

  test "should destroy Translation set" do
    visit translation_set_url(@translation_set)
    click_on "Destroy this translation set", match: :first

    assert_text "Translation set was successfully destroyed"
  end
end
