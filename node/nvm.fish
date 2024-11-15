# To be installed at ~/.config/fish/functions

# https://github.com/nvm-sh/nvm/issues/303#issuecomment-2361844546

function nvm
    set -x current_path $(mktemp)
    bash -c "source ~/.nvm/nvm.sh --no-use; nvm $argv; dirname \$(nvm which current) >$current_path"
    fish_add_path -m $(cat $current_path)
    rm $current_path
end

# supplementary functions
function nvm_find_nvmrc
    bash -c "source ~/.nvm/nvm.sh --no-use; nvm_find_nvmrc"
end

function load_nvm --on-variable PWD
    set -l default_node_version $(nvm version default)
    set -l node_version $(nvm version)
    set -l nvmrc_path $(nvm_find_nvmrc)
    if test -n "$nvmrc_path"
        set -l nvmrc_node_version $(nvm version (cat $nvmrc_path))
        if test "$nvmrc_node_version" = "N/A"
            nvm install $(cat $nvmrc_path)
        else if test "$nvmrc_node_version" != "$node_version"
            nvm use $nvmrc_node_version
        end
    else if test "$node_version" != "$default_node_version"
        echo "Reverting to default Node version"
        nvm use default
    end
end
