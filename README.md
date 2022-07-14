# Flua

Flua is a small library to compose lua iterators in a functionnal style inspired by RXjs and the likes.

Compared to [luafun](https://github.com/luafun/luafun), the code is much simpler (no conveniance wrappers) but it offers a chain function that is monadic (taking an iterator and a function from value to iterator and making it an iterator) wheras luafun do not offer an equivalent function, the chain function there being a function that makes a list of iterators into an iterator. The need for this method was one motivation behind flua. I am using flua in a real life project that is yet to be made public, and it is showing to be useful there.

Iterators can return multiple values. Most of the library trives to manage these values on the stack (to the cost of slightly less readable code). However, there are a few cases where it cannot be done. In those cases we provide a generic method (e.g. `last`) that uses the heap, and fix argument methods (e.g. `last1`, `last3`) which use the stack (and are hence faster). It is also the case for functions `folder` and `fold`. `zip` also suffers the same inconvenient (albeight for the first argument only) and we might provide an equivalent method if we ever meet the need.

The library targets lua jit (5.1) and do not work with lua 5.4.
