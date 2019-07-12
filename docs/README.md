<p align="center">
  <img src="https://github.com/marceloboeira/kurz/blob/master/docs/logos/github_2.png?raw=true" width="400">
  <p align="center">A URL Shortener so there are no URL Shorteners<p>
</p>

## Endpoints

* `:8000/` - root page, it renders the `dist/index.html`.
* `:8000/api/hello` - sample endpoint for testing purposes.

# Contributing

TODO: Add a contributing guide

## Available commands

```
help         Lists the available commands
test-all     Tests everything, EVERYTHING
docker-build Builds the core docker image compiling source for Rust and Elm
docker-test  Tests the latest docker generated image
```

## Structure

```
├── LICENSE - License file
├── Makefile - Frequent commands/Tasks
├── api - Rust application root folder
│   ├── Cargo.lock
│   ├── Cargo.toml
│   └── src
│       └── main.rs - Rust application entrypoint
├── docker - Docker build root folder
│   └── Dockerfile
│   └── .dockerignore - Ignore file for docker context
│   └── goss.yaml - Test declaration for the release docker image
├── docs
│   ├── README.md - This file.
│   └── logos - Logos folder
└── ui - Elm application root folder
    ├── dist
    │   ├── assets
    │   │   └── application.js - Elm application binary¹
    │   └── index.html - Static index.html file
    ├── elm.json
    └── src
        └── Application.elm - Elm application entrypoint
```

¹ Only present after build

### Docker Image

In order to deliver a sweet Rust http backend server and statically-served Elm user-interface we have to use a 3-way multi-stage build.

1. Build the backend api, targeting rust to `x86_64-unknown-linux-musl` (for Linux Alpine). -> `kurz binary`
2. Build the elm application `ui/dist/assets/application.js`
3. Blend the compiled binary and the static assets all into a extremelly small `alpine` image.

The resulting image has around 10MB.

The resulting image has the following structure:

```
home/
├── kurz - compiled binary
└── ui - user-interface related content
    ├── assets - compiled assets
    │   │── application.js - compiled Elm application
    │   └── ...
    └── index.html - static html file
```

When you access `kurz:8000/` it renders the `index.html` file.

#### Docker Testing

We're using `dgoss` to test our docker-images, see: https://github.com/aelsabbahy/goss/.

Check `docker/goss.yaml` for more info.


### Reference

* https://blog.codinghorror.com/url-shortening-hashes-in-practice/
* https://www.youtube.com/watch?v=JQDHz72OA3c
* https://michiel.buddingh.eu/distribution-of-hash-values
* https://engineering.checkr.com/introducing-flagr-a-robust-high-performance-service-for-feature-flagging-and-a-b-testing-f037c219b7d5
