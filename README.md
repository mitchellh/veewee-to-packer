# Veewee to Packer Template Converter

This is a RubyGem that will translate [Veewee](https://github.com/jedi4ever/veewee)
templates to [Packer](http://www.packer.io) templates. The conversion is
_perfect_. If 100% of the functionality can't be translated to the Packer
template, a warning or error message will be shown, depending on if its
critical or not.

## Installation

Because Veewee is a RubyGem, so too is this converter. Installing using
RubyGems:

    $ gem install veewee-to-packer

## Usage

Usage is simple:

    $ veewee-to-packer original-template.rb
