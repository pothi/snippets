#!/usr/bin/env sh

#--- prerequisites ---#
# doctl
# DO_PK_FIREWALL_ID env var in ~/.envrc file
# jq

[ -f ~/.envrc ] && . ~/.envrc

doctl compute firewall list -o json | jq -r '.[0]["inbound_rules"][] | select (.ports == "22") | .sources.addresses[]' | while read ip ; do doctl compute firewall remove-rules $DO_PK_FIREWALL_ID --inbound-rules protocol:tcp,ports:22,address:$ip ; done
