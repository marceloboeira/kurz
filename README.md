# 🚀 kurz
> A URL Shortener so there are no URL Shorteners

## Endpoints

* `:8000/` - root page, it renders the `dist/index.html`.
* `:8000/api/hello` - sample endpoint for testing purposes.

## Structure

```
├── LICENSE - License file
├── README.md - This file
├── api - Rust application root folder
│   ├── Cargo.lock
│   ├── Cargo.toml
│   └── src
│       └── main.rs - Rust application entrypoint
├── docker - Docker build root folder
│   └── Dockerfile
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

When you access `kurz/` it renders the index.html file.
