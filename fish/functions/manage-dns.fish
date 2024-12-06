# To add a local domain for testing

set __manage_dns_version 1.0.0

function manage-dns --description "Manage local DNS for local domains"
    argparse --name=add-local-domain 'h/help' 'd/delete=' 'a/add=' 'v/version' 'i/init' 's/show' -- $argv
    or return

    if set -q _flag_version
        echo $__manage_dns_version
        return 0
    end

    if set -q _flag_help
        __add_manage_dns_print_help
        return 0
    end

    if set -q _flag_add
        if not fish_is_root_user
            echo >&2 This script needs sudo / root privileges.
            return 1
        end

        set DOMAIN $_flag_add

        mkdir /etc/resolver &>/dev/null
        echo 'nameserver 127.0.0.1' > /etc/resolver/$DOMAIN

        cd /etc/dnsmasq.d

        echo "local=/mini/" > local-domain-$DOMAIN.conf
        echo "address=/$DOMAIN/127.0.0.1" >> local-domain-$DOMAIN.conf

        restart-dns

        echo $DOMAIN added.

        return 0
    end

    if set -q _flag_delete
        set DOMAIN $_flag_delete

        if test -f /etc/resolver/$DOMAIN
            rm /etc/resolver/$DOMAIN
        end

        if test -f /etc/dnsmasq.d/local-domain-$DOMAIN.conf
            rm /etc/dnsmasq.d/local-domain-$DOMAIN.conf
        end

        restart-dns

        echo "Removed the domain $DOMAIN, if it existed!"

        return 0
    end
end

function __add_manage_dns_print_help

    printf '%s\n\n' 'Manage local DNS for local domains'

    printf 'Usage: %s [-a/--add <tld_ext>] [-d/--delete <tld_ext] [i/init] [-s/--show] [-v/--version] [-h/--help]\n\n' manage-dns

    printf '\t%s\t%s\n' "-a, --add" "Add a top-level local domain extension for testing"
    printf '\t%s\t%s\n' "-d, --delete" "Delete the existing top-level domain extension, if any."
    printf '\t%s\t%s\n' "-i, --install" "Install dnsmasq"
    printf '\t%s\t%s\n' "-s, --show" "Show the existing active local domain extensions"
    printf '\t%s\t%s\n' "-v, --version" "Prints the version info"
    printf '\t%s\t%s\n' "-h, --help" "Prints help"

    printf "\nFor more info, changelog and documentation... https://github.com/pothi/\n"

end
