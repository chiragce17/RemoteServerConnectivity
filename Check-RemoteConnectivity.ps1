Write-Output "`nRunning Connection Check "
    $output = @()
    $pingcon = ""
    $winrmcon = ""
    $Policy = ""
    $HttpPort = ""
    $HttpSPort = ""
    $PublicProfileStatus = ""
    $DomainProfileStatus = ""
    $PrivateProfileStatus = ""

    foreach($server in (Get-Content .\Servers.txt)){

        Write-Output "`nRunning connection check for $server"
         
        if(Test-Connection -ComputerName $server -Count 2 -Quiet -ErrorAction Ignore){$pingcon = "Reachable"}
        else{$pingcon = "NotReachable"}

        if(Test-WSMan -ComputerName $server -ErrorAction Ignore){$winrmcon = "working"}
        else{$winrmcon = "NotWorking"}

        $Policy = (Invoke-Command -ComputerName $server -Scriptblock{Get-ExecutionPolicy} -ErrorAction Ignore).Value 

        $HttpPort = (Test-NetConnection $server -Port 5985).Tcptestsucceeded
        $HttpsPort = (Test-NetConnection $server -Port 5986).Tcptestsucceeded

        if($winrmcon -eq "Working"){
                $FirewallProf = Invoke-Command -ComputerName $server -ScriptBlock{Get-NetFirewallProfile | Select Name, Enabled}
                $PublicProfileStatus = ($FirewallProf | where{$_.Name -eq "Public"}).Enabled.Value
                $PrivateProfileStatus = ($FirewallProf | where{$_.Name -eq "Private"}).Enabled.Value 
                $DomainProfileStatus = ($FirewallProf | where{$_.Name -eq "Domain"}).Enabled.Value
            }
        

        else{
            $PublicProfileStatus = "Unknown"
            $DomainProfileStatus = "Unknown"
            $PrivateProfileStatus = "Unknown"
        }
        
        $output += [PSCustomObject]@{
            "Server_Name" = $server
            "Ping_Connection" = $pingcon
            "WinRM_Conenction" = $winrmcon
            "Policy" = $Policy
            "WINRM_HTTP_Port_Open" = $HttpPort
            "WINRM_HTTPS_Port_Open" = $HttpSPort
            "Firewall_Public_Prof_Enabled?" = $PublicProfileStatus
            "Firewall_Private_Prof_Enabled?" = $PrivateProfileStatus
            "Firewall_Domain_Prof_Enabled?" = $DomainProfileStatus
        }
        
    }

    $output | ft -AutoSize
    $output | Export-Csv .\ConnectionOutput.csv -NoTypeInformation
    Write-Output "`nOutput is stored to ConnectionOutput.Csv in the same script folder"