function curli
    set -l curli_bin ~/.local/downloads/curli/curl-impersonate

    if not test -x "$curli_bin"
        echo "Error: curl-impersonate not found at $curli_bin" >&2
        echo "Please check the path and make sure it's executable." >&2
        return 1
    end

    # Run with:
    #   --compressed     → enables brotli/zstd/gzip + sends proper Accept-Encoding
    #   -D -             → dump response headers to stdout
    #   -o /dev/null     → discard the body
    #   -s               → silent (no progress bar)
    #   -L               → follow redirects (highly recommended)
    command "$curli_bin" --compressed -sL -D - -o /dev/null $argv
end

function unused-curli
    # Full path to your curl-impersonate directory
    set -l curli_path "/Users/pothi/.local/downloads/curli"

    # Choose your preferred impersonation (change this if you want another one)
    # Common good options: curl_chrome134, curl_chrome120, curl_safari17_0, etc.
    set -l impersonate_bin "$curli_path/curl-impersonate"
    # set -l impersonate_bin "$curli_path/curl_chrome134"

    if not test -x "$impersonate_bin"
        echo "Error: $impersonate_bin not found or not executable" >&2
        echo "Check your curl-impersonate folder and update the impersonate_bin line" >&2
        return 1
    end

    # Run with:
    #   --compressed     → enables brotli/zstd/gzip + sends proper Accept-Encoding
    #   -D -             → dump response headers to stdout
    #   -o /dev/null     → discard the body
    #   -s               → silent (no progress bar)
    #   -L               → follow redirects (highly recommended)
    command "$impersonate_bin" --compressed -sL -D - -o /dev/null $argv
end
