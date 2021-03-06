require 'test_helper'

class DeferralsControllerTest < ActionDispatch::IntegrationTest

  setup do
    sign_in_as users(:chris)
    @activity = activities(:open_wp)
    @fault = faults(:fault_deferral)
    @open_deferral_fault = faults(:fault_deferral_two)
    @deferral = corrective_actions(:ca_other_in_wp_deferral)
  end

  test "should get new" do
    get new_activity_deferral_path(@activity, fault_id: @fault.id)
    assert_response :success
  end

  test "should create deferral without product if defer_reason is not no_parts" do
    assert_difference('CorrectiveAction.count') do
      post activity_deferrals_path(@activity), params: { deferral: { fault_id: @open_deferral_fault.id, job_started_at: Time.now, performed_by_id: @deferral.performed_by_id, maintenance_action_id: @deferral.maintenance_action_id, logbook_text: "test", document_reference: "test", opdef: 'true', defer_reason_id: @deferral.defer_reason_id } }
    end

    assert_redirected_to [@activity, @open_deferral_fault]
  end

  test "should create deferral with product if defer_reason is no_parts" do
    assert_difference('CorrectiveAction.count') do
      post activity_deferrals_path(@activity), params: { deferral: { fault_id: @open_deferral_fault.id, job_started_at: Time.now, performed_by_id: @deferral.performed_by_id, maintenance_action_id: @deferral.maintenance_action_id, logbook_text: "test", document_reference: "test", opdef: 'true', defer_reason_id: defer_reasons(:no_parts).id, product_id: products(:single_usb).id } }
    end

    assert_redirected_to [@activity, @open_deferral_fault]
  end

  test "should show deferral" do
    get activity_deferral_path(@activity, @deferral, fault_id: @fault.id)
    assert_response :success
  end

  test "should edit deferral" do
    get edit_activity_deferral_path(@activity, @deferral)
    assert_response :success
  end

  test "should update deferral" do
    patch activity_deferral_path(@activity, @deferral), params: { deferral: { logbook_text: "sample text" } }
    assert_redirected_to [@activity, @deferral.fault]
  end

  test "should destroy deferral" do
    assert_difference('CorrectiveAction.count', -1) do
      delete activity_deferral_path(@activity, @deferral)
    end

    assert_redirected_to [@activity, @fault]
  end

  test "fault attributes are getting updated after successful create" do
    assert_difference('CorrectiveAction.count') do
      post activity_deferrals_path(@activity), params: { deferral: { fault_id: @open_deferral_fault.id, job_started_at: Time.now, performed_by_id: @deferral.performed_by_id, maintenance_action_id: @deferral.maintenance_action_id, logbook_text: "test", document_reference: "test", opdef: 'true', defer_reason_id: @deferral.defer_reason_id } }
    end

    assert_redirected_to [@activity, @open_deferral_fault]

    @open_deferral_fault.reload
    assert @open_deferral_fault.state == 'deferred'
    assert @open_deferral_fault.defer_reason == @deferral.defer_reason
  end

  test "fault attributes are getting updated after successful update" do
    patch activity_deferral_path(@activity, @deferral), params: { deferral: { defer_reason_id: defer_reasons(:no_parts).id, product_id: products(:single_usb).id } }
    assert_redirected_to [@activity, @deferral.fault]

    @deferral.reload
    assert @deferral.fault.defer_reason == @deferral.defer_reason
  end

  test "cannot defer if fault is already closed or deferred_closed" do
    @fault = faults(:fault_actioned_and_raised_in_wp)
    @fault_ca = corrective_actions(:ca_actioned_and_raised_in_wp)

    patch activity_fault_resolutions_path(@activity, fault_id: @fault.id), params: { fault_resolution: { state: 'true', resolving_corrective_action_id: @fault_ca.id } }
    assert_redirected_to [@activity, @fault]

    @fault.reload
    assert @fault.state == 'closed'
    assert @fault.resolving_corrective_action_id == @fault_ca.id

    assert_no_difference('CorrectiveAction.count') do
      post activity_deferrals_path(@activity), params: { deferral: { fault_id: @fault.id, job_started_at: @deferral.job_started_at, performed_by_id: @deferral.performed_by_id, maintenance_action_id: @deferral.maintenance_action_id, logbook_text: "test", document_reference: "test", opdef: 'true', defer_reason_id: @deferral.defer_reason_id } }
    end
  end

  test "cannot re-defer if fault is already deferred by same activity" do
    assert_no_difference('CorrectiveAction.count') do
      post activity_deferrals_path(@activity), params: { deferral: { fault_id: @fault.id, job_started_at: @deferral.job_started_at, performed_by_id: @deferral.performed_by_id, maintenance_action_id: @deferral.maintenance_action_id, logbook_text: "test", document_reference: "test", opdef: 'true', defer_reason_id: @deferral.defer_reason_id } }
    end
  end

end
