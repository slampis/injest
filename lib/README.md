# Injest Client

## Changelog

### 0.1.7

- Support multiple strategies via the `INJEST_STRATEGY` env var, example: `INJEST_STRATEGY="stdout,http"`
- Added the `jsonout` strategy

### 0.1.6

- fix bad exception raise

### 0.1.5

- remove consumer

### 0.1.4

- add raw_search to Injest::HttpClient

ENV vars

- `INJEST_STRATEGY`: stdout by default
  
  Allowed values: Values: stdout | null | http | push
  
  `http` and `push` have the same behavior.

- `INJEST_ROOT`: a URL required with strategy `http` or `push`
- `INJEST_JWT`: a JWT required with strategy `http` or `push`
- `INJEST_CLIENT`: (optional) a string to bind to a specific client

## Release

```bash
./console.sh build
./console.sh release
```

## TODO:

- **use json output wich ideally should not depend on sidekiq**

- Customization with procs
- Tests: https://guides.rubygems.org/make-your-own-gem/#writing-tests