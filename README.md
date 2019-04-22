# Identikey

This library is a thin and incomplete wrapper of the VASCO Identikey SOAP API.

Vasco Identikey has been recently re-branded as OneSpan Authentication Server.

## Requirements

The gem requires the Vasco SDK, that is private intellectual property and
cannot be redistributed here. You have to obtain it from VASCO / OneSpan
as part of your subscription.

The gem interfaces against a running Identikey server, communicating on
port 8888/TCP the SOAP protocol over HTTPS.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'identikey', github: 'ifad/identikey'
```

And then execute:

    $ bundle

## Usage

This is still in alpha stage, as such there is not much documentation. Have a
look at the specs for sample usage.

* Verify an end user OTP

```ruby
Identikey::Authentication.valid_otp?('username', 'otp')
```

* Start an administration session

```ruby
s = Identikey::Administration::Session.new(username: 'admin', password: 'foobar')
s.logon
```

* Find a digipass

```ruby
d = s.find_digipass('serial')
```

* Perform an OTP test

```ruby
d = d.test_otp('1234567890')
```

* Assign a digipass to an user

```ruby
d.assign! 'username'
```

* Unassign a digipass

```ruby
d.unassign!
```

* End an administrative session

```ruby
s.logoff
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then,
run `rake` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

To release a new version, update the version number in `version.rb`, and then
run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/ifad/identikey.

## License

The gem is available as open source under the terms of the [MIT
License](https://opensource.org/licenses/MIT).
