# Crawlie (the crawler)

[![badge](https://travis-ci.org/nietaki/crawlie.svg?branch=master)](https://travis-ci.org/nietaki/crawlie)
[![Coverage Status](https://coveralls.io/repos/github/nietaki/crawlie/badge.svg?branch=master)](https://coveralls.io/github/nietaki/crawlie?branch=master)
[![Module Version](https://img.shields.io/hexpm/v/crawlie.svg)](https://hex.pm/packages/crawlie)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/crawlie/)
[![Total Download](https://img.shields.io/hexpm/dt/crawlie.svg)](https://hex.pm/packages/crawlie)
[![License](https://img.shields.io/hexpm/l/crawlie.svg)](https://github.com/nietaki/crawlie/blob/master/LICENSE)
[![Last Updated](https://img.shields.io/github/last-commit/nietaki/crawlie.svg)](https://github.com/nietaki/crawlie/commits/master)
[![Built with Spacemacs](https://cdn.rawgit.com/syl20bnr/spacemacs/442d025779da2f62fc86c2082703697714db6514/assets/spacemacs-badge.svg)](http://spacemacs.org)

Crawlie is a simple Elixir library for writing decently-performing crawlers with minimum effort.

## Usage example

See the [crawlie_example](https://github.com/nietaki/crawlie_example) project.

## Inner workings

Crawlie uses Elixir's [GenStage](https://github.com/elixir-lang/gen_stage) to parallelise
the work. Most of the logic is handled by the `Crawlie.Stage.UrlManager`, which consumes the url collection passed by the user, receives the urls extracted by the subsequent processing, makes sure no url is processed more than once, makes sure that the "discovered urls" collection is as small as possible by traversing the url tree in a roughly depth-first manner.

The urls are requested from the `Crawlie.Stage.UrlManager` by a GenStage [Flow](https://hexdocs.pm/flow/Flow.html#content), which in parallel
fetches the urls using HTTPoison, and parses the responses using user-provided callbacks. Discovered urls get sent back to UrlManager.

Here's a rough diagram:

![crawlie architecture diagram](assets/crawlie_arch_v0.2.0.png)

## Statistics

If you're interested in the crawling statistics or want to track the progress in real time, see [`Crawlie.crawl_and_track_stats/3`](https://hexdocs.pm/crawlie/Crawlie.html#crawl_and_track_stats/3). It starts a [`Stats GenServer`](https:/hexdocs.pm/crawlie/Crawlie.Stats.Server.html) in Crawlie's supervision tree, which accumulates the statistics for the crawling session.

## Configuration

See [the docs](https://hexdocs.pm/crawlie/Crawlie.html#crawl/3) for supported options.

## Installation

The package can be installed as:

Add `:crawlie` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:crawlie, "~> 1.0.0"}
  ]
end
```

Ensure `:crawlie` is started before your application:

```elixir
def application do
  [
    applications: [:crawlie]
  ]
end
```

## Copyright and License

Copyright (c) 2016 Jacek Królikowski

This work is free. You can redistribute it and/or modify it under the
terms of the MIT License. See the [LICENSE.md](./LICENSE.md) file for more details.
