namespace :redmine do
  namespace :helpdesk do
    desc 'Fetch incoming emails via IMAP for all Helpdesk-enabled projects'
    task :fetch_imap => :environment do
      settings = Setting.plugin_redmine_helpdesk || {}
      settings.each do |key, cfg|
        next unless key.start_with?('project_') && cfg.is_a?(Hash) && cfg['enabled'] == '1'
        next if cfg['imap_host'].blank? || cfg['imap_username'].blank?

        proj_id = key.sub('project_', '').to_i
        project = Project.find_by(id: proj_id)
        next unless project

        Redmine::IMAP.check(
          {
            host: cfg['imap_host'],
            port: (cfg['imap_port'] || 993).to_i,
            ssl: true,
            username: cfg['imap_username'],
            password: cfg['imap_password'].to_s,
            folder: 'INBOX'
          },
          {
            issue: { project: project.identifier },
            unknown_user: 'accept',
            no_permission_check: '1'
          }
        )
      end
    end
  end
end
