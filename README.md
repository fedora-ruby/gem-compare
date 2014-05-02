# WORK IN PROGRESS

# gem-compare

## Description

*gem-compare* is a RubyGems plugin that compares different versions of the specified gem. It can help you to track changes in metadata through the time, see how dependencies were evolving and spot important changes in gem's files such as shebang or permissions modifications.

## Installation

You can install `gem-compare` as a gem from RubyGems.org:

```
gem install gem-compare
```

Once it's stable I will package it for Fedora.

## Usage

By default, `gem-compare` compares specified versions of the given gem and includes only changes in the final report. If it's supposed to compare file lists it will need to download the gems, otherwise it just downloads the specs. If you want to keep the downloaded `.gem` files, use `-k` (as 'keep') option. If you want to see the full report use `-a` (as 'all') switch:

```
$ gem compare rails 3.0.0 4.0.0 -k -a
Fetching: rails-3.0.0.gem (100%)
Fetching: rails-4.0.0.gem (100%)
Compared versions: ["3.0.0", "4.0.0"]
  SAME author
  SAME authors
  SAME bindir
  SAME cert_chain
  DIFFERENT date:
    3.0.0: 2010-08-29 00:00:00 UTC
    4.0.0: 2013-06-25 00:00:00 UTC
  SAME description
  SAME email
  SAME executables
  SAME extensions
  SAME has_rdoc
  SAME homepage
  SAME license
  SAME licenses
  SAME metadata
  SAME name
  SAME platform
  SAME post_install_message
  SAME rdoc_options
  SAME require_paths
  DIFFERENT required_ruby_version:
    3.0.0: >= 1.8.7
    4.0.0: >= 1.9.3
  DIFFERENT required_rubygems_version:
    3.0.0: >= 1.3.6
    4.0.0: >= 1.8.11
...
```

You can also specify what you are interested in by using -p (as 'param') option:

```
$ gem compare activesupport 4.0.0 4.1.0 -p 'runtime_dependency'
Compared versions: ["4.0.0", "4.1.0"]
  DIFFERENT runtime dependencies:
    4.0.0->4.1.0:
      * Deleted:
            multi_json ["~> 1.3"]
      * Added:
            json [">= 1.7.7", "~> 1.7"]
      * Updated:
            i18n from: [">= 0.6.4", "~> 0.6"] to: [">= 0.6.9", "~> 0.6"]
            tzinfo from: ["~> 0.3.37"] to: ["~> 1.1"]
            minitest from: ["~> 4.2"] to: ["~> 5.1"]

```

### Supported options

Will be updated.

## Requirements

Currently tested against RubyGems 2.x.

## Copyright

Released under the MIT license. Feel free to contribute!
