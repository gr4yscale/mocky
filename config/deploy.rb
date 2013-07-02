set :application, "Mocky, the sync integration testing MACHINE"
set :scm, :git
set :repository,  "ccgit@projects.crowdcompass.com:mocky"

ssh_options[:forward_agent] = true
ssh_options[:keys] = %w(~/.ssh/id_rsa)                # If you are using ssh_keys
set :use_sudo, false

set :deploy_via, :copy
set :deploy_to, "/srv/mocky" 

set :user, "ubuntu"

set :domain, "mocky.crowdcompass.com"

set :copy_exclude, ['.git']

server "mocky.crowdcompass.com", :app, :web, :db, :primary => true

# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"

# If you are using Passenger mod_rails uncomment this:
namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end
