# DSL::Maker

[![Gem Version](https://img.shields.io/gem/v/dsl_maker.svg)](https://rubygems.org/gems/dsl_maker)
[![Gem Downloads](https://img.shields.io/gem/dt/dsl_maker.svg)](https://rubygems.org/gems/dsl_maker)
[![Yard Docs](http://img.shields.io/badge/yard-docs-blue.svg)](http://rubydoc.info/github/robkinyon/ruby-dsl-maker)

[![Build Status](https://img.shields.io/travis/robkinyon/ruby-dsl-maker.svg)](https://travis-ci.org/robkinyon/ruby-dsl-maker)
[![Code Climate](https://img.shields.io/codeclimate/github/robkinyon/ruby-dsl-maker.svg)](https://codeclimate.com/github/robkinyon/ruby-dsl-maker)
[![Code Coverage](https://img.shields.io/codecov/c/github/robkinyon/ruby-dsl-maker.svg)](https://codecov.io/github/robkinyon/ruby-dsl-maker)
[![Inline docs](http://inch-ci.org/github/robkinyon/ruby-dsl-maker.png)](http://inch-ci.org/github/robkinyon/ruby-dsl-maker)


Writing single-level Ruby-like DSLs is really easy. Ruby practically builds them
for you with a little meta-programming. [Docile](https://github.com/ms-ati/docile)
makes it ridiculously easy and there are nearly a dozen other modules to do so.

Unfortunately, writing multi-level DSLs becomes repetitive and overly complex.
Which is dumb. Multi-level DSLs are where the sweetness lives. We write DSLs in
order to make things simpler for ourselves, particularly when we want to have
less-experienced individuals able to make changes because they have the business
or domain knowledge. Limiting everything to single-level DSLs makes no sense.

`DSL::Maker` provides a quasi-DSL-like structure that allows you to easily build
multi-level DSLs and handle the output.

## Usage

### Single-level DSLs

In its documentation, [Docile](https://github.com/ms-ati/docile) has a DSL that
builds pizza. An example would look like:

```ruby
@sauce_level = :extra

pizza do
  cheese
  pepperoni
  sauce @sauce_level
end
#=> #<Pizza:0x00001009dc398 @cheese=true, @pepperoni=true, @bacon=false, @sauce=:extra>
```

The PizzaBuilder code (via Docile) looks like:

```ruby
Pizza = Struct.new(:cheese, :pepperoni, :bacon, :sauce)

class PizzaBuilder
  def cheese(v=true); @cheese = v; self; end
  def pepperoni(v=true); @pepperoni = v; self; end
  def bacon(v=true); @bacon = v; self; end
  def sauce(v=nil); @sauce = v; self; end
  def build
    Pizza.new(!!@cheese, !!@pepperoni, !!@bacon, @sauce)
  end
end

PizzaBuilder.new.cheese.pepperoni.sauce(:extra).build
#=> #<Pizza:0x00001009dc398 @cheese=true, @pepperoni=true, @bacon=false, @sauce=:extra>
```

But, this doesn't actually implement the DSL. That is left for another snippet:

``` ruby
def pizza(&block)
  Docile.dsl_eval(PizzaBuilder.new, &block).build
end
```

And it's not quite clear where to actually put this code so that you can ship this
DSL like Chef or Sinatra.

You would implement the same DSL using DSL::Maker as so:

```ruby
class PizzaBuilder < DSL::Maker
  add_entrypoint(:pizza, {
    :cheese => Boolean,
    :pepperoni => Boolean,
    :bacon => Boolean,
    :sauce => String,
  }) do
    Pizza.new(cheese, pepperoni, bacon, sauce)
  end
end

pizza = PizzaBuilder.parse_dsl(dsl_block)
```

Now, you accept the strings (possibly from `IO.read()`) and magically get the
result of your DSL.

(The PizzaBuilder is used in the test suite in `spec/single_level_spec.rb`.)

### Multi-level DSLs

So far, this isn't that impressive - slightly better type coercion and a method
for handling the parsing of a string isn't much to crow about.

```ruby
Person = Struct.new(:name, :mother, :father)

class FamilyTree < DSL::Maker
  add_entrypoint(:person, {
    :name => String,
    :mother => generate_dsl({
      :name => String,
    }) do
      Person.new(name, nil, nil)
    end,
    :father => generate_dsl({
      :name => String,
    }) do
      Person.new(name, nil, nil)
    end,
  }) do
    Person.new(name, mother, father)
  end
end

john_smith = FamilyTree.parse_dsl("
  person {
    name 'John Smith'
    mother {
      name 'Mary Smith'
    }
    father {
      name 'Tom Smith'
    }
  }
")
```

Refactor that a bit and we end up with:

```ruby
class FamilyTree < DSL::Maker
  parent = generate_dsl({
    :name => String,
  }) do
    Person.new(name)
  end

  add_entrypoint(:person, {
    :name => String,
    :mother => parent,
    :father => parent,
  }) do
    Person.new(name, mother, father)
  end
end
```

There's no limit to the number of levels you can go define.

### Handling Arguments

We can improve the family tree DSL a bit by handling arguments. An example works
best to explain.

```ruby
Person = Struct.new(:name, :age, :mother, :father)
class FamilyTree < DSL::Maker
  parent = generate_dsl({
    :name => String,
    :age  => String,
  }) do |*args|
    default(:name, args)
    Person.new(name, age)
  end

  add_entrypoint(:person, {
    :name => String,
    :age  => String,
    :mother => parent,
    :father => parent,
  }) do |*args|
    default('name', args, 0)
    Person.new(name, age, mother, father)
  end
end

john_smith = FamilyTree.parse_dsl("
  person 'John Smith' do
    age 20
    mother 'Mary Smith' do
      age 50
    end
    father {
      name 'Tom Smith'
      age 49
    }
  end
")
```

The result is exactly the same as before.

### Handling multiple items

Chef's recipe files have many entries of different types in them. It doesn't do
you any good if you can't do the same thing.

```ruby
Car = Struct.new(:make, :model)
Truck = Struct.new(:make, :model)

class VehicleDSL < DSL::Maker
  add_entrypoint(:car, {
    :make => String,
    :model => String,
  }) {
    Car.new(make, model)
  }

  add_entrypoint(:truck, {
    :make => String,
    :model => String,
  }) {
    Truck.new(make, model)
  }
end

vehicles = VehicleDSL.parse_dsl("
  car {
    make 'Honda'
    model 'Civic'
  }

  truck {
    make 'Ford'
    model 'F150'
  }
")
```

`vehicles` is an `Array` with a `Car` and a `Truck` in it, in that order. If your
DSL snippet has only one item, you get back that item. If it has multiple items,
you get back an `Array` with everything in the right order.

## API

### Class Methods

DSL::Maker provides three class methods - two for constructing your DSL and one
for parsing your DSL.

* `add_entrypoint(Symbol, Hash={}, Block)`

This is used in defining your DSL class to create an entrypoint - the highest
level of your DSL. `add_entrypoint()` will create the right class methods for
Docile to use when `parse_dsl()` is called. It will also invoke `generate_dsl()`
with the Hash you give it to create the parsing.

* `generate_dsl(Hash={}, Block)`

This is used in defining your DSL to describe the innards - the guts that actually
have meaning. Once this level has been completed, the Block will be called and the
return value provided back to the name.

* `build_dsl_element(Class, String, Type)`

This is normally called by `generate_dsl()` to actually construct the DSL element.
It is provided for you so that you can create recursive DSL definitions. Look at
the tests in `spec/multi_level_spec.rb` for an example of this.

* `parse_dsl(String)`

You call this on your DSL class when you're ready to invoke your DSL. It will
return whatever the block provided `add_entrypoint()` returns.

In the case of multiple DSL entrypoints (for example, a normal Chef recipe),
`parse_dsl()` will return an array with all the return values in the order of
invocation.

### Coercions

There are three defined coercions for use within `generate_dsl()`:

  * String - This takes any string.
  * Boolean - This takes whatever you give it and returns the truthiness of it.
  * `generate_dsl()` - This descends into another level of DSL.

You will be able to add your own coercions in a forthcoming version of DSL::Maker.

### Helpers

There is one pre-defined helper.

* `default(String, Array, Integer=0)`

This takes a method name and the args provided to the block. It then ensures that
the method defaults to the value in the args at the optional third argument.

## Installation

``` bash
$ gem install dsl_maker
```

## Links
* [Source](https://github.com/robkinyon/ruby-dsl-maker)
* [Documentation](http://rubydoc.info/gems/ruby-dsl-maker)
* [Bug Tracker](https://github.com/robkinyon/ruby-dsl-maker/issues)

## Status

Works on [all ruby versions since 1.9.3](https://github.com/robkinyon/ruby-dsl-maker/blob/master/.travis.yml), or so Travis CI [tells us](https://travis-ci.org/robkinyon/ruby-dsl-maker).

## Note on Patches/Pull Requests

  * Fork the project.
  * Setup your development environment with:
      `gem install bundler; bundle install`
  * Make your feature addition or bug fix in a branch.
  * Add tests for it. This is important so I don't break it in a future version
      unintentionally. Plus, I maintain 100% code coverage.
  * Commit.
  * Send me a pull request.
    * I will only accept PRs from branches, never master.

## Copyright & License

Copyright (c) 2015 Rob Kinyon
