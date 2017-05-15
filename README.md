# TypeScript Monkey [![Build Status](https://api.travis-ci.org/markeissler/typescript-monkey.svg?branch=feature/typescript-monkey)](https://travis-ci.org/markeissler/typescript-monkey) [![Coverage Status](https://coveralls.io/repos/github/markeissler/typescript-monkey/badge.svg?branch=feature%2Ftypescript-monkey)](https://coveralls.io/github/markeissler/typescript-monkey?branch=feature%2Ftypescript-monkey)

This is a TypeScript adapter for the Rails asset pipeline.

>BETA: TypeScript Monkey is currently in pre-release. That doesn't mean it's not ready for production, it just means it
hasn't been tested by a large audience yet. The more the merrier and the faster we get to v1.0. Install it, open issues
if you find bugs.

## Overview

TypeScript Monkey let's you use TypeScript (files with a `.ts` extension) wherever you can use JavaScript (`.js`) files.
This includes support for pre-processing other template formats. For instance, you can also create `.ts.erb` files. In
essence, TypeScript is a first class citizen on Rails!

For more information on TypeScript visit the [TypeScript](http://www.typescriptlang.org/) homepage.

## Requirements

### Node.js

One of the goals of __TypeScript Monkey__ is to reduce the dependence on third-party gems which aren't under active
development. This gem does require that [Node.js]() has been installed either globally or locally. Specifically,
TypeScript support (language and compiler) is provided by the TypeScript package for Node. <u>If installed locally,
it is not recommended that you commit your `node_modules` directory to source control.</u>

If you're not familiar with Node.js don't worry, it's not that scary.

To install Node.js support, our recommendation is to use an appropriate package manager:

[Installing Node.js via package manager](https://nodejs.org/en/download/package-manager/)

#### Confused about package managers?

For MacOS, our recommendation is [Homebrew](https://brew.sh/); for Windows your best bet is probably [Chocolatey](http://chocolatey.org/).
Go and install a package manager first, then install node, then come back here. If you're on Linux, well, the assumption
is that you probably know what you're doing already!

## Installation

### Adding a Node Package Definition (package.json) File

The first step is to create a Node.js `package.json` file at the root of your Rails project. You may have created this
file already for other uses, if so, then you will need to merge in the following dependencies:

```json
  "dependencies": {
    "@types/jquery": "^2.0.41",
    "@types/node": "^7.0.14",
    "typescript": "^2.3.1"
  }
```

If you don't have an existing `package.json` you can use the `example_package.json` file in the [contrib](./contrib/)
directory as a starting point. Copy the file to the `root` of your Rails project. __Be sure to rename the file as simply
"package.json".__

The second step is to install some TypeScript dependencies with the Node.js package manager (`npm`):

```sh
    >npm install
```

The package manager will determine and install the dependencies noted above by reading the `package.json` file.

### Adding the Gem to your Rails Project's Gemfile

Update your Gemfile to include the following statement:

```ruby
# typescript support in the asset pipeline!
gem 'typescript-monkey', '~> 0.9.0'
```

Then run bundler:

```sh
    >bundle install
```

Finally, restart your Rails server to load the __Typescript Monkey__ gem.

## Usage

### TypeScript Triple-Slash Directives

__Typescript Monkey__ parses Typescript files and examines __Triple-Slash__ directives (also known as __reference__ tags
or comments). For each directive, a Sprockets dependency relationship will be created so that a change in a dependency
will trigger Sprockets to re-process the dependent file as well.

>NOTE: __TypeScript Monkey__ does not currently support _import_ directives. See [Features Not Yet Implemented (but on the way)](#pending-features)
for more information.

Learn more about __Triple-Slash__ directives by referring to the following secction of the __Typescript Spec__:

[Source Files Dependencies](https://github.com/teppeis/typescript-spec-md/blob/master/en/ch11.md#1111-source-files-dependencies)

### In the Asset Pipeline (Sprockets)

Typical usage is the same as with JavaScript. That is, you will need to add your TypeScript files to `.js` manifest
files just like you would with JavaScript. For instance, in the below example let's pretend that you have created the
following:

```sh
app/assets/javascripts/
├── application.js
├── my-typescript-files
    └── superduper.ts
```

__superduper.ts__

```ts
class SuperDuper {
    public message(message: string): void {
        const body: HTMLBodyElement = document.getElementsByTagName("body")[0];
        const element = document.createElement("p");
        element.innerHTML = `${message}`;
        body.appendChild(element);
    }
}

$(() => {
    const superduper = new SuperDuper();
    superduper.message("TypeScript at work.");
});
```

Then, your `application.js` file might look like this:

__application.js__

```js
// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require jquery-ui/core
//= require bootstrap-sprockets
//= require my-typescript-files/superduper

```

### Embedded in \<script\> tags

Yes, you can embeded TypeScript in your templates just like JavaScript! All that's required is __TypeScript Monkey__
DYnamic Runtime Transpiler (aka __"dyrt"__). For example, let's say you had the following snippet in your template:

```erb
    <script type="text/typescript">
        class Alert {
            public alert(message: string): void {
                alert(`An important message: ${message}`);
                return;
            }
        }
        let myAlert = new Alert();
        myAlert.alert("TypeScript is awesome!");
    </script>
```

The key is making sure your `<script>` tag type is set appropriately as above.

To transpile this script at runtime you will have to make __dyrt__ available at runtime. You will also need to make the
TypeScript library avaialable at runtime. Both of these dependencies can be resolved by adding the following to the end
of your `<body>` section:

```erb
    <%= javascript_include_tag 'transpiler_pkg' %>
```

After the page loads, __dyrt__ will parse all `<script>` tags, transpile the TypeScript objects and then append them
to the end of the page.

#### Loading the transpiler with other scripts

Yes, you could (theoretically) load the __Typescript Monkey__ transpiler along with you other script assets. If you
were to do that, you would then have to make the following call to trigger transpilation after DOM load:

```js
$(function() {
    var transpiler = new TypeScript::Monkey::Transpiler();
    transpiler.transpile();
);
```

The `transpile()` method will parse the page, remove all previous transpiled scripts, transpile each TypeScript object
and then append these scripts to the end of the page.

Pretty neat right? __BUT__ it's important to state that using __TypeScript Monkey__ this way may not offer the best
peformance. Also, you're inline scripts will not benefit from compression or minification. (The `transpiler_pkg` will,
however, be minified by Sprockets as usual).

### Updating Files and Clearing the Sprockets Cache

You've updated some of your TypeScript files and for some reason the changes aren't appearing. Hate it when that
happens, right? Do this:

```sh
    >rake tmp:clear
```

Then re-load your website. Sprockets will re-compile all of your TypeScript assets.

## Configuration

### App-level Configuration

The common application level configuration options that affect the __TypeScript Monkey__ gem are:

```txt
    #
    # Rails options...
    #
    config.app_generators.javascript_engine :typescript
    #
    # Sprockets options...
    #
    config.assets.enabled = true
    config.assets.js_compressor = :uglifier
    # set to "true" to disable Sprockets concatenation
    config.assets.debug = false
    # set to "true" to generate digests
    config.assets.digest = true
```

Since the above configuration options appear at the "app" level, changing these settings can affect gems in addition to
the __Typescript Monkey__ gem.

#### Setting Typescript as the Default Javascript Engine

If you plan on using TypeScript in your project exclusively (instead of plain `.js` or `.coffee` files), then you might
want to configure rails so that generators produce TypeScript template files by default. Add the following lines to
your `config/application.rb` file.

```ruby
module MyRailsApp
  class Application < Rails::Application
    ...
    # enable typescript in the asset pipeline
    config.app_generators.javascript_engine :typescript
    # enable the asset pipeline (!! Make sure assets are enabled !!)
    config.assets.enabled = true
    ...
  end
end
```

Alternatively, you can specify the JavaScript engine as a parameter to the rails generator command line:

```sh
    >rails generate controller MyController --javascript_engine=typescript
```

### Gem-level Configuration

The __TypeScript Monkey__ gem offers some level of configuration. These settings should be configured from within an
appropriate initializer. An `example_typescript.rb` initialization file can be found in the [contrib](./contrib/)
directory. Copy the file to the `app/config/initializers` directory of your Rails project. __Be sure to rename the file
as simply "typescript.rb".__

<a name="typescript-concatenation"></a>

#### Setting Traditional TypeScript Concatenation

During TypeScript transpilation (conversion of TypeScript to JavaScript), the TypeScript compiler will resolve
triple-slash directives (dependencies) and as a result transpile and concatenate the dependencies to each file as
needed. The upside is that each indivual file will contain its dependencies; the downside is that this usually results
in code duplication in a Rails environment.

__Typescript Monkey__ procedes with transpilation under the notion that all dependencies will be met at runtime. That
should be the case if you have setup your manifest files correctly (either the single `application.js` manifest file or
your own additional manifest files).

Still, if you have a reason to revert back to TypeScript's concatenation scheme then you can do so by enabling the
following __Typescript Monkey__ configuration in an initializer:

```ruby
Typescript::Monkey.configure do |config|
  # Configure Typescript::Monkey concatenated compilation
  config.compile = true
end
```

### Configuring a Logger

Adding a logger config is really only useful for debugging. Don't configure logging unless you fully understand the
paragraph that follows the configuraiton snippet:

```ruby
Typescript::Monkey.configure do |config|
  # Configure Typescript::Monkey logging (for debugging your app build)
  config.logger = Rails.logger
end
```

In general, you will see a lot of dependency "errors" generated by the logger. These "errors" (again, in quotes) are
passed through from the TypeScript compiler which doesn't understand that we're building a web site and that all of the
"missing" (also, in quotes) dependencies will be resolved at runtime!

<a name="pending-features"></a>

## Features Not Yet Implemented (but on the way)

This is a short-list of planned features:

1. Support for specifying compiler options from initializer.
2. Support for reading compiler options from `tsconfig.json`.
3. Support for "import" syntax.
4. Features I forgot to write down and can't think of right now...

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Authors

__TypeScript Monkey__ is the work of __Mark Eissler__ based on the original work of others as noted in the
[Attributions](#attributions) section below.

<a name=attributions></a>

## Attributions

__TypeScript Monkey__ is a fork of [typescript-rails](https://github.com/typescript-ruby/typescript-rails). A lot of
work has gone into producing __Typescript Monkey__ which offers better support for Sprockets and the way that Rails
works with assets to provide a more native and familiar experience. Still, without the prior work of __Klaus Zanders__
([klaus.zanders@gmail.com](klaus.zanders@gmail.com)) and __FUJI Goro__ ([gfuji@cpan.org](gfuji@cpan.org)) and also the
[coffee-rails](https://github.com/rails/coffee-rails) project, this gem would probably not exist.

## License

__Typescript Monkey__ is licensed under the MIT open source license.

---
Without open source, there would be no Internet as we know it today.
