# Flua [![codecov](https://codecov.io/github/prncss-xyz/flua/graph/badge.svg?token=6E4BXIU81Q)](https://codecov.io/github/prncss-xyz/flua)

In lua, [iterators](https://www.lua.org/pil/7.1.html) are a fundamental concept.

Flua is a small library to compose lua iterators in a functional style.

Main motivation for this library was to allow monadic operations (`chain`, `flatten`), which are not supported by [luafun](https://github.com/luafun/luafun).

Iterators can return multiple values. Most of the library thrives to manage these values on the stack (to the cost of slightly less readable code). However, there are a few cases where it cannot be done. In those cases we provide a generic method (e.g. `last`) that uses the heap, and fix argument methods (e.g. `last1`, `last3`) which use the stack (and are hence faster). It is also the case for functions `scan` and `fold`. `zip` also suffers the same inconvenient (for the first argument only) and we might provide an equivalent method if we ever meet the need it.

The library targets lua jit (fork of lua 5.1) and do not work with lua 5.4 or later.

Definition of functions are given in comments, but we use names which are pretty standard amongst similar libraries.
