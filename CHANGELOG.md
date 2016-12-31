# Changelog

## v0.3.0 (2016-12-31)

Enhancements:
- No longer extracting the links on pages that are on `max_depth` depth -  [#4](https://github.com/nietaki/crawlie/issues/4)
- Keeping track of urls that remain to be crawled to know when to wrap up the crawling `Flow` -  [#7](https://github.com/nietaki/crawlie/issues/7)

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
