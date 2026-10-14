# CI

The workflows live in `.github/workflows/`. All of them run on pull
requests, on the merge queue and on pushes to `master`, using
GitHub-hosted `ubuntu-latest` runners.

| Workflow | What it runs |
|---|---|
| `ojtest.yml` | `scripts/ojtest` |
| `rspec.yml` | `scripts/rspec`, with a `selenium/standalone-chromium` service container |
| `build.yml` | `scripts/build`, as a compile check. There is no deploy target yet. |

Each workflow does the same two things:

1. It builds the same `Dockerfile` that heighliner uses, with
   `docker/build-push-action`. The layer cache is
   `type=gha,scope=chino-dev`, and all three workflows share it.
2. It runs the wrapper with `docker run`, using the wrapper as the
   `--entrypoint`. The checkout is bind-mounted over `/app`, so the run
   uses this commit's scripts and tests rather than the copy baked into
   the image. The container runs as `-u $(id -u)`, so files written to
   the workspace belong to the runner. `HOME` is set to `/tmp` because
   that user has no home directory in the image.

## rspec specifics

- The app container joins the job's network
  (`${{ job.container.network }}`) with `--network-alias chino-app`, and
  chrome reaches it by that alias. Setting only `--hostname` would not
  work, because other containers cannot resolve it.
- `CHROME_HOSTNAME=chrome` matches the name of the service container.
- Any environment variable that the SPA or the specs need must be
  passed to `docker run` with `-e`. A job-level `env:` entry does not
  reach the container. If you forget, the SPA still builds with empty
  constants, and the resulting failures look like app bugs.
- Selenium needs `--shm-size=2g`; without it Chromium crashes on large
  pages.

Any change to the Dockerfile invalidates the cache for all three
workflows. The first run after such a change does a full build: apt,
npm and two bundle installs.
