RedmineApp::Application.routes.draw do
  post 'helpdesk/inbound_email', to: 'helpdesk_inbound#receive', as: 'helpdesk_inbound_email'
  post 'helpdesk/escalate/:id', to: 'helpdesk_inbound#escalate', as: 'helpdesk_escalate_ticket'
  get 'projects/:project_id/helpdesk/settings', to: 'helpdesk_inbound#project_settings', as: 'project_helpdesk_settings'
  post 'projects/:project_id/helpdesk/settings', to: 'helpdesk_inbound#save_project_settings'
  get 'projects/:project_id/helpdesk/dashboard', to: 'helpdesk_inbound#dashboard', as: 'project_helpdesk_dashboard'
  post 'helpdesk/merge/:id', to: 'helpdesk_inbound#merge', as: 'helpdesk_merge_ticket'
  get 'helpdesk/public/:project_id', to: 'helpdesk_inbound#public_new', as: 'helpdesk_public_new'
  post 'helpdesk/public/:project_id', to: 'helpdesk_inbound#public_create', as: 'helpdesk_public_create'
end
