# Output

The `build` and `publish` commands can show a run in different ways, set by the `output` field of a workflow:

```yaml
build_pipe:
  workflows:
    default:
      # optional -- default: auto
      output: auto
```

| Value         | What it shows                                                                                     |
| ------------- | ------------------------------------------------------------------------------------------------- |
| `auto`        | `interactive` in a terminal, and `plain` anywhere else, including a CI                            |
| `interactive` | A tree of the steps that updates in place, with the last few lines of the output of the running step |
| `plain`       | One line per step, without moving the cursor                                                      |
| `verbose`     | Like `plain`, along with the whole output of the commands as they run                             |
| `json`        | One JSON object per line, for scripts and agents                                                   |

In every mode, when a step fails, the last lines of its output are shown along with the error. The whole output of every command is always in the [log file](../logging/logging_intro.md).

## Overriding the output

The `--bp-output` flag overrides the `output` of the workflow, without changing the config:

```bash
dart run build_pipe:build --workflow=release --bp-output=plain
```

The flag is not passed down to the build commands. It is prefixed with `bp-`, since Flutter has an `--output` option of its own.

## Detecting a CI

With `output: auto`, the run is shown as `plain` when the output is not a terminal, or when the `CI` env variable is set (to anything but `false` or `0`). Most CI services set it, and some of them give the command a terminal that only records the output, where redrawing the lines would fill the record with copies of them.

If the detection does not fit your setup, pass `--bp-output` explicitly.

## JSON

With `--bp-output=json`, the stdout has nothing but [JSON Lines](https://jsonlines.org): one JSON object per line, written as soon as it happens. A consumer can follow the run line by line, or read only the last line, which holds the outcome of the whole run.

```bash
dart run build_pipe:build --bp-output=json | tail -n 1
```

Each object has an `event` field. The fields are in `snake_case`, and the durations are in milliseconds.

### Identifying the steps

Each event of a step has the `number` and the `path` of the step:

- `number`: the position of the step, e.g. `"3"`, or `"3.2"` for the second step of a platform with hooks or extra steps
- `path`: the title of the stage, the platform, and the label of the step, e.g. `["Build", "Web", "Cache bust (hash)"]`

The labels can repeat, e.g. every platform with hooks or extra steps has a `Build` step, so use the `number` to tell the steps apart.

### Events

| Event              | Fields                                                                                                         |
| ------------------ | -------------------------------------------------------------------------------------------------------------- |
| `run_started`      | `schema`, `command`, `workflow`, `version`, `started_at`, `steps` (the `number` and `path` of all the steps)    |
| `step_started`     | `number`, `path`                                                                                               |
| `step_status`      | `number`, `path`, `text`: what the step is doing, e.g. `Uploading the build file`                             |
| `step_warning`     | `number`, `path`, `message`                                                                                    |
| `command_started`  | `number`, `path`, `command`: the command that is run                                                           |
| `command_finished` | `number`, `path`, and either `exit_code`, or `error` when the command could not be started                     |
| `step_finished`    | The outcome of the step, see below                                                                             |
| `run_finished`     | `status`, `elapsed_ms`, `steps`, `failed`, `skipped`, `warnings`, `log_file`, `results` (the outcome of all the steps) |
| `message`          | `level` (`error`, `warning`, `info`, or `success`), `text`: a message outside of a run, e.g. an error in the config |

The outcome of a step, in `step_finished` and in the `results` of `run_finished`, has:

- `number`, `path`
- `status`: `succeeded`, `failed`, or `skipped`
- `elapsed_ms`: missing when the step is skipped
- `error`, and `details` when there are any: why the step has failed
- `skip_reason`: why the step is skipped
- `warnings`: when the step has any
- `recent_output`: the last lines of the output of a failed step

The `steps`, `failed`, and `skipped` of `run_finished` count the steps of the stages, where a platform with hooks or extra steps counts once. Such a platform has failed when any of its steps has failed.

The output of the commands is not in the JSON, since it can be thousands of lines. It is in the log file, whose path is in `log_file`.

### Example

```json
{"event":"run_started","schema":1,"command":"build","workflow":"default","version":"1.2.0+12","started_at":"2026-10-18T10:00:00.000","steps":[{"number":"1","path":["Build","Web"]},{"number":"1.1","path":["Build","Web","Build"]},{"number":"1.2","path":["Build","Web","Cache bust (hash)"]}]}
{"event":"step_started","number":"1","path":["Build","Web"]}
{"event":"step_started","number":"1.1","path":["Build","Web","Build"]}
{"event":"command_started","number":"1.1","path":["Build","Web","Build"],"command":"flutter build web"}
{"event":"command_finished","number":"1.1","path":["Build","Web","Build"],"exit_code":1}
{"event":"step_finished","number":"1.1","path":["Build","Web","Build"],"status":"failed","elapsed_ms":1043,"error":"exited with code 1","recent_output":["Compiling lib/main.dart for the Web...","Error: compilation failed"]}
{"event":"step_finished","number":"1.2","path":["Build","Web","Cache bust (hash)"],"status":"skipped","skip_reason":"Build has failed"}
{"event":"step_finished","number":"1","path":["Build","Web"],"status":"failed","elapsed_ms":1050,"error":"Build has failed"}
{"event":"run_finished","status":"failed","elapsed_ms":1102,"steps":1,"failed":1,"skipped":0,"warnings":0,"log_file":".flutter_build_pipe/logs/1.2.0/2026-10-18T10:00:00.000.log","results":[...]}
```

### When the run cannot start

When the config cannot be read, or has an error, there is no run. Only `message` events are written, and the command exits with the code `1`.

### Changes to the format

The `schema` of `run_started` is the version of the format. New events and new fields may be added without changing it, so ignore the ones you do not know. A field that is removed or whose meaning changes bumps the `schema`, and is listed as a breaking change in the changelog.
