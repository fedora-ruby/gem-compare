# gem-compare

gem-compare is a RubyGems plugin that compares different versions of the specified gem. It can help you to track changes in metadata through the time, see how dependencies were evolving and spot important changes in gem's files such as shebang or permissions modifications.

This is especially handy for:

- checking what goes into to a next gem release
- tracking dependencies and license changes before upgrades
- spotting anything suspicious and unusual

## Installation

You can install `gem-compare` as a gem from RubyGems.org:

```bash
$ gem install gem-compare
```

## Usage

By default, `gem-compare` compares specified versions of the given gem and includes only changes in the final report. If it's supposed to compare file lists or Gemfiles it will need to download the gems, otherwise it just downloads the specs. If you want to keep the downloaded `.gem` files, use `-k` (as 'keep') option. If you want to see the full report use `-a` (as 'all') switch:

```bash
$ gem compare rails 3.0.0 4.0.0 -k
Compared versions: ["3.0.0", "4.0.0"]
  DIFFERENT date:
    3.0.0: 2010-08-29 00:00:00 UTC
    4.0.0: 2013-06-25 00:00:00 UTC
  DIFFERENT executables:
    3.0.0: ["rails"]
    4.0.0: []
  DIFFERENT has_rdoc:
    3.0.0: true
    4.0.0:
  DIFFERENT license:
    3.0.0:
    4.0.0: MIT
  DIFFERENT licenses:
    3.0.0: []
    4.0.0: ["MIT"]
  DIFFERENT required_ruby_version:
    3.0.0: >= 1.8.7
    4.0.0: >= 1.9.3
  DIFFERENT required_rubygems_version:
    3.0.0: >= 1.3.6
    4.0.0: >= 1.8.11
  DIFFERENT rubygems_version:
    3.0.0: 1.3.7
    4.0.0: 2.0.2
  DIFFERENT version:
    3.0.0: 3.0.0
    4.0.0: 4.0.0
  DIFFERENT files:
    3.0.0->4.0.0:
      * Deleted:
            bin/rails
      * Added:
            README.md
            guides/assets/images/belongs_to.png
            guides/assets/images/book_icon.gif
(...)
```

You can also specify what you are interested in by using -p (as 'param') option:

```bash
$ gem compare activesupport 4.0.0 4.1.0 -p 'runtime_dependency'
Compared versions: ["4.0.0", "4.1.0"]
  DIFFERENT runtime dependencies:
    4.0.0->4.1.0:
      * Deleted:
            multi_json ["~> 1.3"] (runtime)
      * Added:
            json [">= 1.7.7", "~> 1.7"] (runtime)
      * Updated:
            i18n from: [">= 0.6.4", "~> 0.6"] to: [">= 0.6.9", "~> 0.6"]
            tzinfo from: ["~> 0.3.37"] to: ["~> 1.1"]
            minitest from: ["~> 4.2"] to: ["~> 5.1"]
```
There are also shortcuts for favourite options. Use `--runtime` for runtime dependencies, `--gemfiles` for comparing Gemfiles or `--files` for comparing file lists:

```bash
$ gem compare rails 2.0.1 3.0.0 -k --files
Compared versions: ["2.0.1", "3.0.0"]
  DIFFERENT files:
    2.0.1->3.0.0:
      * Deleted:
            bin
            builtin
            CHANGELOG
            configs
            dispatches
            doc
            environments
            fresh_rakefile
            helpers
            html
            lib
            MIT-LICENSE
(...)
      * Changed:
            bin/rails 7/17
              (!) New permissions: 100644 -> 100755
              (!) File is now executable!
              (!) Shebang probably added: #!/usr/bin/env ruby
```

If you would like to see all development dependencies for `prawn` since `0.1` version, let *gem-compare* expand the versions for you (`>=0.0` won't work as RubyGems asks for the latest spec only):

```bash
$ gem compare prawn '>=0.1' -k -a --development
Compared versions: ["0.1.0", "0.1.1", "0.1.2", "0.2.0", "0.2.1", "0.2.2", "0.2.3", "0.3.0", "0.4.0", "0.4.1", "0.5.0.1", "0.5.1", "0.6.1", "0.6.2", "0.6.3", "0.7.1", "0.7.2", "0.8.4", "0.11.1", "0.12.0", "0.13.0", "0.13.1", "0.13.2", "0.14.0", "0.15.0", "1.0.0", "1.1.0"]
  DIFFERENT development dependencies:
    0.12.0->0.13.0:
      * Added:
            pdf-inspector ["~> 1.1.0"] (development)
            coderay ["~> 1.0.7"] (development)
            rdoc [">= 0"] (development)
    0.13.2->0.14.0:
      * Deleted:
            rdoc [">= 0"] (development)
      * Added:
            yard [">= 0"] (development)
            rspec [">= 0"] (development)
            mocha [">= 0"] (development)
            rake [">= 0"] (development)
    0.14.0->0.15.0:
      * Added:
            simplecov [">= 0"] (development)
            pdf-reader ["~> 1.2"] (development)
    1.0.0->1.1.0:
      * Added:
            prawn-manual_builder [">= 0.1.1"] (development)
            rubocop ["= 0.20.1"] (development)
      * Updated:
            rspec from: [">= 0"] to: ["= 2.14.1"]
```

#### Platforms

*gem-compare* supports querying different gem platforms via standard `--platform` option. To compare
nokogiri gem on different platform run:

```bash
$ gem compare nokogiri 1.5.6 1.6.1 -ak --platform java # for JRuby
$ gem compare nokogiri 1.5.6 1.6.1 -ak --platform x86-mingw32 # on Windows
```

#### Gems from different source server

If you run your own gem source server, you can override the RubyGems.org default with
`--sources SOURCE1,SOURCE2` option.


### Supported options

To see all possible options run:

```bash
$ gem compare --help
```

## Requirements

Currently tested against RubyGems 3.x. Use the `0.0.7` release for RubyGems 2.x.


## Copyright

Made by [Josef Strzibny](https://strzibny.name).

Released under the MIT license. Feel free to contribute!
