# Ensure scoop is installed
if (-not (Test-Path "$env:USERPROFILE\scoop")) {
    iwr -useb get.scoop.sh | iex
}

# Ensure Git is installed
try {
    git --version | Out-Null
}
catch {
    Write-Output "Git is not installed. Installing via Scoop..."
    scoop install git
}

# Install the apps using scoop
$scoopApps = @(
    '7zip', 'bat', 'charm-gum', 'cmake', 'cwrsync', 'dark', 'fd',
    'fzf', 'gcc', 'go', 'gow', 'grype', 'gzip', 'Hack-NF', 'innounp',
    'jc', 'jid', 'jq', 'kotlin', 'ktlint', 'less', 'licecap', 'neovim',
    'nmap', 'nodejs-lts', 'nu', 'openssl', 'pandoc', 'postman', 'PSReadLine',
    'python', 'ripgrep', 'sd', 'starship', 'syft', 'tealdeer', 'vagrant',
    'vcredist2008', 'yq'
)

foreach ($app in $scoopApps) {
    scoop install $app
}

# Install the PowerShell modules
$psModules = @('Terminal-Icons', 'JiraPS')

foreach ($module in $psModules) {
    Install-Module -Name $module -Scope CurrentUser -Force -AllowClobber
    Import-Module -Name $module
}

# Fetch and update $PROFILE from a git repo
$gitRepoUrl = "https://github.com/dvladimirov/dotfiles"
$profileBackup = "$env:USERPROFILE\Documents\WindowsPowerShell\profile_backup.ps1"

if (Test-Path $profileBackup) {
    Remove-Item $profileBackup
}

# Backup existing profile
if (Test-Path $PROFILE) {
    Copy-Item $PROFILE $profileBackup
}

# Download and set new profile
git clone $gitRepoUrl "$env:USERPROFILE\Documents\WindowsPowerShell\profile_repo"
Copy-Item "$env:USERPROFILE\Documents\WindowsPowerShell\profile_repo\profile.ps1" $PROFILE

# Clean up
Remove-Item "$env:USERPROFILE\Documents\WindowsPowerShell\profile_repo" -Recurse

# Install Neovim configuration
$nvimConfigUrl = "https://spacevim.org/install.cmd"
$nvimConfigPath = "$env:TEMP\install.cmd"

Invoke-WebRequest -Uri $nvimConfigUrl -OutFile $nvimConfigPath
cmd.exe /c $nvimConfigPath

# Clean up the temporary install.cmd
Remove-Item $nvimConfigPath

# Notify user
Write-Output "Setup complete!"

