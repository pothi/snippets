#!/usr/bin/env sh

#--- prerequisites ---#
# doctl
# DO_PK_FIREWALL_ID env var in ~/.envrc file
# myip script

[ -f ~/.envrc ] && . ~/.envrc

doctl compute firewall add-rules $DO_PK_FIREWALL_ID --inbound-rules=protocol:tcp,ports:22,address:$(myip)
