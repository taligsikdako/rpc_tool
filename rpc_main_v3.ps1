<#
Name:Regular Password Change Preparation
Environment : PRD,STG/DEV and TRN

Changes#
20220120 - Added changes to export where resource name contains or has "vms" on it
and export a csv file under a CSV Directory
#>


$startTime = (Get-Date).Millisecond
0..1000 | ForEach-Object {$i++}

Write-Host 'Declared variables has been cleared'
Remove-Variable * -ErrorAction SilentlyContinue

Write-Host 'Please input folder name'
$FolderName = Read-Host

Write-Host 'Please select a csv file '
Add-Type -AssemblyName System.Windows.Forms
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog
$FileBrowser.filter = "csv (*.csv)| *.csv"
[void]$FileBrowser.ShowDialog()


    if ($FileBrowser.FileName -eq '') {
        Write-Host 'No file Selected, Please choose a CSV File'
    } else {


    $path = 'D:\RegularPasswordChange\' + $FolderName

    if(Test-Path -Path $path){

    Write-Host 'Directory is already exist'
    } else {
    Write-Host 'Directory is not Exist, Creating a Directory...'
    Start-Sleep 1
    md -Force -Path $path
    }

    write-host 'Changing directory to' $path

    #cd $path
    $CSV = $path + '\CSV'
    $Day1 = $path + '\Day1'
    $Day2 = $path + '\Day2'

    Write-Host 'Checking of folder existency, if no folders found, folders will be created accordingly'

    Start-Sleep 1

    if (Test-Path -Path $CSV) {
        Write-Host  $CSV 'Folder Exist'
    } else {
        Write-Host 'No CSV Folder Found, Mkdir \CSV...'
        md -Force -Path $CSV
    }

    if (Test-Path -Path $Day1) {
    Write-Host  $Day1 'Folder Exist'
    } else {
        Write-Host 'No CSV Folder Found, Mkdir \Day1...'
        md -Force -Path $Day1
    }

    
    if (Test-Path -Path $Day2) {
        Write-Host  $Day2 'Folder Exist'
        } else {
            Write-Host 'No CSV Folder Found, Mkdir \Day2...'
            md -Force -Path $Day2
        }

Start-Sleep 1

    Write-Host 'Selected CSV File' $FileBrowser.FileName

    #CSV Deletion Here
    Write-Host 'Currently deleting of old .csv file'
    if(Test-Path -Path $path\CSV\*.csv){
     Write-Host 'Removing / Deleting existing CSV file under CSV directory...'
        rm -r $path\CSV\*.csv

    } else {
        Write-Host 'No CSV Files that needs to be deleted under CSV Folder'
    }

    #CSV Deletion Here
    if(Test-Path -Path $path\Day1\*.csv){
     Write-Host 'Removing / Deleting existing CSV file under Day1  directory..'
    #Deleting a *.csv File only
        rm -r $path\Day1\*.csv
    } else {
        Write-Host 'No CSV Files that needs to be deleted under Day1 Folder'
    }

           #CSV Deletion Here
    if(Test-Path -Path $path\Day2\*.csv){
     Write-Host 'Removing / Deleting existing CSV file under Day2 directory....'
        #rm -r $path\CSV\*.csv
        rm -r $path\Day2\*.csv
        #rm -r $path\Day1\*.csv
    } else {
        Write-Host 'No CSV Files that needs to be deleted under Day2 Folder'
    }
    Write-Host 'Importing'  $FileBrowser.FileName  'and Exporting to windows_os.csv that stored on CSV Directory'

    $export_windows_to_csv = Import-Csv -Path $FileBrowser.FileName | ? 'OS Type' -Like *Windows* | Export-Csv $path\CSV\windows_os.csv -NoTypeInformation
    $export_vmware_to_csv = Import-Csv -Path $FileBrowser.FileName | ? 'Resource Name' -CLike *vms* | Export-Csv $path\CSV\vmware_esxi.csv -NoTypeInformation
    
    <#Windows RPC Staging starts here #>
    start-sleep 1

    function fn_VmWare {
        $datafile = $path + '\CSV\vmware_esxi.csv'
        $ExportedFileCSV = $path + '\Day1\passwdvmware.csv'
        $dataInput = Import-Csv $datafile

        $dataInput | ForEach-Object { 
        $newData = $_
        $newRecordProperties = [ordered]@{
        "server"= $newData.'Resource Name'
        "vmware.old"= $newData.'Old Password' #$newData.LoginUser
        "vmware.new"= $newData.Password
        "timeout"= $newData.timeout
        #"AddUserInfo"= ""
        #"AddUserGroup"= ""
        #"NewPasswd"= $newData.Password
        #"DelUserName"= ""
       #"PasswdChangeUserName"= $newData.'User Account'
         }
        $newRecord = New-Object psobject -Property $newRecordProperties
         Write-Output $newRecord

        }| Export-Csv  $ExportedFileCSV -Append -NoTypeInformation 

    }

    fn_VmWare
    
    function fn_windows_stg {


    $export_windows_stg_to_csv = Import-Csv -Path $path\CSV\windows_os.csv | ? 'Env' -Like *Stg* | Export-Csv $path\CSV\windows_os_stg.csv -NoTypeInformation
    $datafile = $path + '\CSV\windows_os_stg.csv'
    $ExportedFileCSV = $path + '\CSV\Serverlist_Template.csv'
    $dataInput = Import-Csv $datafile

    #Commented out 
    #$data_output = Import-Csv $ExportedFileCSV -ErrorAction SilentlyContinue
    

    $dataInput | ForEach-Object {

    $newData = $_
    $newRecordProperties = [ordered]@{
        "Hostname"= $newData.'Resource Name'
        "LoginUser"= $newData.LoginUser
        "LoginPassword"= $newData.'Old Password'
        "AddUserName"= ""
        "AddUserInfo"= ""
        "AddUserGroup"= ""
        "NewPasswd"= $newData.Password
        "DelUserName"= ""
        "PasswdChangeUserName"= $newData.'User Account'
    }
    $newRecord = New-Object psobject -Property $newRecordProperties
    Write-Output $newRecord
     } | Export-Csv  $ExportedFileCSV -Append -NoTypeInformation 

 
     Write-Host 'Importing Serverlist_Template.csv... and Exporting to windows_stg.csv '
     Import-Csv $path\CSV\Serverlist_Template.csv | Where-Object 'Hostname' -Like ** | Export-Csv -Path $path\CSV\windows_stg.csv -Append -NoTypeInformation
  
     $qajp1win12 = Import-Csv -Path $path\CSV\Serverlist_Template.csv
     $qajp1win12 | foreach { if($_.Hostname -eq 'qajp1win12'){$_.Hostname = '10.1.225.32'}} 
     $qajp1win12 | Export-Csv $path\CSV\windows_stg.csv -NoTypeInformation

     #Look for pncdeva1 target server and update target password
     #commented out due to unnecessary
     #Write-Host 'Importing windows_stg.csv...'
     $ImportWindowsSTG = Import-Csv -Path $path\CSV\windows_stg.csv
     $GetPassword = $ImportWindowsSTG | Where-Object 'Hostname' -EQ 'pncdeva1' | Where-Object 'PasswdChangeUserName' -eq 'Administrator'

     $ImportWindowsSTG | foreach {if($_.Hostname -eq 'pncdeva1' -and $_.PasswdChangeUserName -eq 'unyo') {$_.LoginPassword = $GetPassword.NewPasswd}}
     $ImportWindowsSTG | Export-Csv $path\Day2\Serverlist_password_stg.csv -NoTypeInformation

     Import-Csv $path\Day2\Serverlist_password_stg.csv | Where-Object 'PasswdChangeUserName' -Match 'unyo|administrator' | Export-Csv -Path $path\CSV\windows_stg_login.csv -Append -NoTypeInformation

     $Importwindows_stg_login = Import-Csv -Path $path\CSV\windows_stg_login.csv

     <#pncdeva1 add unyo to serverlogin Start #>
     $GetUnyoPncdeva1 =  $Importwindows_stg_login | Where-Object 'Hostname' -EQ 'pncdeva1' | Where-Object 'PasswdChangeUserName' -eq 'unyo'
     $Importwindows_stg_login | foreach {if($_.Hostname -eq 'pncdeva1' -and $_.PasswdChangeUserName -eq 'unyo') {$_.LoginPassword = $GetUnyoPncdeva1.NewPasswd}}
     $Importwindows_stg_login | foreach {if($_.Hostname -eq 'pncdeva1' -and $_.PasswdChangeUserName -eq 'unyo') {$_.LoginUser = $GetUnyoPncdeva1.PasswdChangeUserName}}
      $Importwindows_stg_login | Export-Csv $path\CSV\WindowsServerLoginSTG.csv -NoTypeInformation
     <#pncdeva1 add unyo to serverlogin End #>

    function export_login_checker {

    $Logindatafile = $path + '\CSV\WindowsServerLoginSTG.csv'
    $ExportedLogin = $path + '\Day2\Serverlist_login_stg.csv'

    #commented out code below, due to not necessary to import
    #$server_login_output = Import-Csv $ExportedLogin -ErrorAction SilentlyContinue

    $ServerInput = Import-Csv $Logindatafile

    $ServerInput | ForEach-Object {

        $newLoginData = $_
        $newLoginRecordProperties = [ordered]@{
         "Hostname"= $newLoginData.Hostname
         "LoginUser"= $newLoginData.LoginUser
         "LoginPassword"= $newLoginData.NewPasswd
         "AddUserName"= ""
         "AddUserInfo"= ""
         "AddUserGroup"= ""
         "NewPasswd"= ""
         "DelUserName"= ""
         "PasswdChangeUserName"= ""
        }
        $newLoginRecord = New-Object psobject -Property $newLoginRecordProperties
        Write-Output $newLoginRecord
 } | Export-Csv  $ExportedLogin -Append -NoTypeInformation
}
export_login_checker
}

fn_windows_stg
 <#Windows RPC Staging ends here #>

 <#Windows RPC Prod begins here #>
function fn_windows_prd {

#Extracted only type of OS equal to 'Windows'
<#Date CO :  2021/11/01
Reason: Change to Global, below variable have been call or used already at STG environment of Windows
$export_windows_to_csv = Import-Csv -Path $FileBrowser.FileName | ? 'OS Type' -Like *Windows* | Export-Csv $path\windows_os.csv -NoTypeInformation
#>
#Extracted only type of ENV equal to 'PRD'
$export_windows_prd_to_csv = Import-Csv -Path $path\CSV\windows_os.csv | ? 'Env' -Like *Prod* | Export-Csv $path\CSV\windows_os_prd.csv -NoTypeInformation
$datafile = $path + '\CSV\windows_os_prd.csv'
$ExportedFileCSV = $path + '\CSV\Serverlist_TemplatePRD.csv'
$dataInput = Import-Csv $datafile

#Test-Path -Path $path\CSV\Serverlist_TemplatePRD.csv -PathType Leaf
#r
#$data_output = Import-Csv $ExportedFileCSV -ErrorAction SilentlyContinue

  $dataInput | ForEach-Object {

    $newData = $_
    $newRecordProperties = [ordered]@{
     "Hostname"= $newData.'Resource Name'
     "LoginUser"= $newData.LoginUser
     "LoginPassword"= $newData.'Old Password'
     "AddUserName"= ""
     "AddUserInfo"= ""
     "AddUserGroup"= ""
     "NewPasswd"= $newData.Password
     "DelUserName"= ""
     "PasswdChangeUserName"= $newData.'User Account'
    }
    $newRecord = New-Object psobject -Property $newRecordProperties
    Write-Output $newRecord
 } | Export-Csv  $ExportedFileCSV -Append -NoTypeInformation 

    Import-Csv $path\CSV\Serverlist_TemplatePRD.csv | Where-Object 'Hostname' -Like ** | Export-Csv -Path $path\CSV\windows_prd.csv -Append -NoTypeInformation

    #Look for pncdba1 and update administrator password
     $ImportWindowsPRD = Import-Csv -Path $path\CSV\windows_prd.csv
     $GetPassword = $ImportWindowsPRD | Where-Object 'Hostname' -EQ 'pncdba1' | Where-Object 'PasswdChangeUserName' -eq 'Administrator'
     $GetPwdPNCWEBA1 = $ImportWindowsPRD | Where-Object 'Hostname' -EQ 'pncweba1' | Where-Object 'PasswdChangeUserName' -eq 'Administrator'
     $GetPwdhfmweba1 = $ImportWindowsPRD | Where-Object 'Hostname' -EQ 'hfmweba1' | Where-Object 'PasswdChangeUserName' -eq 'Administrator'
     $GetPwdhfmweba2 = $ImportWindowsPRD | Where-Object 'Hostname' -EQ 'hfmweba2' | Where-Object 'PasswdChangeUserName' -eq 'Administrator'
     $GetPwdhfmweba3 = $ImportWindowsPRD | Where-Object 'Hostname' -EQ 'hfmweba3' | Where-Object 'PasswdChangeUserName' -eq 'Administrator'
     
     #pncdba1
     #$ImportWindowsPRD | foreach {if($_.Hostname -eq 'pncdba1' -and $_.PasswdChangeUserName -eq 'Administrator') {$_.LoginPassword = $GetPassword.NewPasswd}}
     $ImportWindowsPRD | foreach {if($_.Hostname -eq 'pncdba1' -and $_.PasswdChangeUserName -eq 'alftp') {$_.LoginPassword = $GetPassword.NewPasswd}}
     $ImportWindowsPRD | foreach {if($_.Hostname -eq 'pncdba1' -and $_.PasswdChangeUserName -eq 'unyo') {$_.LoginPassword = $GetPassword.NewPasswd}}     
     $ImportWindowsPRD | foreach {if($_.Hostname -eq 'pncdba1' -and $_.PasswdChangeUserName -eq 'alftp') {$_.LoginUser = 'Administrator'}}
     $ImportWindowsPRD | foreach {if($_.Hostname -eq 'pncdba1' -and $_.PasswdChangeUserName -eq 'unyo') {$_.LoginUser = 'Administrator'}}
     
     
     #pncweba1
     $ImportWindowsPRD | foreach {if($_.Hostname -eq 'pncweba1' -and $_.PasswdChangeUserName -eq 'unyo') {$_.LoginPassword = $GetPwdPNCWEBA1.NewPasswd}}
     $ImportWindowsPRD | foreach {if($_.Hostname -eq 'pncweba1' -and $_.PasswdChangeUserName -eq 'alftp') {$_.LoginPassword = $GetPwdPNCWEBA1.NewPasswd}}
     $ImportWindowsPRD | foreach {if($_.Hostname -eq 'pncweba1' -and $_.PasswdChangeUserName -eq 'alftp') {$_.LoginUser = 'Administrator'}}
     $ImportWindowsPRD | foreach {if($_.Hostname -eq 'pncweba1' -and $_.PasswdChangeUserName -eq 'unyo') {$_.LoginUser = 'Administrator'}}

     #hfmweba1
     $ImportWindowsPRD | foreach {if($_.Hostname -eq 'hfmweba1' -and $_.PasswdChangeUserName -eq 'unyo') {$_.LoginPassword = $GetPwdhfmweba1.NewPasswd}}
     $ImportWindowsPRD | foreach {if($_.Hostname -eq 'hfmweba1' -and $_.PasswdChangeUserName -eq 'alftp') {$_.LoginPassword = $GetPwdhfmweba1.NewPasswd}}
     $ImportWindowsPRD | foreach {if($_.Hostname -eq 'hfmweba1' -and $_.PasswdChangeUserName -eq 'alftp') {$_.LoginUser = 'Administrator'}}
     $ImportWindowsPRD | foreach {if($_.Hostname -eq 'hfmweba1' -and $_.PasswdChangeUserName -eq 'unyo') {$_.LoginUser = 'Administrator'}}

     #hfmweba2
      $ImportWindowsPRD | foreach {if($_.Hostname -eq 'hfmweba2' -and $_.PasswdChangeUserName -eq 'unyo') {$_.LoginPassword = $GetPwdhfmweba2.NewPasswd}}
     $ImportWindowsPRD | foreach {if($_.Hostname -eq 'hfmweba2' -and $_.PasswdChangeUserName -eq 'alftp') {$_.LoginPassword = $GetPwdhfmweba2.NewPasswd}}
     $ImportWindowsPRD | foreach {if($_.Hostname -eq 'hfmweba2' -and $_.PasswdChangeUserName -eq 'alftp') {$_.LoginUser = 'Administrator'}}
     $ImportWindowsPRD | foreach {if($_.Hostname -eq 'hfmweba2' -and $_.PasswdChangeUserName -eq 'unyo') {$_.LoginUser = 'Administrator'}}

     #hfmweba3
     $ImportWindowsPRD | foreach {if($_.Hostname -eq 'hfmweba3' -and $_.PasswdChangeUserName -eq 'unyo') {$_.LoginPassword = $GetPwdhfmweba3.NewPasswd}}
     $ImportWindowsPRD | foreach {if($_.Hostname -eq 'hfmweba3' -and $_.PasswdChangeUserName -eq 'alftp') {$_.LoginPassword = $GetPwdhfmweba3.NewPasswd}}
     $ImportWindowsPRD | foreach {if($_.Hostname -eq 'hfmweba3' -and $_.PasswdChangeUserName -eq 'alftp') {$_.LoginUser = 'Administrator'}}
     $ImportWindowsPRD | foreach {if($_.Hostname -eq 'hfmweba3' -and $_.PasswdChangeUserName -eq 'unyo') {$_.LoginUser = 'Administrator'}}
     $ImportWindowsPRD | Export-Csv $path\CSV\Serverlist_password_prd_temp.csv -NoTypeInformation

     #Start pncweba1 and pncdba1 add unyo user for Login Check
     Import-Csv $path\CSV\Serverlist_password_prd_temp.csv | Where-Object 'LoginUser' -CLike *dministrator* | Export-Csv -Path $path\Day2\Serverlist_password_prd.csv -Append -NoTypeInformation
     Import-Csv $path\CSV\Serverlist_password_prd_temp.csv | Where-Object 'PasswdChangeUserName' -Match 'unyo|administrator|PRT\Administrator'| Export-Csv -Path $path\CSV\windows_prd_login.csv -Append -NoTypeInformation
     $Importwindows_prd_login = Import-Csv -Path $path\CSV\windows_prd_login.csv

     $GetUnyoPNCWEBA1 = $Importwindows_prd_login | Where-Object 'Hostname' -EQ 'pncweba1' | Where-Object 'PasswdChangeUserName' -eq 'unyo'
     $GetUnyPNCDBA1 = $Importwindows_prd_login | Where-Object 'Hostname' -EQ 'pncdba1' | Where-Object 'PasswdChangeUserName' -eq 'unyo'
     #PNCWEBA1
     $Importwindows_prd_login | foreach{if($_.Hostname -eq 'pncweba1' -and $_.PasswdChangeUserName -eq 'unyo') {$_.LoginPassword = $GetUnyoPNCWEBA1.NewPasswd}}
     $Importwindows_prd_login | foreach{if($_.Hostname -eq 'pncweba1' -and $_.PasswdChangeUserName -eq 'unyo') {$_.LoginUser = $GetUnyoPNCWEBA1.PasswdChangeUserName}}
     #PNCDBA1
     $Importwindows_prd_login | foreach{if($_.Hostname -eq 'pncdba1' -and $_.PasswdChangeUserName -eq 'unyo') {$_.LoginPassword = $GetUnyPNCDBA1.NewPasswd}}
     $Importwindows_prd_login | foreach{if($_.Hostname -eq 'pncdba1' -and $_.PasswdChangeUserName -eq 'unyo') {$_.LoginUser = $GetUnyPNCDBA1.PasswdChangeUserName}}
     $Importwindows_prd_login | Export-Csv $path\CSV\windowsServerLoginCheck.csv -NoTypeInformation
     #End pncweba1 add unyo user for Login Check
   
    function export_login_checker {

    $Logindatafile = $path + '\CSV\windowsServerLoginCheck.csv'
    $ExportedLogin = $path + '\Day2\Serverlist_login_prd.csv' #template only

    
    $ServerInput = Import-Csv $Logindatafile

    $ServerInput | ForEach-Object {

        $newLoginData = $_
        $newLoginRecordProperties = [ordered]@{
         "Hostname"= $newLoginData.Hostname
         "LoginUser"= $newLoginData.LoginUser
         "LoginPassword"= $newLoginData.NewPasswd
         "AddUserName"= ""
         "AddUserInfo"= ""
         "AddUserGroup"= ""
         "NewPasswd"= ""
         "DelUserName"= ""
         "PasswdChangeUserName"= ""
        }
        $newLoginRecord = New-Object psobject -Property $newLoginRecordProperties
        Write-Output $newLoginRecord
 } | Export-Csv  $ExportedLogin -Append -NoTypeInformation
}
export_login_checker

}
fn_windows_prd

<#Windows RPC Prod ends here #>
<#Windows RPC TRN Starts here #>

function fn_windows_trn {

#Extracted only type of ENV equal to 'TRN'
$export_windows_stg_to_csv = Import-Csv -Path $path\CSV\windows_os.csv | ? 'Env' -Like *Trn* | Export-Csv $path\CSV\windows_os_trn.csv -NoTypeInformation
$datafile = $path + '\CSV\windows_os_trn.csv'
$ExportedFileCSV = $path + '\CSV\Serverlist_Templatetrn.csv' <#Common for Windows #>
$dataInput = Import-Csv $datafile
   
  $dataInput | ForEach-Object {

    $newData = $_
    $newRecordProperties = [ordered]@{
     "Hostname"= $newData.'Resource Name'
     "LoginUser"= $newData.LoginUser
     "LoginPassword"= $newData.'Old Password'
     "AddUserName"= ""
     "AddUserInfo"= ""
     "AddUserGroup"= ""
     "NewPasswd"= $newData.Password
     "DelUserName"= ""
     "PasswdChangeUserName"= $newData.'User Account'
    }
    $newRecord = New-Object psobject -Property $newRecordProperties
    Write-Output $newRecord
 } | Export-Csv  $ExportedFileCSV -Append -NoTypeInformation 

 
 
 Import-Csv $path\CSV\Serverlist_Templatetrn.csv | Where-Object 'PasswdChangeUserName' -CLike *dministrator* | Export-Csv -Path $path\Day2\Serverlist_password_trn.csv -Append -NoTypeInformation
  
<# Windows TRN Login #>
function export_login_checker {

    $Logindatafile = $path + '\Day2\Serverlist_password_trn.csv'
    $ExportedLogin = $path + '\Day2\Serverlist_login_trn.csv' #templateonly
    #commented out
    #$server_login_output = Import-Csv $ExportedLogin -ErrorAction SilentlyContinue
    $ServerInput = Import-Csv $Logindatafile

    $ServerInput | ForEach-Object {

        $newLoginData = $_
        $newLoginRecordProperties = [ordered]@{
         "Hostname"= $newLoginData.Hostname
         "LoginUser"= $newLoginData.LoginUser
         "LoginPassword"= $newLoginData.NewPasswd
         "AddUserName"= ""
         "AddUserInfo"= ""
         "AddUserGroup"= ""
         "NewPasswd"= ""
         "DelUserName"= ""
         "PasswdChangeUserName"= ""
        }
        $newLoginRecord = New-Object psobject -Property $newLoginRecordProperties
        Write-Output $newLoginRecord
 } | Export-Csv  $ExportedLogin -Append -NoTypeInformation
}
export_login_checker
 
}
fn_windows_trn
<#Windows RPC TRN ENDS HERE #>


<# Linux RPC Staging begins here
#>


function fn_linux_stg {
 
        $export_linux_os_to_csv = Import-Csv -Path $FileBrowser.FileName | ? 'OS Type' -Like *Linux* | Export-Csv $path\CSV\linux_os.csv -NoTypeInformation
        $export_linux_os_stg_to_csv = Import-Csv -Path $path\CSV\linux_os.csv | ? 'Env' -Like *STG* | Export-Csv $path\CSV\linux_os_stg.csv -NoTypeInformation
        $export_linux_os_stg_root = Import-Csv -Path $path\CSV\linux_os_stg.csv | ? 'User Account' -Like *root* | Export-Csv $path\CSV\linux_os_stg_root.csv -NoTypeInformation
        $export_linux_os_stg_unyo = Import-Csv -Path $path\CSV\linux_os_stg.csv | ? 'User Account' -Like *unyo* | Export-Csv $path\CSV\linux_os_stg_unyo.csv -NoTypeInformation

#Declared as Global variable $datafile for created function
    $datafile = $path + '\CSV\linux_os_stg_root.csv'

    function linux_root {

        $ExportedFileCSV = $path + '\CSV\stg_passwd_root_template.csv'
        $dataInput = Import-Csv $datafile
        #Commented out 2021/11/15
        #$data_output = Import-Csv $ExportedFileCSV 


        $dataInput | ForEach-Object {
            $newData = $_
            $newRecordProperties = [ordered]@{
             "server"= $newData.'Resource Name'
             "jsox"= $newData.jsox
             "unyo.old"= ""
             "unyo.new"= ""
             "root.old"= $newData.'Old Password'
             "root.new"= $newData.Password
             
             "timeout"= $newData.timeout
        }
        $newRecord = New-Object psobject -Property $newRecordProperties
        Write-Output $newRecord
    } | Export-Csv  $ExportedFileCSV  -NoTypeInformation
    }

linux_root

#Function where we update the existing CSV File column target server name:stg_passwd_root_template, and insert unyo credential for each target server 
    function update_linux_stg {

    if (Test-Path -Path $datafile) {
        $DataSource = Import-Csv -Path $path\CSV\linux_os_stg_unyo.csv
    } else {
        Write-Host 'No linux_os_stg_unyo.csv has been found'
    }

        $DataResults = Import-Csv -Path $path\CSV\stg_passwd_root_template.csv

        $DataHT = @{}
        $DataResults | ForEach-Object { $DataHT.Add($_.server,$_) }

        ForEach( $Record in $DataSource ){
         $DataHT[$Record.'Resource Name'].'unyo.old' = $Record.'Old Password'
         $DataHT[$Record.'Resource Name'].'unyo.new' = $Record.Password
 
        } 

        $DataHT.Values | Export-Csv -Path $path\Day1\passwd.unyo.root_stg.csv -NoTypeInformation

}

        update_linux_stg
        <# 
        BEGIN Login Checker Scripts
        #>

        
        function export_login_checker {
        $Logindatafile = $path + '\Day1\passwd.unyo.root_stg.csv'
        $ExportedLogin = $path + '\Day1\login.unyo.root_stg.csv'
        #commented out
        #Import-Csv $ExportedLogin
   
        $ServerInput = Import-Csv $Logindatafile
        $ServerInput | ForEach-Object {

            $newLoginData = $_
            $newLoginRecordProperties = [ordered]@{
             "server"= $newLoginData.server
             "jsox"= $newLoginData.jsox
             "unyo.new"= $newLoginData."unyo.new"
             "root.new"= $newLoginData."root.new"
             "timeout"=$newLoginData.timeout

            }
            $newLoginRecord = New-Object psobject -Property $newLoginRecordProperties
            Write-Output $newLoginRecord
         } | Export-Csv  $ExportedLogin -Append -NoTypeInformation
}
export_login_checker

  }
  fn_linux_stg
  <#Linux RPC Staging ends here #>

  <#fn_linux_prd
  Starts here
   #>

  function fn_linux_prd {

  #  $export_linux_os_to_csv = Import-Csv -Path $FileBrowser.FileName | ? 'OS Type' -Like *Linux* | Export-Csv $path\CSV\linux_os.csv -NoTypeInformation
    $export_linux_os_prd_to_csv = Import-Csv -Path $path\CSV\linux_os.csv | ? 'Env' -Like *Prod* | Export-Csv $path\CSV\linux_os_prd.csv -NoTypeInformation
    $export_linux_os_prd_root = Import-Csv -Path $path\CSV\linux_os_prd.csv | ? 'User Account' -Like *root* | Export-Csv $path\CSV\linux_os_prd_root.csv -NoTypeInformation
    $export_linux_os_prd_unyo = Import-Csv -Path $path\CSV\linux_os_prd.csv | ? 'User Account' -Like *unyo* | Export-Csv $path\CSV\linux_os_prd_unyo.csv -NoTypeInformation
    $export_linux_os_prd_alftp = Import-Csv -Path $path\CSV\linux_os_prd.csv | ? 'User Account' -Like *alftp* | Export-Csv $path\CSV\linux_os_prd_alftp.csv -NoTypeInformation

<#
This function serves as 
#>
function linux_root {

    $export_linux_root_to_csv = Import-Csv -Path $path\CSV\linux_os_prd_unyo.csv | ? 'User Account' -like *unyo* |
        Export-Csv $path\CSV\exported_linux_prd_unyo.csv

    $datafile = $path + '\CSV\exported_linux_prd_unyo.csv'

    $ExportedFileCSV = $path + '\CSV\prd_passwd_unyo_template.csv'

    $dataInput = Import-Csv $datafile
    #Commented out 2021/11/15
    #$dataOutput = Import-Csv $ExportedFileCSV
     

    $dataInput | ForEach-Object {
        $newData = $_
        $newRecordProperties = [ordered]@{
         "server"= $newData.'Resource Name'
         "jsox"= $newData.jsox
         "unyo.old"= $newData.'Old Password'
         "unyo.new"= $newData.Password         
         "root.old"= ""
         "root.new"= ""
         "timeout"= $newData.timeout
    }
    $newRecord = New-Object psobject -Property $newRecordProperties
    Write-Output $newRecord
} | Export-Csv  $ExportedFileCSV  -NoTypeInformation
}

linux_root

#function where we update the linux root data and insert the linux unyo data
function update_linux_prd {

$DataSource = Import-Csv -Path $path\CSV\linux_os_prd_root.csv
$DataResults = Import-Csv -Path $path\CSV\prd_passwd_unyo_template.csv

$DataHT = @{}
$DataResults | ForEach-Object { $DataHT.Add($_.server,$_) }

ForEach( $Record in $DataSource ){
 $DataHT[$Record.'Resource Name'].'root.old' = $Record.'Old Password'
 $DataHT[$Record.'Resource Name'].'root.new' = $Record.Password
} 

$DataHT.Values | Export-Csv -Path $path\Day1\passwd.unyo.root_prd.csv -NoTypeInformation
}

update_linux_prd



<# 
Login Checker Scripts
#>

function export_login_checker {

    $Logindatafile = $path + '\Day1\passwd.unyo.root_prd.csv'
    $ExportedLogin = $path + '\Day1\login.unyo.root_prd.csv'

    #$server_login_output = Import-Csv $ExportedLogin -ErrorAction SilentlyContinue
    $ServerInput = Import-Csv $Logindatafile
 
    

    $ServerInput | ForEach-Object {

        $newLoginData = $_
        $newLoginRecordProperties = [ordered]@{
         "server"= $newLoginData.server
         "jsox"= $newLoginData.jsox
         "unyo.new"= $newLoginData."unyo.new"
         "root.new"= $newLoginData."root.new"
         "timeout"=$newLoginData.timeout

        }
        $newLoginRecord = New-Object psobject -Property $newLoginRecordProperties
        Write-Output $newLoginRecord
     } | Export-Csv  $ExportedLogin -Append -NoTypeInformation
}
    export_login_checker


<#
Extracting alftp
#>
function extracting_alftp_to_new_template {

    $export_linux_root_to_csv = Import-Csv -Path $path\CSV\linux_os_prd_unyo.csv | ? 'User Account' -like *unyo* | Export-Csv $path\CSV\exported_linux_prd_unyo.csv

   

    $datafile = $path + '\CSV\linux_os_prd_alftp.csv'

    $ExportedFileCSV = $path + '\CSV\prd_passwd_alftp_template.csv'

    $dataInput = Import-Csv $datafile
    #$dataOutput = Import-Csv $ExportedFileCSV
 
 

    $dataInput | ForEach-Object {
        $newData = $_
        $newRecordProperties = [ordered]@{
         "server"= $newData.'Resource Name'
         "jsox"= $newData.jsox
         "login.pwd"= $null #This is unyo data
         "tgt.usr"= $newData.'User Account' #target alftp user only
         "tgt.old"= $newData.'Old Password' #alftp new password
         "tgt.new"= $newData.Password #alftp new password
         "timeout"= $newData.timeout
    }
    $newRecord = New-Object psobject -Property $newRecordProperties
    Write-Output $newRecord
} | Export-Csv  $ExportedFileCSV  -NoTypeInformation
}

#prd_passwd_alftp_template
Write-Host "Exporting  template for passwd_alftp"
extracting_alftp_to_new_template

<# 
Updating alftp template
where we update login.pwd collumn into each alftp servers
#>
function update_alftp_prd {

    $DataSource = Import-Csv -Path $path\CSV\prd_passwd_unyo_template.csv #source file
    $DataResults = Import-Csv -Path $path\CSV\prd_passwd_alftp_template.csv #File that needs to update

    $DataHT = @{}
    $DataResults | ForEach-Object { 
    $DataHT.Add($_.server,$_)
    }

[string] $propertyNationality = 'login.pwd';
 
    function hasProperty($object, $propertyName)
    {
        $hasProperty = $propertyName -in $object.PSobject.Properties.Name;
 
        return($hasProperty);
    }

    ForEach($Record in $DataSource){   

    try {
     $DataHT[$Record.server].'login.pwd' = $Record.'unyo.new'
    } catch {
    if(Test-Path -Path $path\CSV\log.txt) {
    rm -Recurse $path\CSV\log.txt
    }  
   "Login.pwd property is not found " | Add-Content  $path\CSV\log.txt
    }
   
    <#
        $propNationalityExists = hasProperty $Record propertyNationality
        if ($propNationalityExists -eq $true)
        {
          $DataHT[$Record.server].'login.pwd' = $Record.'unyo.new'  
        } else {
        
        }#>
    }
    $DataHT.Values | Export-Csv -Path $path\Day2\passwd.sonota.csv -NoTypeInformation
}

    update_alftp_prd
 }

 fn_linux_prd
 <#Linux RPC PRD ends here #>

    <#Linux Trainng #>
    function fn_linux_trn {

            #Write-Host 'CSV File has been selected it will be imported shortly...'
        # $export_linux_os_to_csv = Import-Csv -Path $FileBrowser.FileName | ? 'OS Type' -Like *Linux* | Export-Csv $path\CSV\linux_os.csv -NoTypeInformation
        $export_linux_os_stg_to_csv = Import-Csv -Path $path\CSV\linux_os.csv | ? 'Env' -Like *Trn* | Export-Csv $path\CSV\linux_os_trn.csv -NoTypeInformation
        $export_linux_os_stg_root = Import-Csv -Path $path\CSV\linux_os_trn.csv | ? 'User Account' -Like *root* | Export-Csv $path\CSV\linux_os_trn_root.csv -NoTypeInformation
        $export_linux_os_stg_unyo = Import-Csv -Path $path\CSV\linux_os_trn.csv | ? 'User Account' -Like *unyo* | Export-Csv $path\CSV\linux_os_trn_unyo.csv -NoTypeInformation

    #Declared as Global variable $datafile for created function
        $datafile = $path + '\CSV\linux_os_trn_root.csv'

        function linux_root {

            $ExportedFileCSV = $path + '\CSV\trn_passwd_root_template.csv'
            $dataInput = Import-Csv $datafile
            #$data_output = Import-Csv $ExportedFileCSV 


            $dataInput | ForEach-Object {
                $newData = $_
                $newRecordProperties = [ordered]@{
                 "server"= $newData.'Resource Name'
                 "jsox"= $newData.jsox
                 "unyo.old"= ""
                 "unyo.new"= ""
                 "root.old"= $newData.'Old Password'
                 "root.new"= $newData.Password
             
                 "timeout"= $newData.timeout
            }
            $newRecord = New-Object psobject -Property $newRecordProperties
            Write-Output $newRecord
        } | Export-Csv  $ExportedFileCSV  -NoTypeInformation
        }

    linux_root

    #Function where we update the existing CSV File column target server name:stg_passwd_root_template, and insert unyo credential for each target server 
        function update_linux_trn {

        $DataSource = Import-Csv -Path $path\CSV\linux_os_trn_unyo.csv
        $DataResults = Import-Csv -Path $path\CSV\trn_passwd_root_template.csv

        $DataHT = @{}
        $DataResults | ForEach-Object { $DataHT.Add($_.server,$_) }

        ForEach( $Record in $DataSource ){
            $DataHT[$Record.'Resource Name'].'unyo.old' = $Record.'Old Password'
            $DataHT[$Record.'Resource Name'].'unyo.new' = $Record.Password 
 
            } 

            $DataHT.Values | Export-Csv -Path $path\Day1\passwd.unyo.root_trn.csv -NoTypeInformation

    }

            update_linux_trn
            <# 
            BEGIN Login Checker Scripts
            #>

        
            function export_login_checker {
            $Logindatafile = $path + '\Day1\passwd.unyo.root_trn.csv'
            $ExportedLogin = $path + '\Day1\login.unyo.root_trn.csv'

            $ServerInput = Import-Csv $Logindatafile
            $ServerInput | ForEach-Object {

                $newLoginData = $_
                $newLoginRecordProperties = [ordered]@{
                 "server"= $newLoginData.server
                 "jsox"= $newLoginData.jsox
                 "unyo.new"= $newLoginData."unyo.new"
                 "root.new"= $newLoginData."root.new"
                 "timeout"=$newLoginData.timeout

                }
                $newLoginRecord = New-Object psobject -Property $newLoginRecordProperties
                Write-Output $newLoginRecord
             } | Export-Csv  $ExportedLogin -Append -NoTypeInformation
    }
    export_login_checker


    }
    fn_linux_trn

}  

$TimeEnd = (Get-Date).Millisecond
Write-Host "Completed"
Write-Host "This script took $($TimeEnd - $startTime) milliseconds to run"

Read-Host -Prompt "Press any key to continue or CTRL+C to quit"