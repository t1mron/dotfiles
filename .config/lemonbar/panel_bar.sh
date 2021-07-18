#!/bin/bash

. $HOME/.config/lemonbar/panel_colors.sh

num_mon=$(bspc query -M | wc -l)


while read -r line; do
  case $line in
    BAT*)
      bat="${line#???}"
      ;;
    CPU*)
      cpu="${line#???}"
      ;;
    MEM*)
      mem="${line#???}"
      ;;
    TEMP*)
      temp="${line#????}"
      ;;
    FS*)
      fs="${line#??}"
      ;; 
    WM*)
		  # bspwm's state
			wm=""
			IFS=':'
			set -- ${line#?}
			while [ $# -gt 0 ] ; do
			  item=$1
			  name=${item#?}
			  case $item in
				  [mM]*)
					  [ $num_mon -lt 2 ] && shift && continue
						case $item in
						  m*)
							  # monitor
								FG=$COLOR_MONITOR_FG
								BG=$COLOR_MONITOR_BG
								;;
							M*)
								# focused monitor
							  FG=$COLOR_FOCUSED_MONITOR_FG
							  BG=$COLOR_FOCUSED_MONITOR_BG
								;;
						esac

						wm="${wm}%{F${FG}}%{B${BG}} ${name} %{B-}%{F-}"
						;;
					[ouFOU]*)
					  case $item in
							o*)
								# occupied desktop
								FG=$COLOR_OCCUPIED_FG
								BG=$COLOR_OCCUPIED_BG
								;;
							u*)
							  # urgent desktop
								FG=$COLOR_URGENT_FG
							  BG=$COLOR_URGENT_BG
								;;
              [FO]*)
								# focused occupied/free desktop
							  FG=$COLOR_FOCUSED_OCCUPIED_FG
								BG=$COLOR_FOCUSED_OCCUPIED_BG
								;;
              U*)
								# focused urgent desktop
							  FG=$COLOR_FOCUSED_URGENT_FG
								BG=$COLOR_FOCUSED_URGENT_BG
								;;
						esac

            wm="${wm}%{F${FG}}%{B${BG}} ${name} %{B-}%{F-}"
						;;
				esac
				shift
			done
			;;
    KBD*)
      kbd="${line#???}"
      ;;
    VOL*)
      volume="${line#???}"
      ;;
    DATE*)
      date="${line#????}"
      ;;
  esac

  printf "%s\n" "%{l} ${bat} ${cpu} ${mem} ${temp} ${fs}%{c}${wm}%{r}${kbd} ${date} "
done
