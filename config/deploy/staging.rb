### This file contains stage-specific settings ###
 
# Set the deployment directory on the target hosts.
set :deploy_to, "/var/apps/#{application}"
set :web_path, "/var/www/#{application}"

set :deploy_via, :checkout

# The hostnames to deploy to.
role :web, "staging.fiercemarkets.com"
 
# Specify one of the web servers to use for database backups or updates.
# This server should also be running Drupal.
role :db, "staging.fiercemarkets.com", :primary => true
 
# The username on the target system, if different from your local username
# ssh_options[:user] = 'alice'
 
# The path to drush
# set :drush, "cd #{current_path} ; /usr/bin/php /data/lib/php/drush/drush.php"
set :drush, "echo "

set :user, "deploy"
