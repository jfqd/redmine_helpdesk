namespace :helpdesk do
  namespace :localdb do
    db_label = 'helpdesk-db'

    def get_env ()
      db_name = 'redmine'
      db_host = 'localhost'
      db_user = 'root'

      db_adapter = ENV['DATABASE_ADAPTER']
      case db_adapter
      when "mysql"
        env = "-e MYSQL_DATABASE=#{db_name} "\
              "-e MYSQL_ALLOW_EMPTY_PASSWORD=yes "
      when "postgresql"
        env = "-e POSTGRES_DB=#{db_name} "\
              "-e POSTGRES_USER=#{db_user} "\
      when "postgresql_ext"
        env = "-e POSTGRES_DB=#{db_name} "\
              "-e POSTGRES_USER=#{db_user}"
      else
        raise StandardError.new "Cannot start local db"
      end
      env
    end

    def get_port ()
      db_adapter = ENV['DATABASE_ADAPTER']
      case db_adapter
      when "mysql"
        port = 3306
      when "postgresql"
        port = 5432
      when "postgresql_ext"
        port = 5432
      else
        raise StandardError.new "Cannot start local db"
      end
      port
    end

    def get_image ()
      db_adapter = ENV['DATABASE_ADAPTER']
      case db_adapter
      when "mysql"
        image = "mysql"
      when "postgresql"
        image = "postgres"
      when "postgresql_ext"
        image = "postgres"
      else
        raise StandardError.new "Cannot start local db"
      end
      image
    end

    task :start => :stop do
      env = get_env()
      port = get_port()
      image = get_image()
      cmd = "docker run -d --name #{db_label} "\
              "--net=host "\
              "#{env} "\
              "#{image}"
      puts cmd
      system(cmd)
    end

    task :stop do
      system("docker stop #{db_label}")
      system("docker rm #{db_label}")
    end
  end
end
