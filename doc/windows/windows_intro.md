# Windows

Windows build is supported via the `pubspec` config.

```yaml
build_pipe:
  workflows:
    default:
      platforms:
        windows:
          build:
            build_command: flutter build windows
```

At this moment, besides the build command and the `pre_command` and `post_command` hooks that every platform has, we do not provide any Windows specific config. Read about the hooks in the [run order & hooks doc](../hooks/hooks_intro.md).