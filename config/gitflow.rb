Capistrano::Configuration.instance(true).load do |configuration|
    before "deploy:update_code", "gitflow:calculate_tag"
    namespace :gitflow do
        def last_tag_matching(pattern)
            lastTag = nil

            allTagsMatching = `git tag -l '#{pattern}'`
            allTagsMatching = allTagsMatching.split
            natcmpSrc = File.join(File.dirname(__FILE__), '/natcmp.rb')
            require natcmpSrc
            allTagsMatching.sort! do |a,b|
                String.natcmp(b,a,true)
            end
            
            if allTagsMatching.length > 0
                lastTag = allTagsMatching[0]
            end
            return lastTag
        end

        def last_dev_tag()
            return last_tag_matching('dev-*')
        end

        def last_staging_tag()
            return last_tag_matching('staging-*')
        end

        def last_production_tag()
            return last_tag_matching('production-*')
        end

        desc "Calculate the tag to deploy"
        task :calculate_tag do
            # make sure we have any other deployment tags that have been pushed by others so our auto-increment code doesn't create conflicting tags
            `git fetch`

            tagMethod = "tag_#{stage}"
            send tagMethod

            # push tags and latest code
            system 'git push'
            if $? != 0
                raise "git push failed"
            end
            system 'git push --tags'
            if $? != 0
                raise "git push --tags failed"
            end
        end

        desc "Show log between most recent staging tag (or given tag=XXX) and last production release."
        task :update_log do
            fromTag = nil
            toTag = nil

            # do different things based on stage
            if stage == :production
                fromTag = last_production_tag
            elsif stage == :staging
                fromTag = last_staging_tag
            else
                raise "Unsupported stage #{stage}"
            end

            # no idea how to properly test for an optional cap argument a la '-s tag=x'
            toTag = configuration[:tag]
            if toTag == nil
                puts "Calculating 'end' tag for :update_log for '#{stage}'"
                # do different things based on stage
                if stage == :production
                    toTag = last_staging_tag
                elsif stage == :staging
                    toTag = 'head'
                else
                    raise "Unsupported stage #{stage}"
                end
            end

            # run comp
            logSubcommand = 'log'
            if ENV['git_log_command'] && ENV['git_log_command'].strip != ''
                logSubcommand = ENV['git_log_command']
            end
            command = "git #{logSubcommand} #{fromTag}..#{toTag}"
            puts command
            system command
        end

        desc "Mark the current code as a dev release"
        task :tag_dev do
            # find latest dev tag for today
            newTagDate = Date.today.to_s 
            newTagSerial = 1

            lastDevTag = last_tag_matching("dev-#{newTagDate}.*")
            if lastDevTag
                # calculate largest serial and increment
                lastDevTag =~ /dev-[0-9]{4}-[0-9]{2}-[0-9]{2}\.([0-9]*)/
                newTagSerial = $1.to_i + 1
            end
            newDevTag = "dev-#{newTagDate}.#{newTagSerial}"

            shaOfCurrentCheckout = `git log --pretty=format:%H HEAD -1`
            shaOfLastDevTag = nil
            if lastDevTag
                shaOfLastDevTag = `git log --pretty=format:%H #{lastDevTag} -1`
            end

            if shaOfLastDevTag == shaOfCurrentCheckout
                puts "Not re-tagging dev because the most recent tag (#{lastDevTag}) already points to current head"
                newDevTag = lastDevTag
            else
                puts "Tagging current branch for deployment to dev as '#{newDevTag}'"
                system "git tag -a -m 'tagging current code for deployment to dev' #{newDevTag}"
            end

            set :branch, newDevTag
        end


        desc "Mark the current code as a staging/qa release"
        task :tag_staging do
            # find latest staging tag for today
            newTagDate = Date.today.to_s 
            newTagSerial = 1

            lastStagingTag = last_tag_matching("staging-#{newTagDate}.*")
            if lastStagingTag
                # calculate largest serial and increment
                lastStagingTag =~ /staging-[0-9]{4}-[0-9]{2}-[0-9]{2}\.([0-9]*)/
                newTagSerial = $1.to_i + 1
            end
            newStagingTag = "staging-#{newTagDate}.#{newTagSerial}"

            shaOfCurrentCheckout = `git log --pretty=format:%H HEAD -1`
            shaOfLastStagingTag = nil
            if lastStagingTag
                shaOfLastStagingTag = `git log --pretty=format:%H #{lastStagingTag} -1`
            end

            if shaOfLastStagingTag == shaOfCurrentCheckout
                puts "Not re-tagging staging because the most recent tag (#{lastStagingTag}) already points to current head"
                newStagingTag = lastStagingTag
            else
                puts "Tagging current branch for deployment to staging as '#{newStagingTag}'"
                system "git tag -a -m 'tagging current code for deployment to staging' #{newStagingTag}"
            end

            set :branch, newStagingTag
        end

        desc "Push the head of master to production."
        task :tag_production do

            system 'git checkout master'
            if $? != 0
                raise "git checkout of master failed"
            end

            # find latest production tag for today
            newTagDate = Date.today.to_s 
            newTagSerial = 1

            lastProductionTag = last_tag_matching("production-#{newTagDate}.*")
            if lastProductionTag
                # calculate largest serial and increment
                lastProductionTag =~ /production-[0-9]{4}-[0-9]{2}-[0-9]{2}\.([0-9]*)/
                newTagSerial = $1.to_i + 1
            end
            newProductionTag = "production-#{newTagDate}.#{newTagSerial}"

            shaOfCurrentCheckout = `git log --pretty=format:%H HEAD -1`
            shaOfLastProductionTag = nil
            if lastProductionTag
                shaOfLastProductionTag = `git log --pretty=format:%H #{lastProductionTag} -1`
            end

            if shaOfLastProductionTag == shaOfCurrentCheckout
                puts "Not re-tagging production because the most recent tag (#{lastProductionTag}) already points to current head of the master branch."
                newProductionTag = lastProductionTag
            else
                puts "Tagging current head of the master branch for deployment to production as '#{newProductionTag}'"
                system "git tag -a -m 'tagging current code for deployment to production' #{newProductionTag}"
            end

            set :branch, newProductionTag
        end
    end
end
