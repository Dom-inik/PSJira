function Remove-JiraIssue
{
    <#
    .Synopsis
       Removes an existing issue from JIRA
    .DESCRIPTION
       This function removes an existing issue from JIRA.
    .EXAMPLE
       Remove-JiraIssue -Key TEST-001
       Removes the JIRA issue TEST-001

       Get-JiraIssue -Query 'project = TEST AND summary ~ "Test"' | Remove-JiraIssue
       Removes all JIRA issues returned by 'Get-JiraIssue'
    .INPUTS
       [PSJira.Issue[]] The JIRA issue to delete
    .OUTPUTS
       This function returns no output.
    #>
    [CmdletBinding(SupportsShouldProcess = $true,
                   ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true,
                   Position = 0,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [Alias('Key')]
        [Object[]] $Issue,

        # Credentials to use to connect to Jira
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credential,

        # Execute without confirmation
        [Switch] $Force
    )

    begin
    {
        Write-Debug "[Remove-JiraIssue] Reading information from config file"
        try
        {
            Write-Debug "[Remove-JiraIssue] Reading Jira server from config file"
            $server = Get-JiraConfigServer -ConfigFile $ConfigFile -ErrorAction Stop
        } catch {
            $err = $_
            Write-Debug "[Remove-JiraIssue] Encountered an error reading configuration data."
            throw $err
        }

        if ($Force)
        {
            Write-Debug "[Remove-JiraIssue] -Force was passed. Backing up current ConfirmPreference [$ConfirmPreference] and setting to None"
            $oldConfirmPreference = $ConfirmPreference
            $ConfirmPreference = 'None'
        }
    }

    process
    {
        foreach ($i in $Issue)
        {
            Write-Debug "[Remove-JiraIssue] Obtaining reference to issue"
            $issueObj = Get-JiraIssue -InputObject $i -Credential $Credential

            if ($issueObj)
            {
                $thisUrl = $issueObj.RestUrl
                Write-Debug "[Remove-JiraIssue] Issue URL: [$thisUrl]"

                Write-Debug "[Remove-JiraIssue] Checking for -WhatIf and Confirm"
                if ($PSCmdlet.ShouldProcess($issueObj.Key, 'Completely remove issue from JIRA'))
                {
                    Write-Debug "[Remove-JiraIssue] Preparing for blastoff!"
                    Invoke-JiraMethod -Method Delete -URI $thisUrl -Credential $Credential
                } else {
                    Write-Debug "[Remove-JiraIssue] Runnning in WhatIf mode or user denied the Confirm prompt; no operation will be performed"
                }
            }
        }
    }

    end
    {
        if ($Force)
        {
            Write-Debug "[Remove-JiraIssue] Restoring ConfirmPreference to [$oldConfirmPreference]"
            $ConfirmPreference = $oldConfirmPreference
        }

        Write-Debug "[Remove-JiraIssue] Complete"
    }
}


