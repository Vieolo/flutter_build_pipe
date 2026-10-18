# Logging

If `generate_log` field is set to true (default: true), all the steps of a run, along with the output of their commands, will be recorded in a log file in `.flutter_build_pipe/logs/{version}/{timestamp}.log`.

If you run `build_pipe:build` with the same version multiple times, the previous logs would not be overwritten and a new one, with the latest timestamp will be created.

Add `.flutter_build_pipe/` to your `.gitignore` for git to ignore this folder.

## The log file

The log file has one section per step, in the order they run. Each line of a section starts with the time since the step has started, and the section ends with the outcome of the step. A summary of the whole run is at the end of the file.

The steps are numbered in order. The steps of a platform with hooks or extra steps, such as the cache bust of web, are numbered under the platform, e.g. `[3.2] Build › Web › Cache bust (hash)`. The section of a hook also has the env variables given to it.

```
command: build
workflow: default
version: 1.2.0+12
started: 2026-10-18T10:00:00.000000

========================================================================
[2] Pre-build › flutter pub get
------------------------------------------------------------------------
[00:00.0] $ flutter pub get
[00:00.4]   Resolving dependencies...
[00:01.9]   Got dependencies!
[00:02.0]   exit code: 0
------------------------------------------------------------------------
succeeded - 2.0s

...

========================================================================
1 of 4 steps failed - 3m 12s
  √ [1] Pre-build › flutter clean - 1.1s
  √ [2] Pre-build › flutter pub get - 2.0s
  X [3] Build › iOS - 1m 2s - exited with code 65
  √ [4] Build › Web - 1m 4s
    √ [4.1] Build › Web › Build - 1m 3s
    √ [4.2] Build › Web › Cache bust (hash) - 0.1s
```

The values hidden from the output, such as the API keys of App Store Connect, are replaced by `REDACTED` in both the terminal and the log file.
