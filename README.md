# HuntFor.ps1
Quick tool to search the Sysmon Operational log for ProcessCreate events with a specific CommandLine.

In the code that's in this repo, it's looking for the WebClient service being started.  Change the $script:huntfor regex to whatever you want.

When a match it found, it writes the source Computer Name, UtcTime from the event, and CommandLine to the console.

![HuntFor.ps1 Example](/huntfor.png)
