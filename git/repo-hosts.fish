#!/usr/bin/env fish

set ver 1

# Displays the repos and their hosts (Github, AWS, etc)

# echo PATH: $PATH
echo Script Version: $ver

echo -e \nScript: $(PWD)
echo -e "Date & Time: $(date +%c)\n"

set local_repos
set github_repos
set awscc_repos

cd ~/git
for repo in */
    # echo $repo
    set repo (echo $repo | tr -d '/')
    set origin (git -C $repo config --get remote.origin.url)

    if not test $origin
        # set origin 'Local Repo'
        # set local_repos $local_repos $repo
        set -a local_repos $repo
        # echo $repo is hosted locally!
    else if string match -q -e 'git@github.com' $origin
        set -a github_repos $repo
        # echo $repo is hosted in Github.
    else if string match -q -e 'amazonaws.com' $origin
        set -a awscc_repos $repo
        # echo $repo is hosted in AWS Code Commit.
    else
        echo $repo is hosted in $origin
    end
    # echo $repo: $origin

end
cd -

echo; echo Local Repos...
for repo in $local_repos
    echo $repo
end
echo; echo Github Repos...
for repo in $github_repos
    echo $repo
end
echo; echo AWS CC Repos...
for repo in $awscc_repos
    echo $repo
end
