function run {
	[CmdletBinding()]
	param (
		[Alias('theme')]
		[string]$oh_theme = 'night-owl',
		[switch]$AIO,
		[switch]$ohmp,
		[switch]$cmd,
		[switch]$ps7,
		[Alias('term')]
		[switch]$terminal,
		[Alias('prof')]
		[switch]$ps_profile,
		[switch]$nano,
		[Alias('icon')]
		[switch]$icons,
		[string]$log
	)

	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

	$progressPreference = 'SilentlyContinue'
	
	######### Helpers
	function Shout {
		param(
			[parameter(Mandatory = $true)]
			[string]$text,
			[string]$color,
			[switch]$new,
			[switch]$after,
			[switch]$date
		)

		if (($date) -or ($log)){
			$_date = (Get-Date -Format "MM/dd/yy HH:mm:ss").ToString()
			$finaltext = "{0} {1}" -f $_date, $text
		} else { 
			$finaltext = $text 
		}

		if ($new){ $finaltext = "`n" + $finaltext }
		if ($after){ $finaltext = $finaltext + "`n" }
		if ($log) { $finaltext | Out-File -FilePath $log -Append -ErrorAction SilentlyContinue }

		if ($color){
			if (-not ([Enum]::IsDefined([System.ConsoleColor], $color))) {
				Write-Host "$color doesn't exists in System.ConsoleColor" -ForegroundColor Red
				Write-Host $finaltext
			} else {
				Write-Host $finaltext -ForegroundColor $color
			}
		} else {
			Write-Host $finaltext
		}
	}

	function Test-Inet {
		param(
			[PARAMETER(Mandatory = $true)]
			[ValidateNotNullOrEmpty()]
			$ip
		)
		$response = Test-Connection -ComputerName "$ip" -Count 1 -Quiet
		
		if ($response) {
			Write-Host "Internet detected. Continue..." -ForegroundColor Green
		} else {
			Write-Host "No internet connection detected! Please restart the script once the internet becomes available." -ForegroundColor Red
			Read-Host -Prompt "Press Enter to exit"
			throw "No internet connection detected! Please restart the script once the internet becomes available."
		}
	}

	function Extract-Zip {
		param (
			[string]$archivePath,
			[string]$destinationPath
		)

		if (-not (Test-Path $destinationPath)) {
			New-Item -Path $destinationPath -ItemType Directory -Force | Out-Null
		}

		$shellApp = New-Object -ComObject Shell.Application
		$zipFile = $shellApp.NameSpace($archivePath)
		$destinationFolder = $shellApp.NameSpace($destinationPath)

		foreach ($item in $zipFile.Items()) {
			$destinationFolder.CopyHere($item, 0x0004 + 0x0010 + 0x0400)
		}
	}

	function Download {
		param (
			[string]$releaseZipUrl,
			[string]$savePath,
			[string]$fileName
		)

		if (-not (Test-Path $savePath)) {
			New-Item -ItemType Directory -Path $savePath -Force
		}

		try {
			(New-Object Net.WebClient).DownloadFile("$releaseZipUrl", "$savePath\$fileName")
		} catch {
			Shout "$fileName is not downloaded. Skipping..."
		}
	}

	function GitHubParce {
		param(
			[PARAMETER(Mandatory = $true)]
			[ValidateNotNullOrEmpty()]
			$username,
			[PARAMETER(Mandatory = $true)]
			[ValidateNotNullOrEmpty()]
			$repo,
			[PARAMETER(Mandatory = $true)]
			[ValidateNotNullOrEmpty()]
			$zip_name
		)
		
		$latestReleaseUrl = "https://api.github.com/repos/$username/$repo/releases/latest"

		try {
			$latestRelease = Invoke-WebRequest -Uri $latestReleaseUrl | ConvertFrom-Json
			$link = $latestRelease.assets.browser_download_url | Select-String -Pattern "$zip_name" | select-object -First 1
			$link = $link.ToString().Trim()
			return $link
		} catch {
			Shout "Error fetching release information. Check your network connection or repository." -color 'Red'
			return
		}
	}

	#########

	function MainRun {
		param (
		[PARAMETER(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		$oh_theme = 'night-owl',
		[PARAMETER(Mandatory = $false)]
		[switch]$nano,
		[PARAMETER(Mandatory = $false)]
		[switch]$cmd,
		[PARAMETER(Mandatory = $false)]
		[switch]$ps7,
		[PARAMETER(Mandatory = $false)]
		[switch]$ps_profile,
		[PARAMETER(Mandatory = $false)]
		[switch]$terminal,
		[PARAMETER(Mandatory = $false)]
		[switch]$icons
	)

		$savePath = "$env:TEMP\oh-my-posh_OneClick"

		if (-not (Test-Path $savePath)) {
			New-Item -Path $savePath -ItemType Directory -Force | Out-Null
		}

		function Install-oh {
			$releaseZipUrl = GitHubParce -username "JanDeDobbeleer" -repo "oh-my-posh" -zip_name "install-amd64.exe"
			$fileName = $releaseZipUrl.Split('/')[-1]

			Download -releaseZipUrl $releaseZipUrl -savePath $savePath -fileName $fileName
			
			Start-Process "$savePath\$fileName" -ArgumentList "/CURRENTUSER /VERYSILENT" -Wait | out-null
		
			$machinePath = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::Machine)
			$userPath = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::User)
			$env:Path = $machinePath + ";" + $userPath
			
			if (!(Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
				Shout "oh-my-posh not installed! Rerun the script!" -color 'Red'
				pause
				throw "oh-my-posh not installed! Rerun the script!"
			}
		}

		function Install-Pwsh {
			$releaseZipUrl = GitHubParce -username "PowerShell" -repo "PowerShell" -zip_name "-win-x64.msi"
			$fileName = $releaseZipUrl.Split('/')[-1]

			Download -releaseZipUrl $releaseZipUrl -savePath $savePath -fileName $fileName

			Start-Process "$savePath\$fileName" -ArgumentList "/quiet /passive ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ENABLE_PSREMOTING=1 REGISTER_MANIFEST=1 USE_MU=1 ENABLE_MU=1" -Wait

			$sourcePath = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules"
			$destinationPath = "$env:USERPROFILE\Documents\PowerShell\Modules"

			if (-not (Test-Path $destinationPath)) {
				New-Item -Path $destinationPath -ItemType Directory -Force | Out-Null
			}

			Copy-Item -Path "$sourcePath\PSReadLine" -Destination $destinationPath -Recurse
			Copy-Item -Path "$sourcePath\Terminal-Icons" -Destination $destinationPath -Recurse
		}

		function Install-Clink {
			$releaseZipUrl = GitHubParce -username "chrisant996" -repo "clink" -zip_name "clink.*.zip"
			$fileName = $releaseZipUrl.Split('/')[-1]
			
			Download -releaseZipUrl $releaseZipUrl -savePath $savePath -fileName $fileName

			$archivePath = "$savePath\$fileName"
			$destinationPath = "$env:LocalAppData\clink"

			Extract-Zip -archivePath $archivePath -destinationPath $destinationPath

			$cfg_path = "$env:LocalAppData/Programs/oh-my-posh/themes".Replace('\', '/')
			$scriptContent = "load(io.popen('oh-my-posh.exe --config=`"$cfg_path/$oh_theme.omp.json`" --init --shell cmd'):read(`"*a`"))()"
			$scriptContent | Out-File -FilePath "$destinationPath\oh-my-posh.lua" -Force -Encoding utf8

			Invoke-Expression "& '$destinationPath\clink.bat' autorun install" | Out-Null
		}

		function Install-Nano {
			$releaseZipUrl = GitHubParce -username "okibcn" -repo "nano-for-windows" -zip_name "nano-for-windows_win64*"
			$fileName = $releaseZipUrl.Split('/')[-1]

			Download -releaseZipUrl $releaseZipUrl -savePath $savePath -fileName $fileName

			$archivePath = "$savePath\$fileName"
			$destinationPath = "$env:LocalAppData\Nano"
			
			Extract-Zip -archivePath $archivePath -destinationPath $destinationPath
			
			$currentPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)
			$newPath = $currentPath + ";$destinationPath"
			[System.Environment]::SetEnvironmentVariable("Path", $newPath, [System.EnvironmentVariableTarget]::User)
		}

		function Install-WindowsTerminal {
			if (Get-AppxPackage -Name Microsoft.WindowsTerminal) {
				Shout "Windows Terminal is installed. Skipping..." -color 'Red'
			} else {
				$releaseZipUrl = GitHubParce -username "microsoft" -repo "terminal" -zip_name ".msixbundle"
				$fileName = $releaseZipUrl.Split('/')[-1]
			
				Download -releaseZipUrl $releaseZipUrl -savePath $savePath -fileName $fileName
			
				try {
					Add-AppxPackage -Path "$savePath\$fileName" | Out-Null
				} catch {
					Shout "$($_.Exception.Message)" -color 'Red'
					Shout "WindowsTerminal is not installed. Skipping..." -color 'Red'
				}
			}
		}

		function Configure-WindowsTerminal {
			$get_wt = Get-AppxPackage -Name Microsoft.WindowsTerminal
			if ($get_wt){
				Shout 'Some preparation for WindowsTerminal'
				$wtExecutablePath = Join-Path -Path $($get_wt.InstallLocation) -ChildPath "wt.exe"
				if (Test-Path $wtExecutablePath) {
					if (Get-Process -Name WindowsTerminal -ErrorAction SilentlyContinue){
						Shout 'Windows Terminal is currently running. Reopen it once the script has completed!' -Color 'Red'
					} else {
						Start-Process -FilePath $wtExecutablePath -WindowStyle Hidden
						Start-Sleep -Seconds 2
						Get-Process -Name WindowsTerminal | Stop-Process
					}
					if (Test-Path -Path "$($get_wt.InstallLocation)"){
						$file_path =  "$env:localappdata\Packages\$($get_wt.PackageFamilyName)\LocalState\settings.json"
						$jsonContent = Get-Content $file_path
						$newContent = $jsonContent -replace '"defaults": \{\},', `
						'"defaults": {
									"font": {
										"face": "FiraCode Nerd Font"
									} 
								},' 
						Set-Content $file_path $newContent
					}
				}
			} else {
				Shout "WindowsTerminal is not installed. Skipping" -color 'Red'
			}
		}

		function Write-Profile {
			param(
				[PARAMETER(Mandatory = $true)]
				[ValidateNotNullOrEmpty()]
				[ValidateSet("5", "7")]
				$ps_ver,
				[PARAMETER(Mandatory = $true)]
				[ValidateNotNullOrEmpty()]
				$oh_theme
			)

			$mydocuments = [environment]::getfolderpath("mydocuments")

			if ($icons){
				$row = 'Import-Module Terminal-Icons'
			}

			if ($ps_ver -eq '5'){
				$ps_com = 'powershell'
				$profile_dir = Join-Path -ChildPath 'WindowsPowerShell' -Path $mydocuments
				$profile_path = "$profile_dir\Microsoft.PowerShell_profile.ps1"
			} else {
				$ps_com = 'pwsh'
				$profile_dir = Join-Path -ChildPath 'PowerShell' -Path $mydocuments
				$profile_path = "$profile_dir\Profile.ps1"
			}

			if (Test-Path $profile_path) {
				$top_line = ''
				$profile_content = Get-Content -Path $profile_path -Raw
				if ($profile_content -match "oh-my-posh") {
					$profile_content = $profile_content -replace '(?m)^oh-my-posh init.*$\r?\n?',''
					$profile_content = $profile_content -replace '(?m)^\$oh_my_theme.*$\r?\n?',''

					if ($row){
						$profile_content = $profile_content -replace '(?m)^Import-Module Terminal-Icons.*$\r?\n?',''
						$top_line += $row
						$top_line += "`n"
					}
					
					$top_line += "`$oh_my_theme=`"$oh_theme`""
					$top_line += "`n"
					$top_line += "oh-my-posh init $ps_com --config `"$env:LOCALAPPDATA\Programs\oh-my-posh\themes\`$oh_my_theme.omp.json`" | Invoke-Expression"
					$profile_content = $top_line + $profile_content
					Set-Content -Path $profile_path -Value $profile_content -Encoding UTF8 -Force
				}
			} else {
				$scriptContent = @(
					"$row"
					"`$oh_my_theme=`"$oh_theme`""
					"oh-my-posh init $ps_com --config `"$env:LOCALAPPDATA\Programs\oh-my-posh\themes\`$oh_my_theme.omp.json`" | Invoke-Expression"
					''
					'Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete'
					'Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward'
					'Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward'
					'Set-PSReadLineOption -PredictionViewStyle ListView'
				) -join "`n"
				New-Item -Path "$profile_dir" -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
				$scriptContent | Out-File -FilePath "$profile_path" -Force -Encoding UTF8
			}
		}

		function NewLinks {
			$shell = New-Object -ComObject WScript.Shell
			$userProgramsFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
		
			if (((Get-Culture).DisplayName -like "English*") -and ($cmd)) {
				Remove-Item -Path "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\System Tools\Command Prompt.lnk" -Force -ErrorAction SilentlyContinue
				$cmdShortcutPath = Join-Path -Path "$userProgramsFolder\System Tools" -ChildPath "Command Prompt.lnk"
				$cmdShortcut = $shell.CreateShortcut($cmdShortcutPath)
				$cmdShortcut.TargetPath = "$env:SystemRoot\System32\cmd.exe"
				$cmdShortcut.IconLocation = "$env:SystemRoot\System32\cmd.exe"
				$cmdShortcut.WorkingDirectory = '%HOMEDRIVE%%HOMEPATH%'
				$cmdShortcut.Save()
			}
		
			Remove-Item -Path "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\Windows PowerShell.lnk" -Force -ErrorAction SilentlyContinue
		
			$psShortcutPath = Join-Path -Path "$userProgramsFolder\Windows PowerShell" -ChildPath "Windows PowerShell.lnk"
			$psShortcut = $shell.CreateShortcut($psShortcutPath)
			$psShortcut.TargetPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
			$psShortcut.IconLocation = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
			$psShortcut.WorkingDirectory = '%HOMEDRIVE%%HOMEPATH%'
			$psShortcut.Save()
		}

		# =======================  Main Script Body =======================
		$timer = [Diagnostics.Stopwatch]::StartNew()
		cls
		Shout "Script is starting" -color 'Green'
		Shout 'Installing NuGet packageProvider'; $job = Start-Job -ScriptBlock { Install-PackageProvider -Name NuGet -Confirm:$False -Scope CurrentUser -Force | Out-Null }; Wait-Job -Job $job | Out-Null; Remove-Job -Job $job
		Shout 'Configuring PSGallery repository'; $job = Start-Job -ScriptBlock { Set-PSRepository -Name PSGallery -InstallationPolicy Trusted | Out-Null }; Wait-Job -Job $job | Out-Null; Remove-Job -Job $job
		Shout 'Installing the latest PSReadline powershell module'; $job = Start-Job -ScriptBlock { Install-Module -Name psreadline -Scope CurrentUser -Force -ErrorAction SilentlyContinue | Out-Null }; Wait-Job -Job $job | Out-Null; Remove-Job -Job $job
		if ($icons) { Shout 'Installing Terminal-Icons module'; $job = Start-Job -ScriptBlock { Install-Module -Name Terminal-Icons -Confirm:$False -Scope CurrentUser -Repository PSGallery | Out-Null }; Wait-Job -Job $job | Out-Null; Remove-Job -Job $job }
		Set-ItemProperty -Path "HKCU:\Console" -Name "FaceName" -Value "FiraCode Nerd Font Mono" -ErrorAction SilentlyContinue | Out-Null
		if ($ps7) { Shout 'Installing the latest powershell 7'; Install-Pwsh }
		Shout 'Installing oh-my-posh'; Install-oh
		if ($nano) { Shout 'Installing nano for console'; Install-Nano }
		if ($cmd) { Shout 'Installing clink for cmd (oh-my-cmd)'; Install-Clink }
		if ($ps_profile) { Shout "Creating profiles for PS5/7"; Write-Profile -ps_ver '7' -oh_theme $oh_theme; Write-Profile -ps_ver '5' -oh_theme $oh_theme}
		Shout 'Installing oh-my-posh fonts'; oh-my-posh font install FiraCode | out-null
		if ($terminal) { Shout 'Installing WindowsTerminal'; Install-WindowsTerminal }
		Shout 'Configuring WindowsTerminal'; Configure-WindowsTerminal
		Shout 'Recreating console links for a new font (only for English lang)'; NewLinks
		$timer.Stop()
		$timeRound = [Math]::Round(($timer.Elapsed.TotalSeconds), 2)
		$timer.Reset()
		Shout '------------------------------------' -color 'Cyan'
		Shout "   The script is completed in $timeRound! Enjoy!  " -color 'Blue'
		Shout '------------------------------------' -color 'Cyan'
		pause
		return
	}

############################################################

	Test-Inet -ip '8.8.8.8'

	if ($AIO -or $ohmp -or $cmd -or $ps7 -or $terminal -or $ps_profile -or $nano -or $icons) {
		if ($AIO){
			MainRun -oh_theme $oh_theme -cmd -ps7 -terminal -ps_profile -nano -icons
		} elseif ($ohmp){
			MainRun -oh_theme $oh_theme
		} else {
			MainRun -oh_theme $oh_theme -cmd:$cmd -ps7:$ps7 -terminal:$terminal -ps_profile:$ps_profile -nano:$nano -icons:$icons
		}
	}

	# Initial features
	$features = @{
		ps7        = [PSCustomObject]@{ status = '++'; description = 'Install the latest powershell 7 (admin rights)'; argument = '-ps7' }
		cmd        = [PSCustomObject]@{ status = '++'; description = 'Install Clink for cmd (oh-my-cmd)'; argument = '-cmd' }
		terminal   = [PSCustomObject]@{ status = '++'; description = 'Install WindowsTerminal'; argument = '-terminal' }
		nano       = [PSCustomObject]@{ status = '++'; description = 'Install Nano editor for console'; argument = '-nano' }
		icons      = [PSCustomObject]@{ status = '++'; description = 'Install Terminal-Icons module'; argument = '-icons' }
		ps_profile = [PSCustomObject]@{ status = '++'; description = 'Create powershell profiles (or do it manually later)'; argument = '-ps_profile' }
	}

	$orderedFeatures = @(
		'ps7',
		'cmd',
		'terminal',
		'nano',
		'icons',
		'ps_profile'
	)

	# Colorized
	function Write-StatusLine {
		param (
			[string]$status,
			[string]$lineText
		)
		$textColor = if ($status -eq '++') { 'Green' } else { 'Red' }
		Write-Host $lineText -ForegroundColor $textColor
	}

	function ParametersPreparing {
		$cmd = $features.cmd.status -eq '++'
		$ps7 = $features.ps7.status -eq '++'
		$terminal = $features.terminal.status -eq '++'
		$ps_profile = $features.ps_profile.status -eq '++'
		$nano = $features.nano.status -eq '++'
		$icons = $features.icons.status -eq '++'
		MainRun -oh_theme $oh_theme -cmd:$cmd -ps7:$ps7 -terminal:$terminal -ps_profile:$ps_profile -nano:$nano -icons:$icons
	}

	# Main menu loop
	do {
		cls
		Write-Host '---------------------------------------'
		Write-Host '    Oh-my-posh OneClick installer' -ForegroundColor Yellow
		Write-Host '---------------------------------------'
		Write-Host ' T or 0 - Set Oh-my-posh theme (current: ' -NoNewline
		Write-Host "$oh_theme" -ForegroundColor Cyan -NoNewline
		Write-Host ")`n"
		$count = 1
		foreach ($featureKey in $orderedFeatures) {
			$feature = $features[$featureKey]
			Write-StatusLine -status $feature.status -lineText " $count. $($feature.status) $($feature.description)"
			$count++
		}
		Write-Host "`n--------------------------------------"
		Write-Host " R. Run installation Script" -ForegroundColor Blue
		Write-Host " Q. Do nothing and exit" -ForegroundColor Red
		Write-Host "--------------------------------------"
		Write-Host ' Notes:'
		Write-Host '  By default, all functions are enabled unless manually disabled'
		Write-Host "  Choose option with numbers plus Enter to disable/enable function `n"

		$option = Read-Host " Enter your choice"

		switch ($option) {
			{($_ -eq 'T') -or ($_ -eq 0)} {
				cls
				Write-Host '---------------'
				Write-Host " Set Oh-my-posh theme (current: " -NoNewline
				Write-Host "$oh_theme" -ForegroundColor Cyan -NoNewline
				Write-Host ")"
				Write-Host "---------------"
				
				$themes = @()
				$response = Invoke-RestMethod -Uri "https://api.github.com/repos/JanDeDobbeleer/oh-my-posh/contents/themes"
				if ($response) {
					foreach ($item in $response) {
						if ($item.type -eq "file") {
							$themes += $($item.name).Replace('.omp.json', '')
						}
					}
				} else {
					Write-Host "No files found or request failed." -ForegroundColor Red
				}
				
				$columnCount = 3
				$itemsPerColumn = [math]::Ceiling($themes.Count / $columnCount)
				
				for ($row = 0; $row -lt $itemsPerColumn; $row++) {
					$line = ""
					for ($col = 0; $col -lt $columnCount; $col++) {
						$index = $row + $col * $itemsPerColumn
						if ($index -lt $themes.Count) {
							$line += "{0,-4} {1,-30}" -f ($index + 1), $themes[$index]
						}
					}
					Write-Host $line
				}
				
				Write-Host "`n`n------------"
				Write-Host " B. Go back and set theme to $oh_theme" -ForegroundColor Green
				Write-Host "------------`n`n"
				
				$choice = Read-Host " Select theme by number"
				
				if ($choice -eq 'B' -or $choice -eq 'b') {
					continue
				}
				
				if ($themes[$choice - 1] -and ($choice -gt 0)) {
					$oh_theme = $themes[$choice - 1]
				} else {
					Write-Host " Invalid selection. Try again." -ForegroundColor Red
					Start-Sleep -Seconds 2
				}
			}
			{ $_ -in (1..6) } {
				$featureKey = $orderedFeatures[$option - 1]
				if ($features[$featureKey].status -eq '++') {
					$features[$featureKey].status = '--'
				} else {
					$features[$featureKey].status = '++'
				}
			}
			'R' {
				ParametersPreparing
			}
			'Q' {
				return
			}
			default {
				Write-Host " Invalid option. Please try again." -ForegroundColor Red
				Start-Sleep -Seconds 2
			}
		}
	} while ($true)
}