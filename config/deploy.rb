### This file contains project-specific settings ###
 
# The project name.
set :application, "fiercemarkets"
 
# List the Drupal multi-site folders.  Use "default" if no multi-sites are installed.
set :domains, ["default"]

# List folders that reside outside of Git
set :static_dirs, ["files","sites"]
 
# username of owner of apache process
set :apache_user, "apache"
 
set :scm, "git"
set :repository,  "git@github.com:FierceMarkets/fiercemarkets.git"
# run as the user logged in to SSH, including keys
# ssh_options[:forward_agent] = true
# gitflow.rb sets the branch
# set :branch, "master"
 
# Use a remote cache to speed things up
set :deploy_via, :remote_cache
 
# Multistage support - see config/deploy/[STAGE].rb for specific configs
set :default_stage, "staging"
set :stages, %w(production staging dev)
 
# Generally don't need sudo for this deploy setup
set :use_sudo, false


case `whoami`.chomp
when "edickinson", "elidickinson"
	set :user, "eli"
end
