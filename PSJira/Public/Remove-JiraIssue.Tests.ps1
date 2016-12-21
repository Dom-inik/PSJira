$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {

    # This is intended to be a parameter to the test, but Pester currently does not allow parameters to be passed to InModuleScope blocks.
    # For the time being, we'll need to hard-code this and adjust it as desired.
    $ShowMockData = $false
    $ShowDebugData = $false

    $jiraServer = 'https://jira.example.com'

    $testIssue = 'TEST-001'

    Describe "Remove-JiraIssue" {
        if ($ShowDebugData)
        {
            Mock "Write-Debug" {
                Write-Host "       [DEBUG] $Message" -ForegroundColor Yellow
            }
        }

        Mock Get-JiraConfigServer {
            $jiraServer
        }

        Mock Get-JiraIssue -ModuleName PSJira {
            [PSCustomObject] @{
                Key = $testIssue
                RestURL = "$jiraServer/rest/api/latest/issue/12345"
            }
        }

        Mock Invoke-JiraMethod -ModuleName PSJira -ParameterFilter {$Method -eq 'DELETE' -and $URI -eq "$jiraServer/rest/api/latest/issue/12345" -or $URI -eq "$jiraServer/rest/api/latest/issue/$testIssue"} {
            if ($ShowMockData)
            {
                Write-Host "       Mocked Invoke-JiraMethod with DELETE method" -ForegroundColor Cyan
                Write-Host "         [Method]         $Method" -ForegroundColor Cyan
                Write-Host "         [URI]            $URI" -ForegroundColor Cyan
            }
            # This REST method should produce no output
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName PSJira {
            Write-Host "       Mocked Invoke-JiraMethod with no parameter filter." -ForegroundColor DarkRed
            Write-Host "         [Method]         $Method" -ForegroundColor DarkRed
            Write-Host "         [URI]            $URI" -ForegroundColor DarkRed
            throw "Unidentified call to Invoke-JiraMethod"
        }

        #############
        # Tests
        #############

        It "Accepts a issuename as a String to the -Issue parameter" {
            { Remove-JiraIssue -Issue $testIssue -Force } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Accepts a PSJira.Issue object to the -Issue parameter" {
            $issue = Get-JiraIssue -InputObject $testIssue
            { Remove-JiraIssue -Issue $issue -Force } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Accepts pipeline input from Get-JiraIssue" {
            { Get-JiraIssue -InputObject $testIssue | Remove-JiraIssue -Force } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Removes a issue from JIRA" {
            { Remove-JiraIssue -Issue $testIssue -Force } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Provides no output" {
            Remove-JiraIssue -Issue $testIssue -Force | Should BeNullOrEmpty
        }
    }
}


