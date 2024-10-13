### Kanji Pop-up Dictionary Configuration

*If Kanji Pop-up Dictionary has been a valuable asset in your studies, please consider supporting the efforts of the original dev efforts by [buying them a coffee](https://ko-fi.com/X8X0L4YV), or by [pledging your support on Patreon](https://www.patreon.com/glutanimate). Each and every contribution is greatly appreciated and will help them maintain and improve Pop-up Dictionary as time goes by!*

Please note that the following settings do not sync and require a restart to apply:

- `RTKDeckName` (string): Name of the RTK deck to take kanji cards from. Default: `"RTK"`.
- `keywordFieldName` (string): Name of the RTK keyword field in the RTK deck. Default: `"Keyword"`.
- `kanjiFieldName` (string): Name of the kanji field in the RTK deck. Default: `"Kanji"`.
- `generalConfirmEmpty` (true/false): Whether or not to show tooltip when no results have been found. Default: `true`.
- `generalHotkey` (string): Hotkey to invoke tooltip manually. Default: `"Ctrl+Shift+D"`.
- `snippetsExcludedFields` (list): List of fields to exclude from being shown in the note snippet section of the tooltip. Default: `["Note ID", "ID (hidden)"]`.
- `snippetsResultsWarnLimit` (integer): Number of results above which to show a warning on the potential slowdowns they could cause. Set to `0` to disable warning. Default: `1000`.
- `wordSearchSortingColumn` (string): Internal Anki name for the column to order words by in the search by kanji browser window. Default: `"cardDue"`.
- `defaultTooltipDivId` (string): Id of the div to use to position the tooltip when invoked via the hotkey. Only change if the tooltip isn't displayed correctly, has to be the id of a div from the card template. Default: `"qa > div"`.