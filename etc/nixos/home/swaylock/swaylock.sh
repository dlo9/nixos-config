#!/bin/sh
# https://github.com/Misterio77/dotfiles/blob/sway/home/.config/sway/swaylock.sh

insidecolor=$(flavours info -r $(flavours current) | sed -n '4 p')
ringcolor=$(flavours info -r $(flavours current) | sed -n '5 p')
errorcolor=$(flavours info -r $(flavours current) | sed -n '11 p')
clearedcolor=$(flavours info -r $(flavours current) | sed -n '15 p')
highlightcolor=$(flavours info -r $(flavours current) | sed -n '14 p')
verifyngcolor=$(flavours info -r $(flavours current) | sed -n '12 p')
textcolor=$(flavours info -r $(flavours current) | sed -n '10 p')

arguments=""
arguments+=" --ring-color $ringcolor"
arguments+=" --inside-wrong-color $errorcolor"
arguments+=" --ring-wrong-color $errorcolor"
arguments+=" --key-hl-color $highlightcolor"
arguments+=" --bs-hl-color $errorcolor"
arguments+=" --ring-ver-color $verifyngcolor"
arguments+=" --inside-ver-color $verifyngcolor"
arguments+=" --inside-color $insidecolor"
arguments+=" --text-color $textcolor"
arguments+=" --text-clear-color $insidecolor"
arguments+=" --text-ver-color $insidecolor"
arguments+=" --text-wrong-color $insidecolor"
arguments+=" --text-caps-lock-color $textcolor"
arguments+=" --inside-clear-color $clearedcolor"
arguments+=" --ring-clear-color $clearedcolor"
arguments+=" --inside-caps-lock-color $verifyngcolor"
arguments+=" --ring-caps-lock-color $ringcolor"
arguments+=" --separator-color $ringcolor"

swaylock $arguments $@
