# get repo-owner from user (don't show on screen)
$input = Read-Host "Enter owner: " -AsSecureString
$owner = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
	[Runtime.InteropServices.Marshal]::SecureStringToBSTR($input)
)

# TODO compare input (hash) with (hash of) "Phydon"
# If(!($input -eq "Phydon")) {
	# Write-Host "Owner unknown"
	# exit
# }

# $destination_path = "~/.local/bin"
# TODO remove after testing
$destination_path = "~/main/lc/testdir"

Write-Host "Downloading leanncore-utils into $destination_path..."

# create output directory if it doesn't exist
If(!(test-path -PathType container $destination_path)) {
	[void](New-Item -ItemType Directory -Path $destination_path)
}

$utils = @("sf", "mg", "pf", "cx", "sl", "up", "witchfile", "map", "gib")

try {
	foreach ($util in $utils) {
		# get latest release version for each leanncore util
		$latestRelease = Invoke-WebRequest "https://github.com/$owner/$util/releases/latest" -Headers @{"Accept"="application/json"} -ErrorAction Stop
		$json = $latestRelease.Content | ConvertFrom-Json
		$latestVersion = $json.tag_name
		$url = "https://github.com/$owner/$util/releases/download/$latestVersion/$util.exe"

		$outfile = "$destination_path/$util.exe"

		Invoke-WebRequest -Uri $url -Outfile $outfile -ErrorAction Stop
	}

	Write-Host "All done"
}
catch {
	Write-Warning $Error[0]
}
