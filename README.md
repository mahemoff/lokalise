# Lokalise

Download your translation files from the [Lokalise](https://lokali.se) translation service.

```

# Call with no argument for help
> lokalise

# Typical usage - mandatory project ID and auth token (which can also be in environment variable; get your token from https://lokali.se/account)
> lokalize --token aab14314 1234567e0.0129

Options:
  -t, --token              API token (default: LOKALISE_API_TOKEN env variable)
  -f, --format             output format (default: yml)
  -o, --output-folder      output folder (default: current folder; will be created if doesnt exist)
  -s, --strip              strip out entries with empty string value
  -l, --language-fallback  ensure non-dialect fallback exists for all dialects
  -v, --verbose            add logging
  -q, --quiet              no output - suppress showing new files
  -h, --help               help

# Contributions

Are welcome. Especially test cases.

# Legal

Please note this is an unofficial client library, creators are not affiliated with the Lokalise service. [License info](LICENSE.md).
