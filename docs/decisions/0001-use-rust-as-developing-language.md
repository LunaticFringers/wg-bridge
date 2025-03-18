---
# These are optional metadata elements. Feel free to remove any of them.
status: proposed
date: 2025-03-18
decision-makers:
  - '@luca-c-xcv'
  - '@feed3r'
  - '@giubacc'
---

# Use Rust as developing language

## Context and Problem Statement

**wg-bridge** is currently developed in bash, but this language is less
flexible, less robust, and difficult to maintain for a complex tool.
Moreover, Bash is not designed for writing encapsulated code, which is becoming
a necessary requirement as development progresses.

<!-- This is an optional element. Feel free to remove. -->
## Decision Drivers

* Rust is more flexible.
* Rust is more robust.
* Rust is designed for writing complex code.
* Rust is compiled and does not require an interpreter in the user's
  environment.
* Rust is more performant.

## Considered Options

* Python
* Go
* Perl

## Decision Outcome

The most notable feature is the compiled language.
Other notable features are reliability, performance.
Another reason is the desire to learn Rust.

<!-- This is an optional element. Feel free to remove. -->
## Pros and Cons of the Options

### Python

* Good, because it is simple to use
* Good, because it has many libraries
<!-- use "neutral" if the given argument weights neither for good nor bad -->
* Bad, because it requires the interpreter

### Go

* Another good choice to use as an alternative to Rust

### Perl

* Good, because it is simple to use
* Bad, because it requires its interpreter
