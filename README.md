# Identikey

This library is a thin yet incomplete wrapper of the VASCO Identikey SOAP API.

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
gem 'identikey'
```

And then execute:

    $ bundle

## Configuration

By default the client expects WSDL files in the current working directory,
into `./sdk/wsdl` and it connects to an Identikey API endpoint on localhost
port 8888 using TLSv1.2. Great for development, but definitely not good for
production.

To configure the client, you should at least define where your WSDL files are
and where the SOAP endpoint is. Given the WSDL file is different for the two
API sets (Authentication and Administration), you need to configure the two
classes separately.

Use the `.configure` method, that will run the block you give to it in the
context of the [Savon::Globals](http://savonrb.com/version2/globals.html)
object as such all available configuration parameters are available as
instance methods.

Example:

```ruby
Identikey::Authentication.configure do
  wsdl     './path/to/your/authentication.wsdl'
  endpoint 'https://your-identikey.example.com:8888'

  # ... more configuration options as needed ...
end

Identikey::Administration.configure do
  wsdl     './path/to/your/administrtaion.wsdl'
  endpoint 'https://your-identikey.example.com:8888'

  # ... more configuration options as needed ...
end
```

By default, all SOAP requests and responses are logged to `log/identikey.log`.

If you want to reduce the logging level please use:

```ruby
Identikey::Authentication.configure do
  log_level :info # or one of [:debug, :warn, :error, :fatal]
end
```

Or to disable it altogether (not recommended):

```ruby
Identikey::Authentication.configure do
  log false
end
```

The `configure` block accepts all Savon options, for which documentation
is available here: http://savonrb.com/version2/globals.html feel free to
amend it to suit your needs.

The only option whose semantics differ from the default is `filters`, as
it adds handling the faulty parameter passing design in Identikey, where
the same elements are used to transmit different business informations.

By default, sensitive values attribute are filtered out from the logs.
Other attributes to filter out can be specified by prefixing them with
`identikey:`.

Example, filter out `CREDFLD_PASSWORD` and `CREDFLD_USERID`:

```ruby
Identikey::Authentication.configure do
  filters [ 'identikey:CREDFLD_PASSWORD', 'identikey:CREDFLD_USERID' ]
end
```

Please note that the following attributes are filtered out by default:

* `CREDFLD_PASSWORD`
* `CREDFLD_STATIC_PASSWORD`
* `CREDFLD_SESSION_ID`

Please note that if you set your custom filters, these will override the
defaults and you should also take care of filtering the above parameters
in addition to the ones you want to filter out.

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

## Logging to separate files

You can and are encouraged to configure different logging destinations
for the different API endpoints, as follows:

```ruby
Identikey::Administration.configure do
  logger   Logger.new("log/#{Rails.env}.identikey.admin.log")
end

Identikey::Authentication.configure do
  logger   Logger.new("log/#{Rails.env}.identikey.admin.log")
end
```

However be aware of a caveat, as Identikey uses Savon that uses HTTPI
and the latter has a global logger, that Savon sets (and overwrites)
upon calls to `logger`.

In the above scenario, you can use a different logfile for HTTPI:

```ruby
HTTPI.logger = Logger.new("log/#{Rails.env}.identikey.httpi.log")
```

However please be aware of side-effects with other components of
your application.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then,
run `rake` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To run specs, please copy `spec/test.env.example` into `spec/test.env` and
populate it with your Identikey Authentication Server host, username, password
and domain. You also need the Identikey SDK, that can be placed in `/sdk` and
its WSDL paths as well referenced in the `spec/test.env` file.

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
