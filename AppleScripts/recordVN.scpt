set appName to "Anki"
if application appName is not running then
	return
end if

set configFile to ((path to home folder) & ".config:vnrecordingscript.conf") as string
set theFileContents to paragraphs of (read file configFile)
set manageWindows to item 1 of theFileContents as integer
set appName2 to item 2 of theFileContents as string
set delayInterval to item 3 of theFileContents as real
set keyCode1 to item 4 of theFileContents as integer
set keyCode2 to item 5 of theFileContents as integer
set keyCodeInterval to item 6 of theFileContents as real

if manageWindows is equal to 1 then
	if application appName2 is not running then
		set process_running to false
		try
			do shell script "/usr/bin/pgrep -q " & appName2
			set process_running to true
		end try
		
		if not process_running then
			return
		end if
	end if
end if

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
	if manageWindows is equal to 1 then
		tell application id (id of application appName2) to activate
	else if manageWindows is equal to 2 then
		tell application "System Events" to key code 124 using control down
		delay appName2
	else
		delay appName2
	end if
	tell application "System Events"
		key down keyCode2
		delay keyCodeInterval
		key up keyCode2
	end tell
	set posixFileName to the quoted form of POSIX path of (POSIX file (recordingsFolder & "/" & audioFileName))
	savetoanki(posixFileName)
	tell application id (id of application appName) to activate
	beep 2
else
	set formattedDate to (do shell script "date +'%Y-%m-%d-%H.%M.%S'")
	set filename to "/tmp/recording-" & formattedDate & ".m4a"
	if manageWindows is equal to 1 then
		tell application id (id of application appName2) to activate
	else if manageWindows is equal to 2 then
		tell application "System Events" to key code 124 using control down
		delay appName2
	else
		delay appName2
	end if
	tell application "System Events"
		key down keyCode1
		delay keyCodeInterval
		key up keyCode1
	end tell
	delay delayInterval
	do shell script "echo '' > /tmp/ffmpeg_stop"
	do shell script "</tmp/ffmpeg_stop /opt/homebrew/bin/ffmpeg -f avfoundation -i ':Studying' -c:a aac_at -aac_at_mode vbr -q:a 8 -f ipod " & quoted form of filename & "> /dev/null 2>&1 &"
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

on savetoanki(posixFileName)
    do shell script "/opt/homebrew/bin/python3 <<'EOF' - " & posixFileName & "

import sys, json, os
import urllib.request


def request(action, **params):
    return {'action': action, 'params': params, 'version': 6}

def anki_connect(action, **params):
    requestJson = json.dumps(request(action, **params)).encode('utf-8')
    response = json.load(urllib.request.urlopen(urllib.request.Request('http://127.0.0.1:8765', requestJson)))
    if len(response) != 2:
        raise Exception('response has an unexpected number of fields')
    if 'error' not in response:
        raise Exception('response is missing required error field')
    if 'result' not in response:
        raise Exception('response is missing required result field')
    if response['error'] is not None:
        raise Exception(response['error'])
    return response['result']


def main():
    added_notes = anki_connect('findNotes', query='added:1')
    added_notes.sort()
    noteid = added_notes[-1]
    note = {'id': noteid, 
            'fields': {},
            'audio': {'filename': os.path.basename(sys.argv[1]),
                      'path': sys.argv[1],
                      'fields': ['SentenceAudio']
                     }
           }
    anki_connect('guiBrowse', query='nid:1')
    anki_connect('updateNoteFields', note=note)
    anki_connect('guiBrowse', query='is:new')

main()
EOF"
end savetoanki