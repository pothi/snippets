# ref: https://github.com/aws/aws-cli/issues/1079#issuecomment-2225628740
# also see: https://stackoverflow.com/a/61811035/1004587

function __aws_complete
  set -lx COMP_SHELL fish
  set -lx COMP_LINE (commandline -opc)

  if string match -q -- "-*" (commandline -opt)
    set COMP_LINE $COMP_LINE -
  end

  aws_completer | command sed 's/ $//'
end

complete --command aws --no-files --arguments '(__aws_complete)'
