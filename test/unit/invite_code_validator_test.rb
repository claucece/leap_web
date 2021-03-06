require 'test_helper'

class InviteCodeValidatorTest < ActiveSupport::TestCase
  test "user should not be created with invalid invite code" do
    with_config invite_required: true do
    invalid_user = FactoryGirl.build(:user)

    assert !invalid_user.valid?
    end
  end

  test "user should be created with valid invite code" do
    valid_user = FactoryGirl.build(:user)
    valid_code = InviteCode.create
    valid_user.invite_code = valid_code.invite_code

    assert valid_user.valid?
  end

  test "trying to create a user with invalid invite code should add error" do
    with_config invite_required: true do
    invalid_user = FactoryGirl.build(:user, :invite_code => "a non-existent code")

    invalid_user.valid?

    errors = {invite_code: ["This is not a valid code"]}
    assert_equal errors, invalid_user.errors.messages
    end
  end
end