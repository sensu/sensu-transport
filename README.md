# Sensu::Transport

[![Build Status](https://travis-ci.org/sensu/sensu-transport.svg?branch=master)](https://travis-ci.org/sensu/sensu-transport)

[![Code Climate](https://codeclimate.com/github/sensu/sensu-transport.png)](https://codeclimate.com/github/sensu/sensu-transport)

## Installation

Add this line to your application's Gemfile:

    gem 'sensu-transport'

And then execute:

    $ bundle

## Usage

This library provides the transport Base class, its documentation can be found
[here](http://rubydoc.info/github/sensu/sensu-transport/Sensu/Transport/Base).
The RabbitMQ transport is also included, providing an example while
continuing to be the primary Sensu transport, supported by the
community and [Heavy Water Operations](http://hw-ops.com).

## Contributing

Please do not submit a pull request to add an additional transport to
this library.

1. [Fork it](https://github.com/sensu/sensu-transport/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

Sensu-Transport is released under the [MIT license](https://raw.github.com/sensu/sensu-transport/master/LICENSE.txt).
