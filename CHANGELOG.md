## 0.2.0

2025-08-21
Breaking change:
The default behavior of web cache busting is changed. Previously, to bust the cache, we used the appliation's version. e.g. `?v=0.12.3`. Now, the default behavior is adding a random hash to bust the cache on every build. You can control the behvavior using the `query_param_versioning_type` field of web.

## 0.1.5

2025-08-16
- Added example
- Adjusted docs
- Confirmed the web caching for `Flutter v3.35.1`

## 0.1.4

2025-07-28
- Fixed the local paths on windows and linux

## 0.1.3

2025-07-17
- Fixed the race condition for logging the web cache bust

## 0.1.2

2025-07-17
- Added the `xcode_derived_data_path_env_key` property to the config which is the name of the environmental variable having the path to XCode derived data as value.
- Improved the printing of the text to the terminal

## 0.1.1

2025-07-13
- Added the `post_build_command` which is a command to be run after all platforms are built

## 0.1.0

2025-07-12
- Initial release
