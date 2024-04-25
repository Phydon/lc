$destination_path = "~/.local/bin"

# get repo-owner from user (don't show on screen)
$input = Read-Host "Enter owner: " -AsSecureString
$owner = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
	[Runtime.InteropServices.Marshal]::SecureStringToBSTR($input)
)

Write-Host "Downloading leanncore-utils into $destination_path"

# create output directory if it doesn't exist
If (!(test-path -PathType container $destination_path)) {
	[void](New-Item -ItemType Directory -Path $destination_path)
}

$utils = @("sf", "mg", "pf", "cx", "sl", "up", "witchfile", "map", "gib", "ms", "xa", "gerf")

try {
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
		
		# get current version for each leanncore util
		$currentVersion = "V$((Invoke-Expression "$outfile -V").split(" ")[-1])"

		# compare current version with latest release version
		# only download util when currentVersion != latestVersion
		# TODO make semantic version check
		# TODO update when currentVersion < latestVersion
		If (!($currentVersion -eq $latestVersion)) {
			Write-Host "Updating $util $currentVersion => $latestVersion"
			Invoke-WebRequest -Uri $url -Outfile $outfile -ErrorAction Stop 
		# } Else {
		# 	# TODO remove else statement??
		# 	Write-Host "$util $currentVersion already up to date"
		}
		
		# restore the progress bar
		$ProgressPreference = "Continue"
		
		$counter++
	}

	Write-Host "All done"
}
catch {
	Write-Warning $Error[0]
}
finally {
	# restore the progress bar
	$ProgressPreference = "Continue"
}
