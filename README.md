# `tmuxss` — A Simple Bash Tmux Multiview Session Manager

**`tmuxss`** is a lightweight session manager for `tmux` that enables multiview workflows using reusable JSON templates and structured session creation.

---

## Features

* Attach multiple clients to the same `tmux` session independently
* Use reusable JSON templates to define complex environments
* Configure split layouts, commands, working directories, read-only panes, and shell histories

---

## Usage

`tmuxss` can be used directly from the CLI or more conveniently via hotkeys configured in your `tmux.conf`.

### Initialize the Main Group

Run this as your terminal startup command:

```bash
tmuxss -i
```

This creates and attaches you to a new session tied to the current terminal client, grouped under the default "main" group.

### Switch Between Sessions

When run from within an existing `tmux` session, `tmuxss` opens an interactive selector. Choosing a session will attach you to it:

```bash
tmuxss
```

You can also attach directly:

```bash
tmuxss -a -g <GROUP>
```

### Kill Sessions

* Kill selected session via prompt:

  ```bash
  tmuxss -k
  ```

* Kill specific group session:

  ```bash
  tmuxss -k -g <GROUP>
  ```

### Create New Session Groups

Use the `-c` option:

```bash
tmuxss -c [OPTIONS]
```

#### Available Options:

| Option          | Description                                                                                                |
| --------------- | ---------------------------------------------------------------------------------------------------------- |
| `-g <GROUP>`    | (Optional) Group name. Defaults to the basename of the current directory, unless overridden by a template. |
| `-d`            | Start the session without attaching.                                                                       |
| `-t <TEMPLATE>` | Load a template by name. Will look for `/home/<user>/tmuxss.json`.                                         |
| `-p <PATH>`     | Path to a template configuration file (overrides default path).                                            |

> **Note:** The `-s <SESSION ID>` option is intended for internal use (e.g., binding sessions to TTYs like `tty1`). You typically won’t need to use this manually.

---

## Template Format

Templates define session structure, window layouts, working directories, and commands.

### Minimal Example

```json
{
  "default": "default",
  "envs": {
    "default": {
      "path": ".",
      "focused": 0,
      "windows": [
        { "name": "code", "command_run": "nvim" },
        { "name": "util", "command_run": "htop" }
      ]
    }
  }
}
```

### Nested Split Example

```json
{
  "envs": {
    "dev": {
      "path": "~/src/project",
      "windows": [
        {
          "name": "runtime",
          "hsplit": [
            {
              "vsplit": [
                { "command_prepare": "yarn start", "path": "./frontend" },
                { "command_prepare": "cargo run", "path": "./backend" }
              ]
            },
            { "command_run": "htop" }
          ]
        }
      ]
    }
  }
}
```

See [example.tmuxss.json](example.tmuxss.json) for a complete config.

---

## Requirements

* [`tmux`](https://github.com/tmux/tmux)
* [`yq`](https://github.com/mikefarah/yq) — used to parse the JSON config

---

## Installation

Make the script executable and move it to your `PATH`:

```bash
chmod +x tmuxss
mv tmuxss ~/.local/bin/
```

### Optional: Auto-Start on TTY

Add this to your shell config or terminal launcher to bind `tmuxss` to a specific TTY:

```bash
case "$(tty)" in
  */tty4)
    tmuxss -i -s $(basename "$(tty)")
    exit
  ;;
esac
```
