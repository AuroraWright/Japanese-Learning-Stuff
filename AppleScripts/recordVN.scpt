if application "Anki" is not running then
	return
end if

set configFile to ((path to home folder) & ".config:vnrecordingscript.conf") as string
set fileContents to paragraphs of (read file configFile)
set ffmpegPath to item 2 of fileContents as string
set pythonPath to item 4 of fileContents as string
set virtualDeviceName to item 6 of fileContents as string
set windowManagementMode to item 8 of fileContents as integer
set vnApp to item 10 of fileContents as string
set preKeyCodeDelay to item 12 of fileContents as real
set preRecordingDelay to item 14 of fileContents as real
set secondKeyCodeDelay to item 16 of fileContents as real
set keyCode1 to item 18 of fileContents as integer
set keyCode2 to item 20 of fileContents as integer
set keyCode3 to item 22 of fileContents as integer
set keyCode4 to item 24 of fileContents as integer
set keyCodeHoldingTime to item 26 of fileContents as real
set ankiFieldName to item 28 of fileContents as string

if windowManagementMode is equal to 1 then
	if application vnApp is not running then
		set process_running to false
		try
			do shell script "/usr/bin/pgrep -q " & vnApp
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
	if windowManagementMode is equal to 1 then
		tell application id (id of application vnApp) to activate
	else if windowManagementMode is equal to 2 then
		tell application "System Events" to key code 124 using control down
		delay vnApp
	else if windowManagementMode is equal to 3 then
		delay vnApp
	end if
	if windowManagementMode is not equal to 4 then
		delay preKeyCodeDelay
		tell application "System Events"
			key down keyCode2
			delay keyCodeHoldingTime
			key up keyCode2
		end tell
		if keyCode4 is not equal to 0 then
			tell application "System Events"
				delay secondKeyCodeDelay
				key down keyCode4
				delay keyCodeHoldingTime
				key up keyCode4
			end tell
		end if
	end if
	set posixAudioFileName to the quoted form of POSIX path of (POSIX file (recordingsFolder & "/" & audioFileName))
	savetoanki(pythonPath, posixAudioFileName, ankiFieldName)
	tell application id (id of application "Anki") to activate
else
	tell application "System Events"
		tell the folder "/private/tmp" to delete (files whose name starts with "recording-")
	end tell
	set formattedDate to (do shell script "date +'%Y-%m-%d-%H.%M.%S'")
	set filename to "/tmp/recording-" & formattedDate & ".m4a"
	if windowManagementMode is equal to 1 then
		tell application id (id of application vnApp) to activate
	else if windowManagementMode is equal to 2 then
		tell application "System Events" to key code 124 using control down
		delay vnApp
	else
		delay vnApp
	end if
	if windowManagementMode is not equal to 4 then
		delay preKeyCodeDelay
		tell application "System Events"
			key down keyCode1
			delay keyCodeHoldingTime
			key up keyCode1
		end tell
		if keyCode3 is not equal to 0 then
			tell application "System Events"
				delay secondKeyCodeDelay
				key down keyCode3
				delay keyCodeHoldingTime
				key up keyCode3
			end tell
		end if
	end if
	delay preRecordingDelay
	do shell script "echo '' > /tmp/ffmpeg_stop"
	do shell script "</tmp/ffmpeg_stop " & ffmpegPath & " -f avfoundation -i ':" & virtualDeviceName & "' -c:a aac_at -aac_at_mode vbr -q:a 8 -f ipod -t 120 " & quoted form of filename & "> /dev/null 2>&1 &"
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
	beep
end if

on savetoanki(pythonPath, fileName, ankiFieldName)
    do shell script pythonPath & " <<'EOF' - " & fileName & " " & ankiFieldName & "

import sys, json, os
from subprocess import Popen
import signal
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


def delete():
    try:
        os.remove(sys.argv[1])
    except OSError:
        pass


def main():
    if len(sys.argv) != 3:
        return
    added_notes = anki_connect('findNotes', query='added:1 deck:current')
    if len(added_notes) == 0:
        delete()
        return
    added_notes.sort()
    try:
        with open('/tmp/last_edited_cards.json', 'rb') as fp:
            updated_list = json.load(fp)
    except IOError:
        delete()
        return
    if len(updated_list) == 0:
        delete()
        return
    anki_connect('guiBrowse', query='nid:1')
    note_index = -1
    field_name = sys.argv[2]
    while True:
        if abs(note_index) > len(added_notes):
            break
        note_id = added_notes[note_index]
        if not note_id in updated_list:
            break
        note_data = anki_connect('notesInfo', notes=[note_id])
        if note_data[0]['fields'][field_name]['value'] != '':
            break
        note = {'id': note_id, 
                'fields': {},
                'audio': {'filename': os.path.basename(sys.argv[1]),
                          'path': sys.argv[1],
                          'fields': [field_name]
                         }
               }
        anki_connect('updateNoteFields', note=note)
        note_index -= 1

    anki_connect('guiBrowse', query='added:1 deck:current', reorderCards={'order': 'descending', 'columnId': 'noteCrt'})

    if note_index != -1:
        Popen(f'afplay -t 2 {sys.argv[1]} && rm {sys.argv[1]}', shell=True)
        signal.signal(signal.SIGCHLD, signal.SIG_IGN)
    else:
        delete()

main()
EOF"
end savetoanki