$latestRelease = Invoke-WebRequest https://github.com/Phydon/sf/releases/latest -Headers @{"Accept"="application/json"}

# The releases are returned in the format {"id":3622206,"tag_name":"hello-1.0.0.11",...}, we have to extract the tag_name.
$json = $latestRelease.Content | ConvertFrom-Json
$latestVersion = $json.tag_name

$url = "https://github.com/Phydon/sf/releases/download/$latestVersion/sf.exe"
