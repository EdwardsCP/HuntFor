$script:huntfor = "^C:\\windows\\system32\\svchost\.exe -k LocalService -p -s WebClient$"

Function Banner {
    write-host "Loading HuntFor"
    write-host "Currently configured to Hunt For Sysmon ProcessCreate events with Command Line..."
    write-host $script:huntfor
    write-host "Happy Hunting!"
    MenuLogOrFile
    }

Function MenuLogOrFileOptions {
    Write-Host "========================="
    Write-Host "Do you want to process the Sysmon Operational log from an archived EVTX File, or the live log on the local computer?" -ForegroundColor Yellow
    Write-Host "[1] Archived EVTX File(s)"
    Write-Host "[2] Live Log"
    Write-Host "[Q] Quit"
    Write-Host "========================="
    }

Function MenuLogOrFile {
    Do {
        MenuLogOrFileOptions
        $Script:MenuLogOrFileChoice = Read-Host -Prompt 'Please enter a selection from the menu (1, 2, or Q) and press Enter'
        switch ($Script:MenuLogOrFileChoice){
            '1'{
                $script:EVTXLoad = $true
                ProcessEVTXFile
            }
            '2'{
                $script:events = Get-WinEvent -FilterHashTable @{logname='Microsoft-Windows-Sysmon/Operational'; id=1} -ErrorAction SilentlyContinue
                $script:EVTXLoad = $false
                write-host "Total Number of Events Loaded:" $script:events.count
                ProcessEvents
            }
            'Q'{
		        Exit
            }
      }
    }
    Until ($Script:MenuLogOrFileChoice -eq 'q') 
}

#Function to select a FileName to Open using a dialog box
Function Get-FileName($initialDirectory){   
	[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
	$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
	$OpenFileDialog.initialDirectory = $initialDirectory
	$OpenFileDialog.filter = "Event Log (*.EVTX)| *.EVTX"
	$OpenFileDialog.Multiselect = $true
	$OpenFileDialog.ShowDialog() | Out-Null
	
    foreach ($file in $OpenFileDialog.Filenames){
        $Script:EVTXLogs.Add($file) | Out-Null
	}
	Write-Host "Number of files loaded:" $EVTXLogs.Count
}

Function ProcessEVTXFile{
	$Script:EVTXLogs = New-Object System.Collections.ArrayList
    Get-FileName
	foreach ($Script:EVTXLog in $Script:EVTXLogs){
		$script:events = Get-WinEvent -Path $Script:EVTXLog -FilterXPath *[System[EventID=1]] #-MaxEvents 10
		write-host "Total Number of Events Loaded from" $Script:EVTXLog ":" $script:events.count
		ProcessEvents
	}
}



Function ProcessEvents{
	$I = $script:events.count
	$PassCount = 1		
	foreach ($script:event in $script:events){
		Write-Progress -Activity "Processing Events" -Status "Progress: $PassCount of $I" -PercentComplete ($PassCount/$I*100)
		$script:eventXML = [xml]$script:Event.ToXml()
		$script:Computer = $script:eventXML.Event.System.Computer
	    $script:UtcTime = $script:eventXML.Event.EventData.Data[1].'#text'
		$script:CommandLine = $script:eventXML.Event.EventData.Data[10].'#text'
	
		if ($script:commandline -match $script:huntfor){
			write-host "--------------------------"
			write-host $Computer
			Write-host $UtcTime
			Write-Host $CommandLine
			write-host "--------------------------"
		}
		$PassCount++
	}	
}  
	
