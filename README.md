# Flua

Flua is a toy library to explore functional programming in lua. [luafun](https://github.com/luafun/luafun) is serious project with similar scope.

Library works with both lua jit (5.1) and lua 5.4.

`iterator.lua` enables iterator composition in the style of RXjs but with lua iterators.

- Objectives were genericity (operate with arbitrary arity iterators) and code concision (without being obscure).
- Genericity implies creating tables to handle iterators' values where fix arity could be handled on the stack. This has performance cost. (See type benchmark `fold_bm.lua` for a peek at low performances!)
- Next step is to explore transducers.

`tbl.lua` proposes a few utilities for tables, returning lazy tables whenever possible.

`benchmark.lua` is a minimal lua benhmarker.

`dump.lua` is a dumping utility.

`utils.lua` regroups lua bits I needed some place to store.
