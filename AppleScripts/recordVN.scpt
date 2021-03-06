set appName to "Anki"
if application appName is not running then
	return
end if
set appName2 to "Parallels Desktop"
if application appName2 is not running then
	return
end if

set configFile to ((path to home folder) & ".config:vnrecordingscript.conf") as string
set theFileContents to paragraphs of (read file configFile)
set keyCode1 to item 1 of theFileContents as integer
set keyCode2 to item 2 of theFileContents as integer
set keyCodeInterval to item 3 of theFileContents as real

set ffmpeg_running to false
try
	do shell script "/usr/bin/pgrep -q ffmpeg"
	set ffmpeg_running to true
end try

if ffmpeg_running then
	do shell script "echo q >> /tmp/ffmpeg_stop"
	set recordingsFolder to "/tmp"
	set audioFileName to (do shell script "cd " & quoted form of recordingsFolder & " && ls -ltr -A1 | grep m4a | tail -1")
	repeat
		try
			do shell script "/usr/bin/pgrep -q ffmpeg"
			delay 0.2
			on error
				exit repeat			
		end try
	end repeat
	tell application id (id of application appName2) to activate
	tell application "System Events"
		key down keyCode2
		delay keyCodeInterval
		key up keyCode2
	end tell
	set the clipboard to POSIX file (recordingsFolder & "/" & audioFileName)
	tell application id (id of application appName) to activate
	beep 2
else
	set formattedDate to (do shell script "date +'%Y-%m-%d-%H.%M.%S'")
	set filename to "/tmp/recording-" & formattedDate & ".m4a"
	tell application id (id of application appName2) to activate
	tell application "System Events"
		key down keyCode1
		delay keyCodeInterval
		key up keyCode1
	end tell
	do shell script "echo '' > /tmp/ffmpeg_stop"
	do shell script "</tmp/ffmpeg_stop /opt/homebrew/bin/ffmpeg -f avfoundation -i ':Windows' -c:a aac_at -aac_at_mode vbr -q:a 8 -f ipod " & quoted form of filename & "> /dev/null 2>&1 &"
	tell application "System Events"
		repeat
			if exists file filename then
				exit repeat
			else
				delay 0.2
			end if
		end repeat
	end tell
	beep
end if