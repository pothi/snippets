function envsource --description 'Load .env file (supports quoted values + skips comments/empty lines)'
    if not test -f $argv[1]
        echo "envsource: File '$argv[1]' not found" >&2
        return 1
    end

    cat $argv[1] \
        | string match -v '^\s*#' \
        | string match -v '^\s*$' \
        | while read -l line

        set -l trimmed (string trim -- $line)

        if string match -q '#*' $trimmed
            continue
        end

        # Split on first '=' only
        set -l item (string split -m 1 '=' $trimmed)

        if test (count $item) -ge 1
            set -l key (string trim -- $item[1])

            if test -n "$key"
                if not string match -q -r '^[a-zA-Z_][a-zA-Z0-9_]*$' -- $key
                    echo "envsource: Skipping invalid key '$key'" >&2
                    continue
                end

                # Handle value (strip outer quotes if present)
                set -l value (string trim -- $item[2])

                # Remove surrounding single or double quotes
                if string match -q '"*"' $value
                    set value (string trim -c '"' -- $value)
                else if string match -q "'*'" $value
                    set value (string trim -c "'" -- $value)
                end

                set -gx $key $value
            end
        end
    end
end
