# Some good standards, which are not used if the user
# creates his/her own .bashrc/.bash_profile

# --show-control-chars: help showing Korean or accented characters
alias ls='ls -F --color=auto --show-control-chars'
alias la='ls -a'
alias ll='ls -l'

# other workspace script-dependent aliases added by hashcat
alias setup='powershell ./setup.ps1'
alias update='powershell ./update.ps1'
alias upgrade='setup && update'

# other scoop application-dependent aliases added by hashcat
alias activate='source utilities/Scripts/activate'
alias install='scoop install $1'
alias remove='scoop uninstall $1'

# other python package-dependent aliases added by hashcat
alias image='gallery-dl --directory downloads/images'
alias track='spotdl --output downloads/tracks'
alias video='yt-dlp --paths downloads/videos --merge-output-format mp4'

case "$TERM" in
xterm*)
	# The following programs are known to require a Win32 Console
	# for interactive usage, therefore let's launch them through winpty
	# when run inside `mintty`.
	for name in node ipython php php5 psql python2.7 winget
	do
		case "$(type -p "$name".exe 2>/dev/null)" in
		''|/usr/bin/*) continue;;
		esac
		alias $name="winpty $name.exe"
	done
	;;
esac
