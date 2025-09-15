## Web builds

#### Cache busting
The Flutter web builds, unlike more mature frontend frameworks, do not generate static files with unique URIs. As the result, the Flutter web apps are cached by the browser, practically preventing you from pushing an update to your existing users. You can read more about it [here](https://docs.flutter.dev/platform-integration/web/faq#why-doesnt-my-app-update-immediately-after-its-deployed)

To circumvent this, `build_pipe` will adjust your build files to append a query paramter with either a random hash or your application's version. Our solution is highly inspired by [github.com/doonfrs
flutter-build-web-cache-problem](https://github.com/doonfrs/flutter-build-web-cache-problem).

`build_pipe` can either add a random hash or the version number of your app as the query param. You can select the type of query param using `query_param_versioning_type`. This value is set to `hash` by default.

If `hash` is selected, a random hash is used on every build which means the browser will refetch the files on every build. A reproducible hash is currently not feasible as Flutter's output is slightly different on every build.

If `semver` is selected as the query param type, you are in control of the cache busting, as it relies on you, incrementing the version.

Please note that our approach is fragile by nature since it depends on the generated Flutter code which may change by a new update. At the time of writing, our code is tested on the following Flutter versions:
  - `Flutter v3.32.5`
  - `Flutter v3.35.1`

You can prevent this by setting the `add_version_query_param` field in your web platform to `false`