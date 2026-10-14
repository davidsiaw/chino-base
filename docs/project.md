# Project

`chino-base` is a starting point for new
[chino](https://github.com/davidsiaw/chino) apps. It contains a
Cappuccino (Objective-J) single-page app that the `chino` gem serves
and builds, a heighliner config for running it locally, a test suite,
and CI. To start a new app, clone the repo, change the values in the
`Chinofile`, and start writing `.j` files.

The app is chino's stock skeleton. It shows one window with a
"Hello World!" label and the standard menu bar.

## Layout

```
Chinofile            App metadata. `name` becomes the page title and bundle name.
main.j               Entry point. Calls CPApplicationMain.
AppController.j      The app.
Resources/           Static assets copied into the build.
Gemfile              App bundle: chino, plus puma and rackup because Sinatra 4 has no server.
Dockerfile           Dev image: Ruby, Node, the Cappuccino toolchain and the test gems.
Heighliner.config    Heighliner environment. Kaiserfile is a symlink to it.
scripts/             The rspec, ojtest and build wrappers. They are on PATH in the image.
tests/               Capybara specs in tests/spec and OJTest unit tests in tests/unit.
.github/workflows/   The ojtest, rspec and build workflows.
docs/                These notes.
```

## The dev image

The `Dockerfile` serves both as the heighliner app image and as the CI
test image.

- `build-essential` compiles the native extensions in puma and nio4r.
- `nodejs` and `npm` install `@objj/cappuccino`, which provides `jake`
  for `chino build` and `ojtest` for the unit tests.
- `curl` lets `scripts/rspec` check that chino is answering on port 4444.
- `/app/scripts` is on PATH. Because the wrappers are found in the
  source tree, a checkout bind-mounted over `/app` in CI runs its own
  copies rather than the ones baked into the image.
- The app gems and the test gems are installed as two separate bundles.

## Not included yet

The skeleton has no backend and no authentication, so the following
are left out. Add them when the app needs them.

- **An API mock for specs.** Use a small plain Rack app served by
  WEBrick inside the rspec process. It should return canned responses
  per path in FIFO order and record every request. Use plain Rack rather
  than Sinatra, because rack-protection rejects the SPA's cross-origin
  calls. When you count requests in a spec, remember that the browser
  sends a CORS preflight `OPTIONS` request before each real one.
- **Compile-time constants**, such as `*.j.erb` files that read an API
  host from the environment. Once these exist, the chino used by the
  specs must be started with test values, so `scripts/rspec` can no
  longer reuse a chino that is already running. Change it to kill the
  running chino, start one with the test environment, and check that the
  served constants file contains the test values before running specs.
- **Deployment**, for example syncing `build/` to S3 from CI with OIDC
  credentials.
