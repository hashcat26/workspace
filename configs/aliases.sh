# Some good standards, which are not used if the user
# creates his/her own .bashrc/.bash_profile

# --show-control-chars: help showing Korean or accented characters
alias ls='ls -F --color=auto --show-control-chars'
alias la='ls -a'
alias ll='ls -l'

# other scoop application-dependent aliases added by hashcat
alias install='scoop install "$@"'
alias remove='scoop uninstall "$@"'
alias cleanup='scoop cache rm -a ; scoop cleanup -a'

# other python package-dependent aliases added by hashcat
alias img='pipenv run gallery-dl --directory ../downloads/images'
alias trk='pipenv run spotdl --output ../downloads/tracks'
alias vid='pipenv run yt-dlp --paths ../downloads/videos --merge-output-format mp4'

# other workspace script-dependent aliases added by hashcat
alias setup='powershell ./setup.ps1'
alias update='powershell ./update.ps1'
alias upgrade='setup && update'

# other terminal helper-dependent aliases added by hashcat
alias image='dl(){ cd utilities; img "$1"; unset dl; }; dl'
alias track='dl(){ cd utilities; trk "$1"; unset dl; }; dl'
alias video='dl(){ cd utilities; vid "$1"; unset dl; }; dl'

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
