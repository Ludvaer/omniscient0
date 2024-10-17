require "application_system_test_case"

class DescriptionsTest < ApplicationSystemTestCase
  setup do
    @description = descriptions(:one)
  end

  test "visiting the index" do
    visit descriptions_url
    assert_selector "h1", text: "Descriptions"
  end

  test "should create description" do
    visit descriptions_url
    click_on "New description"

    fill_in "Text", with: @description.text
    click_on "Create Description"

    assert_text "Description was successfully created"
    click_on "Back"
  end

  test "should update Description" do
    visit description_url(@description)
    click_on "Edit this description", match: :first

    fill_in "Text", with: @description.text
    click_on "Update Description"

    assert_text "Description was successfully updated"
    click_on "Back"
  end

  test "should destroy Description" do
    visit description_url(@description)
    click_on "Destroy this description", match: :first

    assert_text "Description was successfully destroyed"
  end
end
