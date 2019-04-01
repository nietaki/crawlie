# Changelog

## Unreleased

- Update GenStage to 0.14.1
- Update Flow to 0.14.3
- Update httpoison requirement to allow newer versions
- Update meck
- Update pqueue

## v1.0.0 (2017-06-26)

- Updating GenStage and Flow to 0.12.x


## v0.6.0 (2017-05-16)

Most planned (for now) features implemented. Unless there's emphatic feature requests, the development will probably focus on bug fixes and interface improvements.

Enhancements:
- Tracking crawling statistics. [#26](https://github.com/nietaki/crawlie/issues/26)

Bug fixes:
- Better `Crawlie.Response` behaviour on missing expected headers.
- Removing potentially duplicated "crawling finished" debug messages from the logs. [#25](https://github.com/nietaki/crawlie/issues/25)


## v0.5.1 (2017-05-11)

Enhancements:
- Allowing the `Crawlie.ParserLogic` to skip pages without printing warnings. [#27](https://github.com/nietaki/crawlie/issues/27)
- Better documentation for `Crawlie.ParserLogic` behaviour.


## v0.5.0 (2017-05-02)

Enhancements: 
- Limiting the memory usage by removing duplicate uris as soon as possible [#22](https://github.com/nietaki/crawlie/issues/22)
- Simplifying initial Url Manager state [#23](https://github.com/nietaki/crawlie/issues/23)

Breaking API changes:
- Moving from string urls to `URI.t` [#19](https://github.com/nietaki/crawlie/issues/19)
- Renaming `extract_links` to `extract_uris` in the ParserLogic behaviour [#20](https://github.com/nietaki/crawlie/issues/20)


## v0.4.1 (2017-04-29)

Enhancements:
- Updating `GenStage` and `Flow` to 0.11.x


## v0.4.0 (2017-04-28)

Enhancements:
- Introducing `Crawlie.Response` struct passed to the user's parser logic - breaking API change. - [#6](https://github.com/nietaki/crawlie/issues/6)
- Setting sensible defaults tuning the Flow parameters - [#8](https://github.com/nietaki/crawlie/issues/8)


## v0.3.1 (2017-01-06)

Enhancements:
- Replacing heap with a priority queue for storing discovered urls - [#9](https://github.com/nietaki/crawlie/issues/9)


## v0.3.0 (2016-12-31)

Enhancements:
- No longer extracting the links on pages that are on `max_depth` depth - [#4](https://github.com/nietaki/crawlie/issues/4)
- Keeping track of urls that remain to be crawled to know when to wrap up the crawling `Flow` - [#7](https://github.com/nietaki/crawlie/issues/7)

Happy New Year!


## v0.2.0 (2016-12-25)

Url deduplication implemented. Tweaking performance with Flow partition options.


## v0.2.0-alpha1 (2016-12-18)

First version using GenStage. Many breaking API changes.

- supporting retries
- supporting recursive crawling


## v0.1.1 (2016-12-16)

Cleaned up `Crawlie` and `Crawlie.Options` modules' interface, same naive implementation.


## v0.1.0 (2016-12-13)

Initial release with a naive implementation.
