# chino

chino (gem version 0.3.3) is a small Sinatra app plus a build script
around the Cappuccino toolchain. Its source is short, so read it when
in doubt. Run `gem fetch chino -v 0.3.3 && gem unpack chino-0.3.3.gem`
and look at `exe/chino`, `lib/chino/config.rb` and
`lib/chino/website.rb`.

## Dev server (`bundle exec chino`)

- It binds `0.0.0.0:4444`. The port is hardcoded and cannot be changed,
  which is why the Dockerfile, Heighliner.config and the specs all use
  4444.
- `/` serves `index-debug.html`. The browser then loads `main.j` and
  compiles the Objective-J itself. A syntax error therefore never shows
  up on the server; the page simply fails to boot. The first load takes
  a few seconds because AppKit is large, which is why Capybara waits up
  to 15 seconds.
- Sinatra 4 ships without a web server, so the Gemfile includes `puma`
  and `rackup`. Removing them breaks the dev server but not the build.
- Host authorization is disabled, so the server accepts any hostname,
  including `<env>-app`, an IP address or the proxy name.
- The server returns any file in the project directory, not just the
  app. For paths that do not exist it falls back to a recursive glob
  (`first/**/rest`). Do not run it in a directory that holds secrets,
  and do not expose it outside development.

## Release build (`chino build`, run it through `scripts/build`)

- chino copies every `./**/*.j` file and renders every `./**/*.j.erb`
  file into `temp/`. It then adds its bundled frameworks (Foundation,
  AppKit and its own `Chino` framework) and runs `jake release`. The
  result goes to `build/`, which contains `index.html`,
  `Browser.environment/` and the rest of the app.
- `jake` comes from the npm package `@objj/cappuccino`, which the
  Dockerfile installs globally. You do not need to clone the Cappuccino
  repo, even though older instructions say to.
- chino exits 0 even when compilation fails, because it never checks
  jake's exit status. A broken `.j` file produces lines like
  `ERROR line N in file:...` in the log and a `build/` directory with no
  app in it. `scripts/build` looks for those lines and checks that the
  output exists, so always use it instead of calling `chino build`
  directly.
- chino compiles every `.j` file in the tree and has no exclude list.
  The only paths it skips are those starting with `./.` (hidden paths).
  Left alone, it would compile `tests/unit/*.j` into the app, and the
  build would fail with `Could not load file at OJUnit/OJTestCase.j`.
  `scripts/build` renames `tests/` to a hidden name during the build and
  restores it when the script exits. Any other `.j` files in the tree,
  such as a vendored reference project, are compiled too and must be
  moved out of the way.
- The build writes `build/` and `temp/` in the project root. Both are
  gitignored.

## Objective-J notes

- Use `@import <Framework/File.j>` for frameworks and
  `@import "File.j"` for project files, with a path relative to the
  importing file.
- chino renders `.j.erb` files with ERB at serve and build time, with
  the Chinofile config in scope. This is where compile-time constants
  belong.
- `chino gen <type> <Name>` generates a class from chino's templates.
