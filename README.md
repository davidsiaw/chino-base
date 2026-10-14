# chino-base

This repository is a starting point for new [chino](https://github.com/davidsiaw/chino) apps. It contains a small Cappuccino app, a test suite and CI.

## Starting a new app

Clone the repository and give the app a name:

```sh
bin/rename MyApp
```

This changes the name in the `Chinofile` and in the smoke spec. You can then edit the other values in the `Chinofile`, such as the author and the company name.

## Running the app

The app runs in a container managed by heighliner. The first time, choose a name for the environment and initialise it:

```sh
heighliner init myapp
```

After that, start the app with the following command:

```sh
heighliner up
```

The app is served on port 4444.

## Running the tests

The tests run inside the app container. Run `heighliner up` first, so that the container has your latest changes.

```sh
heighliner login rspec
heighliner login ojtest
heighliner login build
```

The first command runs the browser specs, the second runs the unit tests, and the third checks that the release build succeeds.

## Further reading

More detailed notes are in the [docs](docs/README.md) folder.
