I# Lokalise

Download your translation files from the [Lokalise](https://lokali.se)
translation service. Use as a command-line tool (e.g. from a Bash script) or as
a Ruby class.

## Installation

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install lokalise

## Command-line usage

```
# Call with no argument for help
> bundle exec lokalise

# Typical usage - mandatory project ID and auth token (which can also be in
  environment variable; get your token from https://lokali.se/account)
> bundle exec lokalise --token aab14314 1234567e0.0129

Options:
-t, --token              API token (default: LOKALISE_API_TOKEN env variable; from:
                         https://lokali.se/en/account)
-f, --format             output format (default: yml)
-o, --output-folder      output folder (default: current folder; will be created if
                         doesnt exist)
-st, --structure         output structure (default:
                         '%PROJECT_NAME%.%LANG_ISO%.%FORMAT%')
-s, --strip              strip out entries with empty string value
-l, --language-fallback  ensure non-dialect fallback exists for all dialects
-v, --verbose            add logging
-q, --quiet              no output - suppress showing new files
-h, --help               help
```

## Ruby usage

Add this line to your application's Gemfile:

```ruby
gem 'lokalise'
```

```ruby
Lokalise::Pull.new(lokalise_api_token: aab14314).download 1234567e0.0129
```

The argument here, `1234567e0.0129`, is your project ID. You may specify
additional options in the constructor (see properties in lokalise.rb for more
options).

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can
also run `bin/console` for an interactive prompt that will allow you to
experiment. Run `bundle exec lokalise` to use the gem in this directory,
ignoring other installed copies of this gem.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

Contributions are welcome. Especially test cases right now.

## License

The gem is available as open source under the terms of the
[MIT License](http://opensource.org/licenses/MIT).
