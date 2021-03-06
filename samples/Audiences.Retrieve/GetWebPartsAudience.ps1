#* **************************************************************************************
# This Sample Code is provided for the purpose of illustration only and is not intended 
# to be used in a production environment.
# THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF
# ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
# We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and
# to reproduce and distribute the object code form of the Sample Code, provided that You
# agree:
#  (i) to not use Our name, logo, or trademarks to market Your software product in which
#      the Sample Code is embedded;
#  (ii) to include a valid copyright notice on Your software product in which the Sample
#      Code is embedded; and
#  (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against
#      any claims or lawsuits, including attorneys’ fees, that arise or result from the
#      use or distribution of the Sample Code
#
#	Created by: Ivan Bondy
#	Email: ibondy@microsoft.com
#	Date: 10/16/2016
#	Purpose: Scans all webparts in site collections pages for audience targeting 
# **************************************************************************************

cls
#Import-Module b:\PnPPowerShell\V15\OfficeDevPnP.PowerShell.Commands.dll 	#onprem
Import-Module b:\PnPPowerShell\V16\OfficeDevPnP.PowerShell.Commands.dll 	#online
Import-Module "C:\Program Files (x86)\SharePoint Online Management Shell\Microsoft.Online.SharePoint.PowerShell\Microsoft.Online.SharePoint.PowerShell.dll"

$outputFile = "<output file location>"
$site = "<site url>"


# Do not modify code below
#==============================================================================
#Gets all document libraries in single web 
function GetDocumentLibraries{
	Param(
	[string] $webUrl
	)
	
	$web = Get-PnPWeb -Identity $webUrl
	$lists = Get-PnPList -Web $web
	$excluded = "Form Templates","Site Assets","Style Library"
	
	foreach($list in $lists.SyncRoot)
	{
		if($list.BaseType -eq "DocumentLibrary" -and $list.Hidden -eq $false -and $excluded.Contains($list.Title) -eq $false)
		{
			$documentLibraries += $list.Title + ","
		}
	}
	$separator = ","
	$option = [System.StringSplitOptions]::RemoveEmptyEntries
	return $documentLibraries.Split($separator,$option)
}

# Gets all webs in site collection
function GetWebs{
	$sites = Get-PnPSite 
	$subs = Get-PnPSubWebs -Web $sites.RootWeb -Recurse
	foreach ($sub in $subs.SyncRoot)
	{
		$subIds += $sub.ServerRelativeUrl + "," 
	}
	$separator = ","
	$option = [System.StringSplitOptions]::RemoveEmptyEntries
	return $subIds.Split($separator,$option)
}

#Processes webs for Audiences targeting in webparts
function ProcessWeb
{
param( [string] $webUrl)
	$docLibraries = GetDocumentLibraries -webUrl $webUrl 
	$x += "<Libraries>"
	foreach ($library in $docLibraries){
		$x += '<Library Title="' + $library +'">'
		$pages = Get-PnPListItem -List $library -Web $webUrl
		$x += "<Pages>"
		foreach($page in $pages.SyncRoot)
		{
			$x +='<Page Url="' + $page.FieldValues["FileLeafRef"] + '">'
			$pageName = $page.FieldValues["FileLeafRef"]
			$url = $page.FieldValues["FileRef"]
			$webparts = get-PnPWebPart -PageUrl $url 
			$webpart = ""
			$x +="<Webparts>"
			foreach ($webpart in  $webparts.SyncRoot)
			{	
				$audience  = $webpart.WebPart.Properties.FieldValues["AuthorizationFilter"]
				if ($audience -eq "")
				{
					$audience = "Not set"
				}
				$x +='<Webpart Title="'+ $webpart.WebPart.Title + '" Audiences="'+ $audience + '">'
				$x += '</Webpart>'	
			}
			$x +="</Webparts>"
			$x += "</Page>"
		}
		$x +="</Pages>"
		$x +="</Library>"		
	}

	$x+="</Libraries>"
	return $x
}

#Connect to site collection
Connect-PnPOnline -Url $site -Credentials (Get-Credential)

#Get all webs
$webs = GetWebs
$xml = '<?xml version="1.0" encoding="utf-8"?>' 
$xml += '<TargetAudienceData>'
$xml +='<Webs>'

#Process webs
foreach ($web in $webs){
	$xml += '<Web Url="' +$web + '">'
	$retxml = ProcessWeb -webUrl $web
	$xml += $retxml
	$xml += '</Web>'
}
$xml +='</Webs>' 
$xml += '</TargetAudienceData>'

Write-Host $xml
$xml | Out-File -Force -FilePath $outputFile

