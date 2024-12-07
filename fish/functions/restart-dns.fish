# To clear dns cache

function restart-dns --description "Clear DNS cache and restart dnsmasq / mDNS"
    # dnsmasq
    launchctl unload /Library/LaunchDaemons/uk.org.thekelleys.dnsmasq.plist
    launchctl load /Library/LaunchDaemons/uk.org.thekelleys.dnsmasq.plist

    dscacheutil -flushcache
    killall -HUP mDNSResponder
end
