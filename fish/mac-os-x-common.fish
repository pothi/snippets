# specific to mac OS X

# replacement for wget
# -s: silent mode to suppress progress meter or error messages.
# -S: to show error messages when used with -s.
# -O: save as remote file name
# -L: follow redirect
abbr -a wget curl -sSOL
