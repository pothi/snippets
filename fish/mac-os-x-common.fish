# specific to mac OS X
# functions and aliases (abbr)

# replacement for wget
# -s: silent mode to suppress progress meter or error messages.
# -S: to show error messages when used with -s.
# -O: save as remote file name
# -L: follow redirect
abbr -a wget curl -sSOL

# mail log
# ref: https://apple.stackexchange.com/a/276325/24501
abbr -a maillogstream "log stream --predicate  '(process == \"smtpd\") || (process == \"smtp\")' --info"

# time machine log
# ref: https://discussions.apple.com/thread/250942260
abbr -a tmlog 'log show --predicate \'subsystem == "com.apple.TimeMachine"\' --info --last 1h | grep -F \'eMac\' | grep -Fv \'etat\' | awk -F\']\' \'{print substr($0,1,19), $NF}\''
abbr -a tmlogstream "log stream --predicate 'subsystem == \"com.apple.TimeMachine\"' --info | awk -F']' '{print substr(\$0,1,19), \$NF}'"
# additional scripts...
# https://discussions.apple.com/thread/251491948
