# nimAGG
 * [![Build Status][badge-nimagg-travisci]][nimagg-travisci]
 * [![Build status][badge-nimagg-appveyor]][nimagg-appveyor]

This project relying on recent bugfixes of Nim compiler, so you must use devel
branch on Github to compile this project.

Those bugfixes are:
  - proc parameter shadowing inside template
  - mixin inside generic proc generated by template
  - inheriting generic object
  - inheriting partial specialization generic object
  - type alias via template
  - call proc of partial/specialized/some generic object by subtype object
  - generic proc forward declaration
  - generic object with generic field(s) type obtained via template*

  
## How to build demos?

```text
cd examples
nim e build.nims
```

[nimagg-travisci]: https://travis-ci.org/jangko/nimAGG
[nimagg-appveyor]: https://ci.appveyor.com/project/jangko/nimagg
[badge-nimagg-travisci]: https://travis-ci.org/jangko/nimAGG.svg?branch=master
[badge-nimagg-appveyor]: https://ci.appveyor.com/api/projects/status/github/jangko/nimAGG?svg=true