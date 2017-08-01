# Change Log

## [Unreleased](https://github.com/sensu/sensu-transport/tree/HEAD)

[Full Changelog](https://github.com/sensu/sensu-transport/compare/v7.0.2...HEAD)

**Merged pull requests:**

- Add ruby 2.4.0 to .travis.yml [\#46](https://github.com/sensu/sensu-transport/pull/46) ([cwjohnston](https://github.com/cwjohnston))
- remove codeclimate, update redis spec to fix the build [\#45](https://github.com/sensu/sensu-transport/pull/45) ([cwjohnston](https://github.com/cwjohnston))

## [v7.0.2](https://github.com/sensu/sensu-transport/tree/v7.0.2) (2016-11-03)
[Full Changelog](https://github.com/sensu/sensu-transport/compare/v7.0.1...v7.0.2)

## [v7.0.1](https://github.com/sensu/sensu-transport/tree/v7.0.1) (2016-11-03)
[Full Changelog](https://github.com/sensu/sensu-transport/compare/v7.0.0...v7.0.1)

## [v7.0.0](https://github.com/sensu/sensu-transport/tree/v7.0.0) (2016-11-03)
[Full Changelog](https://github.com/sensu/sensu-transport/compare/v6.0.1...v7.0.0)

**Merged pull requests:**

- Implement Transport Base API hostname resolution methods [\#42](https://github.com/sensu/sensu-transport/pull/42) ([portertech](https://github.com/portertech))
- Improve rabbitmq transport logging on connection errors [\#34](https://github.com/sensu/sensu-transport/pull/34) ([moises-silva](https://github.com/moises-silva))
- Throw an exception when publishing while disconnected [\#33](https://github.com/sensu/sensu-transport/pull/33) ([moises-silva](https://github.com/moises-silva))

## [v6.0.1](https://github.com/sensu/sensu-transport/tree/v6.0.1) (2016-09-12)
[Full Changelog](https://github.com/sensu/sensu-transport/compare/v6.0.0...v6.0.1)

**Merged pull requests:**

- Only include necessary gem files [\#41](https://github.com/sensu/sensu-transport/pull/41) ([amdprophet](https://github.com/amdprophet))

## [v6.0.0](https://github.com/sensu/sensu-transport/tree/v6.0.0) (2016-04-28)
[Full Changelog](https://github.com/sensu/sensu-transport/compare/v5.0.0...v6.0.0)

**Merged pull requests:**

- Use amqp 1.6.0 for better connection error messages [\#29](https://github.com/sensu/sensu-transport/pull/29) ([portertech](https://github.com/portertech))

## [v5.0.0](https://github.com/sensu/sensu-transport/tree/v5.0.0) (2016-03-18)
[Full Changelog](https://github.com/sensu/sensu-transport/compare/v4.0.0...v5.0.0)

**Merged pull requests:**

- Implemented a deferrable/callback transport API [\#27](https://github.com/sensu/sensu-transport/pull/27) ([portertech](https://github.com/portertech))

## [v4.0.0](https://github.com/sensu/sensu-transport/tree/v4.0.0) (2016-02-22)
[Full Changelog](https://github.com/sensu/sensu-transport/compare/v3.3.0...v4.0.0)

**Merged pull requests:**

- reduce the use of block arguments [\#26](https://github.com/sensu/sensu-transport/pull/26) ([portertech](https://github.com/portertech))
- Improve RabbitMQ error handling [\#24](https://github.com/sensu/sensu-transport/pull/24) ([portertech](https://github.com/portertech))

## [v3.3.0](https://github.com/sensu/sensu-transport/tree/v3.3.0) (2015-09-16)
[Full Changelog](https://github.com/sensu/sensu-transport/compare/v3.2.1...v3.3.0)

**Merged pull requests:**

- Removed sensu-em as a dependency, let Sensu core determine the em to use [\#18](https://github.com/sensu/sensu-transport/pull/18) ([portertech](https://github.com/portertech))

## [v3.2.1](https://github.com/sensu/sensu-transport/tree/v3.2.1) (2015-08-17)
[Full Changelog](https://github.com/sensu/sensu-transport/compare/v3.2.0...v3.2.1)

**Merged pull requests:**

- Locked amq-protocol to 1.9.2, 2.x.x only works w/ Ruby 2.0+ [\#17](https://github.com/sensu/sensu-transport/pull/17) ([portertech](https://github.com/portertech))

## [v3.2.0](https://github.com/sensu/sensu-transport/tree/v3.2.0) (2015-07-27)
[Full Changelog](https://github.com/sensu/sensu-transport/compare/v3.1.0...v3.2.0)

**Merged pull requests:**

- Reset \(close connection\) on periodic reconnect attempts, cleaning up SSL context [\#16](https://github.com/sensu/sensu-transport/pull/16) ([portertech](https://github.com/portertech))

## [v3.1.0](https://github.com/sensu/sensu-transport/tree/v3.1.0) (2015-07-27)
[Full Changelog](https://github.com/sensu/sensu-transport/compare/v3.0.0...v3.1.0)

**Merged pull requests:**

- Patch amqp lib to fix heartbeats [\#15](https://github.com/sensu/sensu-transport/pull/15) ([portertech](https://github.com/portertech))

## [v3.0.0](https://github.com/sensu/sensu-transport/tree/v3.0.0) (2015-05-20)
[Full Changelog](https://github.com/sensu/sensu-transport/compare/v2.4.0...v3.0.0)

**Merged pull requests:**

- Redis transport [\#12](https://github.com/sensu/sensu-transport/pull/12) ([portertech](https://github.com/portertech))

## [v2.4.0](https://github.com/sensu/sensu-transport/tree/v2.4.0) (2014-10-31)
[Full Changelog](https://github.com/sensu/sensu-transport/compare/v2.3.0...v2.4.0)

**Merged pull requests:**

- use additional connect\(\) options \(again\) [\#9](https://github.com/sensu/sensu-transport/pull/9) ([portertech](https://github.com/portertech))

## [v2.3.0](https://github.com/sensu/sensu-transport/tree/v2.3.0) (2014-10-31)
[Full Changelog](https://github.com/sensu/sensu-transport/compare/v2.2.0...v2.3.0)

**Merged pull requests:**

- Throw initial connection errors [\#8](https://github.com/sensu/sensu-transport/pull/8) ([portertech](https://github.com/portertech))

## [v2.2.0](https://github.com/sensu/sensu-transport/tree/v2.2.0) (2014-10-31)
[Full Changelog](https://github.com/sensu/sensu-transport/compare/v2.1.0...v2.2.0)

**Merged pull requests:**

- Reconnect on EM connection errors [\#7](https://github.com/sensu/sensu-transport/pull/7) ([portertech](https://github.com/portertech))

## [v2.1.0](https://github.com/sensu/sensu-transport/tree/v2.1.0) (2014-10-31)
[Full Changelog](https://github.com/sensu/sensu-transport/compare/v2.0.0...v2.1.0)

**Merged pull requests:**

- Fixed RabbitMQ backwards compatibility, w/ non multi-broker config [\#6](https://github.com/sensu/sensu-transport/pull/6) ([portertech](https://github.com/portertech))

## [v2.0.0](https://github.com/sensu/sensu-transport/tree/v2.0.0) (2014-10-23)
[Full Changelog](https://github.com/sensu/sensu-transport/compare/v1.0.0...v2.0.0)

**Merged pull requests:**

- Support multiple RabbitMQ brokers [\#5](https://github.com/sensu/sensu-transport/pull/5) ([portertech](https://github.com/portertech))
- ignore vendor [\#2](https://github.com/sensu/sensu-transport/pull/2) ([y13i](https://github.com/y13i))

## [v1.0.0](https://github.com/sensu/sensu-transport/tree/v1.0.0) (2014-06-12)
[Full Changelog](https://github.com/sensu/sensu-transport/compare/v0.0.7...v1.0.0)

## [v0.0.7](https://github.com/sensu/sensu-transport/tree/v0.0.7) (2014-06-03)
[Full Changelog](https://github.com/sensu/sensu-transport/compare/v0.0.6...v0.0.7)

## [v0.0.6](https://github.com/sensu/sensu-transport/tree/v0.0.6) (2014-05-28)
[Full Changelog](https://github.com/sensu/sensu-transport/compare/v0.0.5...v0.0.6)

## [v0.0.5](https://github.com/sensu/sensu-transport/tree/v0.0.5) (2014-05-28)
[Full Changelog](https://github.com/sensu/sensu-transport/compare/v0.0.4...v0.0.5)

## [v0.0.4](https://github.com/sensu/sensu-transport/tree/v0.0.4) (2014-05-28)
[Full Changelog](https://github.com/sensu/sensu-transport/compare/v0.0.3...v0.0.4)

## [v0.0.3](https://github.com/sensu/sensu-transport/tree/v0.0.3) (2014-05-27)
[Full Changelog](https://github.com/sensu/sensu-transport/compare/v0.0.2...v0.0.3)

## [v0.0.2](https://github.com/sensu/sensu-transport/tree/v0.0.2) (2014-05-19)
[Full Changelog](https://github.com/sensu/sensu-transport/compare/v0.0.1...v0.0.2)

**Merged pull requests:**

- Support JRuby \(w/ TLS\) [\#1](https://github.com/sensu/sensu-transport/pull/1) ([portertech](https://github.com/portertech))

## [v0.0.1](https://github.com/sensu/sensu-transport/tree/v0.0.1) (2014-05-10)


\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*