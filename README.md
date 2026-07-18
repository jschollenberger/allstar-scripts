# allstar-scripts

[![ShellCheck](https://github.com/jschollenberger/allstar-scripts/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/jschollenberger/allstar-scripts/actions/workflows/shellcheck.yml)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
![Bash](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnubash&logoColor=white)

Random scripts for [AllStarLink](https://www.allstarlink.org/) / [HamVOIP](https://hamvoip.org/) nodes.

## Scripts

### bouncer.sh

Detects and disconnects nodes that have subtended (further) nodes linked behind them, to keep a hub or net from bridging in unexpected traffic.

```
bouncer.sh [local_node] [remote_node]
```

- `local_node` — optional; if omitted, sourced from `NODE1` in `/usr/local/etc/allstar.env`.
- `remote_node` — optional; if omitted, checks all currently connected links.

Nodes in the `IGNORE_NODES` list at the top of the script are skipped. Actions and results are logged to `/tmp/bouncer.log`. The actual disconnect command (`rpt cmd ... ilink 11`) ships commented out — uncomment it once you've confirmed the detection logic behaves as expected on your node.

### collect-stats.sh

Collects `rpt stats` output for a node and appends it as a CSV line (date + today's stats) to `/root/stats/stats`. Intended to be run on a schedule (e.g. via cron) to build up a history of daily stats. Edit the node number (`53209`) in the script to match your node.

### convert-archive-wav.sh

Watches an AllStar/HamVOIP recording directory and transcodes GSM-in-WAV recordings to linear PCM in place, so they can be played back directly in a browser with a plain `<audio>` tag instead of requiring a GSM-aware player.

```
convert-archive-wav.sh [watch_dir]
```

- `watch_dir` — optional; defaults to `/etc/asterisk/record/50420`. Pass a different path to reuse the same script on another node's recording directory.
- Requires `inotify-tools` and `sox` (developed/tested against SoX 14.4.2).
- Runs as a long-lived watcher (suitable for a systemd service): does an initial catch-up scan of any files already in the directory, then converts new recordings as they're written. Auto-restarts its `inotifywait` watch if it dies, and exits cleanly on SIGTERM/SIGINT. Logs to `/var/log/recording-converter.log`.

### disconnect-outbound-links.sh

Disconnects all outbound links from a node. Useful to run before linking into other hubs for a net, so you're not carrying over unrelated links.

```
disconnect-outbound-links.sh [local_node]
```

- `local_node` — optional; if omitted, sourced from `NODE1` in `/usr/local/etc/allstar.env`.
- Guards against overlapping runs (exits if already running).

### playnews-cw

Modified version of `playnews` that breaks on ARRL news silence (a Morse "K" character followed by 4 seconds of silence) rather than waiting for a fixed duration (~160 seconds).

Executed from cron:

```
# Schedule the news at least 10 minutes prior so we get the warning messages. we do 25 to accomodate download and conversion + potential failback
# play the news on saturday
15 8 * * 6 /etc/asterisk/local/playnews/playnews-cw ARRL 08:40 50420 G &>> /tmp/playnews.log
```

## Requirements

These scripts are written for Asterisk-based AllStarLink/HamVOIP nodes and call out to the `asterisk` CLI (`asterisk -rx ...`) directly, so they're intended to run on the node itself (or somewhere with `asterisk -rx` access). Some scripts additionally expect `/usr/local/etc/allstar.env` to define `NODE1` for your node's ID, and `convert-archive-wav.sh` requires `inotify-tools` and `sox`.

## License
 
This project is licensed under the [GNU General Public License v3.0](LICENSE) (or, at your option, any later version). You are free to use, modify, and redistribute these scripts, provided derivative works remain under the same license and retain the copyright and license notices.
 
`playnews-cw` is a modified version of `playnews` by WA3DSP; the original copyright and license notices are preserved.
 
These scripts are provided as-is, with no warranty (see sections 15–16 of the license). Review before running on a production node, and adjust node numbers, paths, and ignore lists for your own setup.
