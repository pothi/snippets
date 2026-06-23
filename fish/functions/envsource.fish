# Create the function
function envsource --description 'Load .env file with KEY=VALUE format'
    for line in (cat $argv | string match -v '^\s*#')
        set -l item (string split -m 1 '=' $line)
        set -gx $item[1] $item[2]
    end
end
