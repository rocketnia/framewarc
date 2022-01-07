# Framewarc

[![CI](https://github.com/rocketnia/framewarc/actions/workflows/ci.yml/badge.svg)](https://github.com/rocketnia/framewarc/actions/workflows/ci.yml)

Framewarc is an experimental system for writing portable code in the Arc programming language, in two related senses:

* Code that works across multiple Arc implementations.

* Code that avoids name collisions when combined with other Arc code.

Framewarc is also a collection of various libraries. These libraries eager use of some of Arc's more distinctive features, so these can be used to put new Arc implementations to the test.

These are complementary roles: As Framewarc has expanded to support more Arc implementations, it's been a source of test cases that has helped authors of Arc implementations achieve more compatibility. And as Arc implementation authors reach better compatibility, Framewarc's libraries can support more of them.

Arc is nevertheless an experimental language that carries no guarantee of stability or any kind of ongoing compatibility. Framewarc's modularity and portability goals are a bit foolish in this context, and Arc programmers who have a decisive idea of where they're going shouldn't let compatibility concerns get in their way.


## Features

* A fledgling Arc module system based on renaming of global variables (arc/modules/).

* A fledgling multimethod system built up within that module system (arc/multival/).

* A continuation-based backtracking library (arc/amb.arc).

* An extensive continuation-free, combinator-style iterator library (arc/iter.arc). This nevertheless supports continuation-based, coroutine-style iterator specification as well, as long as the language implementation supports it.

* Some more general-purpose modules the multimethod system relies on (arc/rules.arc and arc/utils.arc).

* An updated version of Andrew Wilcox's 'extend macro so that extensions can be removed and replaced (arc/extend.arc).

* Very small examples of using the module system, the multimethod framework, and the iteration library in application code (arc/examples/). These are basically the test cases.

The examples (and therefore the tests) don't cover everything Framewarc has to offer. Framewarc's Arc code is fairly well commented, so reading those comments is probably one of the best ways to get a good feel for things.


## Setup

First, get the Arc language by following the instructions at [https://arclanguage.github.io/](https://arclanguage.github.io/).

There are many versions of Arc, and Framewarc is designed to work with eight of them:

* [Anarki and Anarki Stable](https://arclanguage.github.io/), which
  are community-maintained versions of Arc.

* [Arc 3.1](http://arclanguage.org/item?id=10254), the last official
  release of Arc from August 2009, which has several known issues. (TODO: What about Arc 3.2?)

* [ar](https://github.com/awwx/ar), Andrew Wilcox's fork of Arc 3.1 which makes Arc use Racket's mutable cons cells instead of unsafely mutating the immutable ones. To use ar with Framewarc, load the "strings" library that comes with ar before loading Framewarc.

* The "arc/3.1" language of [the arc/nu project](https://github.com/arclanguage/arc-nu). The arc/nu project is Pauan's heavily refactored fork of ar.

* [Jarc](http://jarc.sourceforge.net/), JD Brennan's JVM implementation of Arc, which omits continuation support and has syntaxes for easy interaction with other JVM code, making it fit in with the JVM ecosystem.

* [Rainbow](https://github.com/conanite/rainbow), Conan Dalton's JVM implementation of Arc, optimized for speed.

* [Rainbow.js](https://github.com/arclanguage/rainbow-js), Rocketnia's port of Rainbow to JavaScript.

To load the core Framewarc libraries, first copy the Framewarc code into lib/framewarc/ or some other foler relative to your Arc directory, and then run:

```racket
(= fwarc-dir* "lib/framewarc/")
(load:+ fwarc-dir* "loadfirst.arc")
```

The loadfirst.arc code looks at the `fwarc-dir*` global variable to determine where to load other Framewarc files from, so you must set that variable as shown.

If you want to use a Framewarc module, you can do this:

```
(use-rels-as ut (+ fwarc-dir* "utils.arc"))
```

This will set `ut` to a namespace from which you can access all the things defined in utils.arc. A Framewarc namespace is just a macro that associates friendly symbols with less friendly global names, and you can use a namespace as follows:

```racket
; function calling with (ut.foo ...)
(ut.foldl (fn (a b) (+ (* 10 a) b)) 0 '(1 2 3))

; macro usage with (ut:foo ...), which also works for function calls
(ut:foldlet a 0
            b '(1 2 3)
  (+ (* 10 a) b))

; using ut.foo lookup somewhere other than function position
(iso (flat:map ut.tails (ut:tails:list 1 2 3))
     '(1 2 3  2 3  3
              2 3  3
                   3))

; using ut.foo as a settable place
(= old-tails ut.tails
   ut.tails [do (prn "DEBUG: entering utils.arc's 'tails")
                old-tails._])

; lookup of unevaluated global names with ut!foo
(mac afoldl (aval bval . body)
  `(,ut!foldlet a ,aval b ,bval ,@body))
```

If you're making an Arc application that uses Framewarc libraries, that should be enough to get started, but you may need to dig through some code to find the utilities you actually want to import this way.

If instead you're making a library, then you can continue using `use-rels-as` like this, but as long as you're using Framewarc already, you might consider making your library into a module. Take a look at a few of the modules included with Framewarc to see how to do that.


## Loading the examples

To load non-module files that use Framewarc, such as the Framewarc examples, use `loadfromwd` like so:

```racket
(loadfromwd:+ fwarc-dir* "examples/iter-demo.arc")
```

The Framewarc `loadfromwd` procedure is like `load`, but it sets the value of `load-dir*` so the file can refer to other files by relative paths.


## Installation with npm

Framewarc is also an npm package. This may make it easier to install and automate usage of Framewarc, despite the fact that it isn't a JavaScript library.

As an npm package, Framewarc has no JavaScript functionality (so no `require("framewarc")`), but it does have a single piece of CLI functionality: The command `framewarc copy-into <path>` copies Framewarc's Arc source files (the arc/ directory) into the given file path. This can be combined with [Rainbow.js](https://github.com/arclanguage/rainbow-js)'s CLI functionality to build a host directory with Rainbow.js's core Arc libraries and Framewarc in its `lib/` directory: `rainbow-js-arc init-arc my-arc-host-dir/ && framewarc copy-into my-arc-host-dir/lib/framewarc/`. Once you have these files in place, keep in mind that you'll still need to run `(= fwarc-dir* "lib/framewarc/")` and `(load:+ fwarc-dir* "loadfirst.arc")` to load Framewarc.

If you'd like to invoke the `framewarc copy-into <url>` command yourself from the command line, install framewarc globally:

```bash
npm install --global framewarc
```

If you'd just like to use it from your own package.json file's testing scripts, you can write the following to add it to your `devDependencies`:

```bash
npm install --save-dev framewarc
```


## Naming and history of the Framewarc project

Framewarc was originally called Lathe, a library named for its ability to *smooth out* various languages' rough edges in the pursuit of smoother overall programming language designs. The Lathe repository started out with a module system and libraries for Arc, basically as a dumping ground for Rocketnia's Arc programming projects. Then, Lathe branched out into having libraries for JavaScript and Racket as well as Rocketnia did more in those languages. The monorepo approach was originally justified by the potential that certain Lathe features might end up being bridges between multiple languages, but that never actually turned out to be the case.

Now, the Lathe libraries are organized into several independent repos, including [Lathe Comforts for Racket](https://github.com/lathe/lathe-comforts-for-racket) and [Lathe Comforts for JS](https://github.com/lathe/lathe-comforts-for-js). Framewarc could have been called "Lathe Modules for Arc" or "Lathe Comforts for Arc" and maintained under the [Lathe GitHub organization](https://github.com/lathe) along with the others. However, at this point, any potential development upon Framewarc will probably go into improving the Arc language's modularity options for the sake of the Arc community's ability to collaborate. Any development effort that crosses over with the rest of Lathe is likely to be incidental enough that Framewarc and Lathe don't need to be under the same banner.

Now Framewarc has its own name and repo, and it can be built upon without the extra JavaScript and Racket cruft getting in the way.
