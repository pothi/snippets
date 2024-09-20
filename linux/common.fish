# To be installed at ~/.config/fish/conf.d/
#--- PATHs ---#
# to permanently add to PATH
# fish_add_path ~/.local/bin
# fish_add_path ~/bin
set -x PATH "~/.local/bin" "$PATH"
set -x PATH "~/bin" "$PATH"

# To use !! like bash
# see file:///usr/local/share/doc/fish/cmds/abbr.html?highlight=alias#examples
function last_history_item
    echo $history[1]
end
abbr -a !! --position anywhere --function last_history_item

# fish shell doesn't have the concept of alias
# see file:///usr/local/share/doc/fish/language.html#defining-aliases
#--- aliases / functions ---#
function curld
    curl -H 'Accept-Encoding:gzip' -s -D- -o /dev/null -A 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:130.0) Gecko/20100101 Firefox/130.0' $argv
end

function curlm
    curl -H 'Accept-Encoding:gzip' -s -D- -o /dev/null -A 'Mozilla/5.0 (iPhone; CPU iPhone OS 13_1_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.1 Mobile/15E148 Safari/604.1' $argv
end

function curlt
    curl -H 'Accept-Encoding:gzip' -s -D- -o /dev/null -A 'Mozilla/5.0 (iPad; CPU OS 11_0 like Mac OS X) AppleWebKit/604.1.34 (KHTML, like Gecko) Version/11.0 Mobile/15A5341f Safari/604.1' $argv
end

#--- abbr ---#
# abbr for git commands
abbr -a gc git commit -m
abbr -a gp git push
