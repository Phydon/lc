param(
  [switch]$V
)

# Define the version
$scriptVersion = "lc 1.0.0"

# Check if version argument was passed
if ($V) {

  # Show the version
  Write-Host "$scriptVersion"

} else {
	$destination_path = "~/.local/bin"

	# create output directory if it doesn't exist
	if (!(Test-Path -PathType container $destination_path)) {
		[void](New-Item -ItemType Directory -Path $destination_path)
	}

	# get repo-owner from user (don't show on screen)
	$input = Read-Host "Enter owner: " -AsSecureString
	$owner = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
		[Runtime.InteropServices.Marshal]::SecureStringToBSTR($input)
	)

	$utils = @("sf", "mg", "pf", "cx", "sl", "up", "witchfile", "map", "gib", "ms", "xa", "gerf")

	try {
		Write-Host "Downloading leanncore-utils into $destination_path"

		$counter = 0
		foreach ($util in $utils) {
			$progress = [math]::round(($counter/$utils.count) * 100, 0)
	
			Write-Progress -Activity "Downloading" -Status "$progress% Complete:" -CurrentOperation "$util.exe" -PercentComplete $progress
	
			# supress the progress bar
			$ProgressPreference = "SilentlyContinue"

			# get latest release version for each leanncore util
			$latestRelease = Invoke-WebRequest "https://github.com/$owner/$util/releases/latest" -Headers @{"Accept"="application/json"} -ErrorAction Stop
			$json = $latestRelease.Content | ConvertFrom-Json
			$latestVersion = $json.tag_name
			$url = "https://github.com/$owner/$util/releases/download/$latestVersion/$util.exe"

			$outfile = "$destination_path/$util.exe"
	
			If (Test-Path $outfile) {
				# get current version for each leanncore util if it already exists in destination_path
				$currentVersion = "V$((Invoke-Expression "$outfile -V").split(" ")[-1])"
		
				# compare current version with latest release version
				# only download util when currentVersion != latestVersion
				# TODO make semantic version check
				# TODO update when currentVersion < latestVersion
				If (!($currentVersion -eq $latestVersion)) {
					Write-Host "Updating $util $currentVersion => $latestVersion"
					Invoke-WebRequest -Uri $url -Outfile $outfile -ErrorAction Stop 
				}
			} Else {
				# if util doesn't already exist in destination_path
				Write-Host "Downloading $util $latestVersion"
				Invoke-WebRequest -Uri $url -Outfile $outfile -ErrorAction Stop 
			}

	
			# restore the progress bar
			$ProgressPreference = "Continue"
	
			$counter++
		}

		Write-Host "All done"
	}
	catch {
		Write-Warning $Error[0]
		Write-Error $_
	}
	finally {
		# restore the progress bar
		$ProgressPreference = "Continue"
	}
}
