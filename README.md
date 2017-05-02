# Crawlie (the crawler) [![badge](https://travis-ci.org/nietaki/crawlie.svg?branch=master)](https://travis-ci.org/nietaki/crawlie) [![Coverage Status](https://coveralls.io/repos/github/nietaki/crawlie/badge.svg?branch=master)](https://coveralls.io/github/nietaki/crawlie?branch=master) [![Hex.pm](https://img.shields.io/hexpm/v/crawlie.svg)](https://hex.pm/packages/crawlie) [![docs](https://img.shields.io/badge/docs-hexdocs-yellow.svg)](https://hexdocs.pm/crawlie/) [![Built with Spacemacs](https://cdn.rawgit.com/syl20bnr/spacemacs/442d025779da2f62fc86c2082703697714db6514/assets/spacemacs-badge.svg)](http://spacemacs.org)


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

## Configuration

See [the docs](https://hexdocs.pm/crawlie/Crawlie.html#crawl/3) for supported options.

## Planned features

- Option of respecting `robots.txt` of the websites (on by default)

## Installation

The package can be installed as:

  1. Add `crawlie` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:crawlie, "~> 0.5.0"}]
end
```

  2. Ensure `crawlie` is started before your application:

```elixir
def application do
  [applications: [:crawlie]]
end
```
