# Logging

If `generate_log` field is set to true (default: true), all the commands and actions, along with their output will be recoreded in a log file in `.flutter_build_pipe/logs/{version}/{timestamp}.log`.

If you run `build_pipe:build` with the same version multiple times, the previous logs would not be overwritten and a new one, with the latest timestamp will be created.

Add `.flutter_build_pipe/` to your `.gitignore` for git to ignore this folder.