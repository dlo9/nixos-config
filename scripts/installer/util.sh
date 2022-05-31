#!/bin/sh

black=$(tput setaf 0)
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
lime_yellow=$(tput setaf 190)
powder_blue=$(tput setaf 153)
blue=$(tput setaf 4)
magenta=$(tput setaf 5)
cyan=$(tput setaf 6)
white=$(tput setaf 7)
bright=$(tput bold)
normal=$(tput sgr0)
reverse=$(tput smso)
underline=$(tput smul)

# Prints text in the given color
colorize_() {
    color="$1"
    shift

    printf "${color}%s${normal}" "$*"
}

# Prints text in the given color, followed by a newline
colorize() {
    color="$1"
    shift

    printf "${color}%s${normal}\n" "$*"
}

# Logging utils
error_() { colorize_ "$red" "$@"; }
warn_() { colorize_ "$yellow" "$@"; }
info_() { colorize_ "$blue" "$@"; }
success_() { colorize_ "$green" "$@"; }

# Logging utils (newline variants)
error() { colorize "$red" "$@"; }
warn() { colorize "$yellow" "$@"; }
info() { colorize "$blue" "$@"; }
success() { colorize "$green" "$@"; }
