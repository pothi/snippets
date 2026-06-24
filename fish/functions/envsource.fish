function envsource --description 'Load .env file (skips comments & empty lines)'
    if not test -f $argv[1]
        echo "envsource: File '$argv[1]' not found" >&2
        return 1
    end

    cat $argv[1] \
        | string match -v '^\s*#' \
        | string match -v '^\s*$' \
        | while read -l line

        set -l trimmed (string trim -- $line)

        # Extra safety check for comments
        if string match -q '#*' $trimmed
            continue
        end

        set -l item (string split -m 1 '=' $trimmed)

        if test (count $item) -ge 1
            set -l key (string trim -- $item[1])

            if test -n "$key"
                if string match -q -r '^[a-zA-Z_][a-zA-Z0-9_]*$' -- $key
                    set -gx $key (string trim -- $item[2])
                else
                    echo "envsource: Skipping invalid key '$key'" >&2
                end
            end
        end
    end
end
