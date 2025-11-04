#!/bin/sh

# proposed by https://github.com/hyprwm/Hyprland/discussions/8459#discussioncomment-14045167
# This will be used by the future app launcher to launch apps as services
exec uwsm-app -t service -- "$@"