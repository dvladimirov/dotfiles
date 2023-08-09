#Initial Setup
Invoke-Expression (&starship init powershell)
Import-Module -Name Terminal-Icons
Import-Module -Name JiraPS
#Install-Module JiraPS -Scope CurrentUser
#Set-JiraConfigServer -Server "https://jira.server.com"
#PSReadLine Setup
Set-PSReadLineOption -BellStyle None
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView


#Environmental Variables
$ENV:STARSHIP_CONFIG = "$HOME\.config\starship\starship.toml"
$ENV:STARSHIP_CACHE = "$HOME\.config\starship\Temp"

#Aliases

Set-Alias -Name ue -Value 'git config --global user.email "dvladimirov@pros.com"'
Set-Alias -Name un -Value 'git config --global user.name "dvladimirov"'
Set-Alias -Name cat -Value bat
Set-Alias -Name vim -Value nvim
Set-Alias -Value 'C:\Program Files\Notepad++\notepad++.exe' -Name n
Set-Alias -Name ll -Value ls
Set-Alias -Name rm -Value del
#Functions
function Get-JiraCredentials {
    $credFile = "C:\users\dvladimirov\Work\credentials.txt"
    $credContent = Get-Content -Path $credFile
    $splitCred = $credContent -split ":"
    $username = $splitCred[0]
    $password = ConvertTo-SecureString -String $splitCred[1] -AsPlainText -Force
    $creds = New-Object System.Management.Automation.PSCredential -ArgumentList ($username, $password)
    return $creds
}
#Alias Functions
function gj {
    param (
        [Parameter(Mandatory=$true)] [string] $ticketNumber
    )
    $creds = Get-JiraCredentials
    $issue = Get-JiraIssue $ticketNumber -Credential $creds
    $issue | Select-Object Key, Summary, Status, Updated | Format-List
}
function mj {
    $creds = Get-JiraCredentials
    $issues = Get-JiraIssue -Query "status in (ToDo, 'In Progress', Testing, Design, Open, 'CQA: SetDescr') AND assignee in (currentUser())" -Credential $creds
    $issues | Format-Table -Property Key, Summary, Status, Updated
}

function ajc {
    param (
        [Parameter(Mandatory=$true)] [string] $ticket,
        [Parameter(Mandatory=$true)] [string] $comment
    )
    Write-Host "Fetching credentials..."
    $creds = Get-JiraCredentials
    Write-Host "Adding comment to ticket $ticket..."
    Add-JiraIssueComment -Credential $creds -Issue $ticket -Comment $comment
    Write-Host "Done!"
}

function jc {
    param (
        [Parameter(Mandatory=$true)] [string] $ticket
    )
    
    Write-Host "Fetching credentials..."
    $creds = Get-JiraCredentials

    Write-Host "Fetching all comments for Jira ticket $ticket..."
    $allComments = Get-JiraIssueComment -Credential $creds -Issue $ticket

    if ($allComments -eq $null) {
        Write-Host "No comments found."
        return $null
    } else {
        Write-Host "Fetched $($allComments.Count) comments."
    }

    $comments = $allComments | Select-Object -Last 5
    Write-Host "Returning last 5 comments..."
    
    return $comments
}
function jcb {
    param (
        [Parameter(Mandatory=$true)] [string] $ticket
    )
    
    Write-Host "Fetching credentials..."
    $creds = Get-JiraCredentials

    Write-Host "Fetching all comments for Jira ticket $ticket..."
    $allComments = Get-JiraIssueComment -Credential $creds -Issue $ticket

    if ($allComments -eq $null) {
        Write-Host "No comments found."
        return $null
    } else {
        Write-Host "Fetched $($allComments.Count) comments."
    }

    $comments = $allComments | Select-Object -Last 5 | ForEach-Object { $_.Body }
    Write-Host "Returning last 5 comments..."
    
    return $comments
}



function tj {
    param (
        [Parameter(Mandatory=$true)] [string] $ticket
    )
    
    $creds = Get-JiraCredentials
    $issue = Get-JiraIssue -Credential $creds -Key $ticket

    # Add debug output for the issue
    Write-Host "Issue: $issue"
    Write-Host "Issue Status: $($issue.Status)"

    $transitionId = $null

    switch ($issue.Status) {
        "Triage" { $transitionId = 201 }  # Approve
        "In Progress" { $transitionId = 101 }  # Ready for Testing
        "Testing" { $transitionId = 251 }  # All Tests Pass
        "Selected for Development" { $transitionId = 31 }  # Ready for Development
        "Open" { $transitionId = 11 } # Open
        "ToDo" { $transitionId = 61 }
        default        { Write-Host "Unknown status: $($issue.Status)"; return }
    }
    Write-Host "Transitioning ticket $ticket to next status using transition ID: $transitionId..."
    Invoke-JiraIssueTransition -Credential $creds -Issue $ticket -Transition $transitionId
    Write-Host "Done!"
}

function lj {
    param (
        [Parameter(Mandatory = $true)]
        [string]$IssueKey1,
        [Parameter(Mandatory = $true)]
        [string]$IssueKey2,
        [Parameter(Mandatory = $true)]
        [string]$LinkType
    )


    $creds = Get-JiraCredentials
    $baseURL = Get-JiraConfigServer

    $body = @{
        type = @{
            name = $LinkType
        }
        inwardIssue = @{
            key = $IssueKey1
        }
        outwardIssue = @{
            key = $IssueKey2
        }
    } | ConvertTo-Json

    #Invoke-JiraMethod -Credential $creds -Method Post -URI ("$baseURL/rest/api/2/issueLink") -Body $body
    try {
        $response = Invoke-JiraMethod -Credential $creds -Method Post -URI ("$baseURL/rest/api/2/issueLink") -Body $body
        if ($response) {
            Write-Host "Linking operation successful for tickets $IssueKey1 and $IssueKey2"
        }
    } catch {
        Write-Host "An error occurred while linking tickets $IssueKey1 and $IssueKey2"
    }
}


#function nj {
#    param (
#        [Parameter(Mandatory = $true)]
#        [string]$Title,
#        [Parameter(Mandatory = $true)]
#        [string]$Description
#    )
#
#    $creds = Get-JiraCredentials
#
#    $params = @{
#        Project = "DummyProject"
#        IssueType = "Task"
#        Summary = $Title
#        Description = $Description
#        Priority = 'Medium'
#        Component = 'PPSS'
#        Affected Version = 'NA'
#
        # More fields here...
#    }
#
#    New-JiraIssue @params -Credential $creds
#}

function jt {
    param (
        [Parameter(Mandatory = $true)]
        [string]$IssueKey,
        [Parameter(Mandatory = $true)]
        [string]$TimeSpentStr,    # in Jira duration format like '3h 30m'
        [Parameter(Mandatory = $false)]
        [string]$Comment = ""  # Optional worklog comment
    )

    # Parse TimeSpentStr and convert to TimeSpan
    $TimeSpent = New-TimeSpan
    if ($TimeSpentStr -match '(\d+)h') {
        $TimeSpent = $TimeSpent.Add([TimeSpan]::FromHours($Matches[1]))
    }
    if ($TimeSpentStr -match '(\d+)m') {
        $TimeSpent = $TimeSpent.Add([TimeSpan]::FromMinutes($Matches[1]))
    }

    $creds = Get-JiraCredentials

    Add-JiraIssueWorklog -Credential $creds -Issue $IssueKey -TimeSpent $TimeSpent -Comment $Comment -DateStarted (Get-Date)
}


function .. { Set-Location ..\}
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }

#Keybindings
#function to parse a document showing only its first column
function au { Set-Location $HOME\Work\Automation}
function w { Set-Location $HOME\Work}
function d { Set-Location $HOME\Work\Dummy}
function gip { 
	git status
	git checkout master
	git pull
	}
function lazyg {
	git add .
	$branchName = git rev-parse --abbrev-ref HEAD
	$ticketPart = $branchName.Split("/")[-1]
	git commit -m "$ticketPart $args"
	git push -u origin $(git rev-parse --abbrev-ref HEAD)
	}
function Get-PubIp {
	(Invoke-WebRequest http://ifconfig.me/ip ).Content
	}
function reload-profile {
	& $profile
	}
function unzip ($file) {
    Write-Output("Extracting", $file, "to", $pwd)
    $fullFile = Get-ChildItem -Path $pwd -Filter .\cove.zip | ForEach-Object { $_.FullName }
    Expand-Archive -Path $fullFile -DestinationPath $pwd
}

function share {
    param (
        [Parameter(Mandatory=$true)]
        [string]$filename
    )

    if (Test-Path $filename) {
        $response = curl -F "f:1=@$filename" http://ix.io
        Write-Output "File uploaded to: $response"
    } else {
        Write-Error "File $filename does not exist."
    }
}


function touch($file) {
    "" | Out-File $file -Encoding ASCII
}
function df {
    get-volume
}
function which($name) {
    Get-Command $name | Select-Object -ExpandProperty Definition
}
function export($name, $value) {
    set-item -force -path "env:$name" -value $value;
}
function pkill($name) {
    Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
}
function pgrep($name) {
    Get-Process $name
}
