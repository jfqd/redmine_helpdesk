require 'fileutils'

namespace :helpdesk do
  namespace :redmine do
    plugin_root = File.expand_path('../../../', __FILE__)
    redmine_path = "#{plugin_root}/test/app"
    tmp_dir = "#{plugin_root}/tmp"

    redmine_source_url = "http://www.redmine.org/releases"
    redmine_version = ENV['REDMINE_VERSION'] || "3.2.0"
    redmine_name = "redmine-#{redmine_version}"
    redmine_package = "#{redmine_name}.tar.gz"
    redmine_url = "#{redmine_source_url}/#{redmine_package}"

    version = redmine_version.split(".")
    major = version[0]
    minor = version[1]
    patch = version[2]

    task :install => [ :remove,
                       :print_env,
                       :download_tarball,
                       :extract_tarball,
                       :configure_db,
                       :link_plugin,
                       :print_result ]

    task :print_env do
      if ENV['DATABASE_ADAPTER'].nil?
        raise StandardError.new "Database adapter not defined"
      end

      puts ""
      puts "######################"
      puts "REDMINE INSTALLATION SCRIPT"
      puts ""
      puts "REDMINE_VERSION  : #{redmine_version}"
      puts "REDMINE_URL      : #{redmine_url}"
      puts "DATABASE ADAPTER : #{ENV['DATABASE_ADAPTER']}"
      puts ""
    end

    task :remove do
      rm_rf redmine_path
    end

    task :download_tarball do
      mkdir_p tmp_dir
      Dir.chdir(tmp_dir) do
        puts "Downloading tarball"
        if !system("wget #{redmine_url}")
          raise StandardError.new "download failed"
        end
      end
    end

    task :extract_tarball do
      Dir.chdir(tmp_dir) do
        puts "Extracting tarball"
        if !system("tar xf #{redmine_package}")
          raise StandardError.new "download failed"
        end
        mv "#{redmine_name}", "#{redmine_path}", :force => true
        rm_rf tmp_dir
      end
    end

    task :configure_db do
      puts "Configuring database"
      db_adapter = ENV['DATABASE_ADAPTER']
      case db_adapter
      when "mysql"
        a = "mysql"
      when "postgresql"
        a = "postgres"
      when "postgresql_ext"
        a = "postgres_ext"
      when "sqlite"
        a = "sqlite"
      else
        raise StandardError.new "Error copying config files"
      end
      cp "#{plugin_root}/test/confs/database_#{a}.yml",
        "#{redmine_path}/config/database.yml", :verbose => true
    end

    task :print_result do
      puts "Dummy Redmine dir listing"
      Dir["#{redmine_path}/*"].each do |f|
        puts f.sub("#{redmine_path}", "")
      end
      puts ""
      puts "Dummy Redmine plugin dir listing"
      Dir["#{redmine_path}/plugins/*"].each do |f|
        puts f.sub("#{redmine_path}/plugins", "")
      end
      puts ""
    end

    task :link_plugin do
      plugin_dir = "#{redmine_path}/plugins/redmine_helpdesk"
      ln_sf plugin_root, plugin_dir
    end
  end
end
