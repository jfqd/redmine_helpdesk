require File.expand_path('../../test_helper', __FILE__)

class HelpdeskEnterpriseTest < ActiveSupport::TestCase
  def test_plugin_registered_as_enterprise_v1
    plugin = Redmine::Plugin.find(:redmine_helpdesk)
    assert_not_nil plugin
    assert_equal '1.0.0', plugin.version
    assert_equal 'Arean Narrayan', plugin.author
  end

  def test_inbound_controller_actions_defined
    actions = HelpdeskInboundController.action_methods
    %w[receive escalate merge dashboard reports project_settings save_project_settings public_new public_create public_status csat].each do |act|
      assert_includes actions, act
    end
  end
end
