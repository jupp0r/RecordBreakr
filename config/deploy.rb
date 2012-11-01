require 'bundler/capistrano'
require "rvm/capistrano"

before 'deploy:setup', 'rvm:install_rvm'
before 'deploy:setup', 'rvm:install_ruby'

set :rvm_ruby_string, 'ruby-1.9.3@recordbreakr'

set :rake, "#{rake} --trace"

set :user, 'jupp'
set :domain, 'jupp0r.de'
set :applicationdir, "/var/www/recordbreakr.jupp0r.de/application"

set :scm, 'git'
set :repository,  "ssh://jupp@jupp0r.de/var/repo/recordbreakr.git"
#set :git_enable_submodules, 1 # if you have vendored rails
set :branch, 'master'
set :git_shallow_clone, 1
set :scm_verbose, true

# roles (servers)
role :web, domain
role :app, domain
role :db,  domain, :primary => true

# deploy config
set :deploy_to, applicationdir
set :deploy_via, :export

# additional settings
default_run_options[:pty] = true  # Forgo errors when deploying from
# windows
#ssh_options[:keys] = %w(/home/user/.ssh/id_rsa)            # If you
#are using ssh_keysset :chmod755, "app config db lib public vendor
#script script/* public/disp*"set :use_sudo, false

# Passenger
namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end
