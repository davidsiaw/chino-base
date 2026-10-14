# Testing

There are two test suites and a build check. Each has a wrapper in
`scripts/`, and the wrapper is the only entry point, whether you run it
locally, in the container or in CI.

| Suite | Wrapper | What it tests | What it needs |
|---|---|---|---|
| Capybara/Selenium | `scripts/rspec [files] [rspec args]` | The real SPA in a real Chromium | chino on port 4444 and a Selenium Grid |
| OJTest | `scripts/ojtest [files]` | Pure-logic Objective-J, run in Node | `ojtest` from the npm package `@objj/cappuccino` |
| Build check | `scripts/build` | That `chino build` succeeds | `jake` from the same npm package |

```sh
heighliner up                                   # The container holds a copy of the source, so rebuild first.
heighliner login rspec
heighliner login rspec tests/spec/smoke_spec.rb -e 'menu bar'
heighliner login ojtest
heighliner login build
```

To watch the browser while specs run, connect a VNC client to port
5900 on the host. That port belongs to the shared chrome container.

## How rspec is wired

- The test gems (rspec, capybara and selenium-webdriver) live in their
  own bundle in `tests/Gemfile`, which keeps the app bundle small. The
  wrapper sets `BUNDLE_GEMFILE` to point at it. The lockfile lists Linux
  and macOS platforms so that nokogiri installs everywhere; keep them
  when you update it.
- The browser is remote, at `http://$CHROME_HOSTNAME:4444/wd/hub`. It
  loads the app from `http://$TEST_HOST:$TEST_PORT`, and `TEST_PORT`
  defaults to 4444. The chrome container resolves `TEST_HOST`, so it is
  never `127.0.0.1`.
- `scripts/rspec` reuses any chino already answering on port 4444, which
  in the heighliner container is the one started by the image's `CMD`.
  Otherwise it starts its own chino and stops it on exit. Reusing a
  running chino is only safe while the app has no compile-time
  configuration; see project.md.
- Specs run in random order, and monkey patching is disabled, so write
  `RSpec.describe` rather than `describe`.

## Writing specs: talk to Cappuccino, not the DOM

Cappuccino renders the UI as absolutely positioned divs, which
Capybara's text and element matchers handle badly.
`tests/cappuccino_helper.rb` instead walks the Cappuccino view hierarchy
through `objj_msgSend`. It provides these helpers:

- `wait_for_cappuccino` waits for the runtime to finish loading. Call it
  before any other helper, because the runtime loads asynchronously.
- `wait_for_cappuccino_text(str)` and `cappuccino_text_values` read the
  values of CPTextFields, including labels.
- `wait_for_cappuccino_button(title)`, `cappuccino_button_visible?(title)`
  and `click_cappuccino_button(title)` find buttons by title.
  `click_cappuccino_button` sends the button's action to its target, so
  no screen coordinates are involved.
- `cappuccino_main_menu_titles` and `cappuccino_menu_bar_visible?`
  inspect the menu bar.

Add new helpers to that file, built on `VIEW_WALK_JS`, rather than
writing JavaScript inline in specs.

Each of these gotchas has broken a build before:

- Do not rely on `have_text` or `page.text` after the UI has been
  rebuilt. After a view swap, Selenium's visible-text extraction can
  return only `"x"`, which is Cappuccino's offscreen text-measuring
  span, even though the UI is clearly on screen. `have_title` is fine;
  for page content, use the helpers above.
- A hidden view is not a removed view. A hidden `CPView` keeps its
  subviews attached, so checking whether a button is attached gives
  false positives. `cappuccino_button_visible?` also checks
  `isHiddenOrHasHiddenAncestor`.
- When you position the children of a view, use that view's `bounds`.
  `[view center]` is in the superview's coordinates, so it works the
  first time and breaks on the next relayout. When layout matters,
  assert on geometry in the spec.
- Every helper raises an error with a message when it times out. If a
  simple smoke check fails, suspect the harness before the app: check
  that chino is up, that chrome is reachable and that `TEST_HOST` is
  correct.

## Writing unit tests

Unit tests live in `tests/unit/` and cover pure-logic Objective-J
classes. They run in Node with the Objective-J runtime and Foundation
loaded. There is no DOM, no AppKit rendering, no `XMLHttpRequest` and
no chino. `tests/unit/SanityTest.j` is a canary: if it fails, the
toolchain itself is broken.

| Belongs in tests/unit | Belongs in tests/spec |
|---|---|
| State machines, timer bookkeeping, retry and backoff calculations | Anything that needs the SPA rendered |
| Parsers and formatters | Anything that talks to a server |
| Helpers that do not touch browser globals | End-to-end flows |

Do not add jsdom or stub out browser globals to make a test fit in
`tests/unit`. If a test needs the DOM, write a Capybara spec instead.

ojtest enforces these rules silently:

- The class name must match the file name. `FooTest.j` must define
  `@implementation FooTest : OJTestCase`, because ojtest derives the
  class from the file's basename. If they differ, ojtest prints
  "unable to get tests" and `Total tests: 0`, which is easy to miss in
  an otherwise green log.
- ojtest runs every method whose name starts with `test`. `setUp` and
  `tearDown` work as they do in XCTest. Assertions are class methods on
  `OJAssert`.
- Import the class under test by relative path, for example
  `@import "../../Foo.j"`.

```objc
@import <Foundation/Foundation.j>
@import <OJUnit/OJTestCase.j>
@import <OJUnit/OJAssert.j>

@implementation FooTest : OJTestCase
- (void)testSomething { [OJAssert assert:1 equals:1]; }
@end
```

The unit test files are not part of the app, but `chino build` would
compile them into it anyway. `scripts/build` hides `tests/` during the
build to prevent that; see chino.md.

## The wrapper scripts

`scripts/ojtest` is itself named `ojtest`, and `scripts/` is on PATH in
the image. A bare `ojtest` call inside it would therefore run the
wrapper again, forever. To avoid that, the wrapper finds the real
binary by skipping its own directory on PATH. It also prints what it is
about to run before the runtime loads, because ojtest prints nothing
for several seconds on a cold start and would otherwise look stuck.

`scripts/rspec` checks that `CHROME_HOSTNAME` and `TEST_HOST` are set.
Heighliner.config sets both inside the app container, and CI passes
them to `docker run`. The browser compiles the Objective-J on first
load and booting AppKit from cold takes a few seconds, which is why
`Capybara.default_max_wait_time` is 15 seconds.
