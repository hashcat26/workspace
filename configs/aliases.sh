# Some good standards, which are not used if the user
# creates his/her own .bashrc/.bash_profile

# --show-control-chars: help showing Korean or accented characters
alias ls='ls -F --color=auto --show-control-chars'
alias la='ls -a'
alias ll='ls -l'
alias lr='ls -R'

# other project repository-dependent aliases added by hashcat
alias bucket='cd ../bucket'
alias discbot='cd ../discbot'
alias gccport='cd ../gccport'
alias workspace='cd ../workspace'

# other scoop application-dependent aliases added by hashcat
alias list='scoop list'
alias install='scoop install "$@"'
alias remove='scoop uninstall -p "$@"'
alias cleanup='scoop cache rm -a'

# other workspace script-dependent aliases added by hashcat
alias fetch='aria2c --conf-path=configs/aria2.conf'
alias setup='powershell ./setup.ps1'
alias update='powershell ./update.ps1'
alias upgrade='setup; update'

# other python package-dependent aliases added by hashcat
alias img='cd utilities; pipenv run gallery-dl --cookies cookies.txt --directory ../downloads/images'
alias trk='cd utilities; pipenv run spotdl --output ../downloads/tracks'
alias vid='cd utilities; pipenv run yt-dlp --merge mp4 --paths ../downloads/videos'
alias arc='cd utilities; pipenv run yt-dlp --config-location ../configs/yt-dlp.conf'

# other terminal helper-dependent aliases added by hashcat
alias image='dl(){ for i in $@; do img "$i"; cd ..; done; unset dl; }; dl'
alias track='dl(){ for i in $@; do trk "$i"; cd ..; done; unset dl; }; dl'
alias video='dl(){ for i in $@; do vid "$i"; cd ..; done; unset dl; }; dl'
alias archive='dl(){ for i in $@; do arc "$i"; cd ..; done; unset dl; }; dl'

# other utility binary-dependent aliases added by hashcat
alias show='pl(){ cd "$1"; cat *.jpg | ffmpeg -i - -r 900 -f webm - 2>/dev/null | ffplay -autoexit -i -; cd ../..; unset pl; }; pl'
alias merge='pl(){ cd "$1"; cat *.mp4 | ffmpeg -i - -r 900 -f webm - 2>/dev/null | ffplay -autoexit -i -; cd ../..; unset pl; }; pl'
alias listen='pl(){ cd utilities; pipenv run yt-dlp "$1" -f ba -o - 2>/dev/null | ffplay -autoexit -nodisp -i -; cd ..; unset pl; }; pl'
alias watch='pl(){ cd utilities; pipenv run yt-dlp "$1" -f bv+ba -o - 2>/dev/null | ffplay -autoexit -i -; cd ..; unset pl; }; pl'

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
