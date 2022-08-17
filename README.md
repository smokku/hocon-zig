# hocon-zig

Library providing [Zig](https://ziglang.org) support for the [HOCON configuration file format][1].

Parser is based on Serge Zaitsev's [jsmn](https://github.com/zserge/jsmn) JSON parser.

## Spec Coverage

<https://github.com/lightbend/config/blob/master/HOCON.md>

- [x] parsing JSON
- [ ] comments
- [ ] omit root braces
- [ ] key-value separator
- [ ] commas are optional if newline is present
- [ ] whitespace
- [ ] duplicate keys and object merging
- [ ] unquoted strings
- [ ] multi-line strings
- [ ] value concatenation
- [ ] object concatenation
- [ ] array concatenation
- [ ] path expressions
- [ ] path as keys
- [ ] substitutions
- [ ] includes
- [ ] conversion of numerically-indexed objects to arrays
- [ ] allow URL for included files
- [ ] duration unit format
- [ ] period unit format
- [ ] size unit format

## License

This software is distributed under [0BSD license](https://opensource.org/licenses/0BSD),
so feel free to integrate it in your commercial products.

[1]: https://github.com/lightbend/config/blob/master/HOCON.md
