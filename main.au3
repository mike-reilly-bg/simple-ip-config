#NoTrayIcon
#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=icon.ico
#AutoIt3Wrapper_Outfile=BG IP Config Tool.exe
#AutoIt3Wrapper_Outfile_x64=BG IP Config 1.0.0-x64.exe
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Description=BG IP Config Tool
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0
#AutoIt3Wrapper_Res_requestedExecutionLevel=requireAdministrator
#AutoIt3Wrapper_Res_HiDpi=y
#AutoIt3Wrapper_Run_AU3Check=n
#AutoIt3Wrapper_Tidy_Stop_OnError=n
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#Region license
; -----------------------------------------------------------------------------
; Simple IP Config is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; Simple IP Config is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with Simple IP Config.  If not, see <http://www.gnu.org/licenses/>.
; -----------------------------------------------------------------------------
#EndRegion license

;==============================================================================
; Filename:		main.au3
; Description:	- call functions to read profiles, get adapters list, create the gui
;				- while loop to keep program running
;				- check for instance already running
;==============================================================================


;==============================================================================
;
; Name:    		 Simple IP Config
;
; Description:   Simple IP Config is a program for Windows to easily change
;				 various network settings in a format similar to the
;				 built-in Windows configuration.
;
; Required OS:   Windows XP, Windows Vista, Windows 7, Windows 8, Window 8.1, Windows 10
;
; Author:      	 Kurtis Liggett
;
;==============================================================================



#include <WindowsConstants.au3>
#include <APIConstants.au3>
#include <WinAPI.au3>
#include <WinAPIEx.au3>
#include <GDIPlus.au3>
#include <GUIImageList.au3>
#include <GuiListView.au3>
#include <GuiIPAddress.au3>
#include <GuiMenu.au3>
#include <Misc.au3>
#include <Color.au3>
#include <GUIEdit.au3>
#include <GuiComboBox.au3>
#include <Array.au3>
#include <Date.au3>
#include <Inet.au3>
#include <File.au3>

#include "libraries\GetInstalledPath.au3"
#include "libraries\AutoItObject.au3"
#include "libraries\oLinkedList.au3"
_AutoItObject_StartUp()

#Region options
Opt("TrayIconHide", 0)
Opt("GUIOnEventMode", 1)
Opt("TrayAutoPause", 0)
Opt("TrayOnEventMode", 1)
Opt("TrayMenuMode", 3)
Opt("MouseCoordMode", 2)
Opt("GUIResizeMode", $GUI_DOCKALL)
Opt("WinSearchChildren", 1)
Opt("GUICloseOnESC", 0)
;~ Opt("MustDeclareVars", 1)
TraySetClick(16)
#EndRegion options

; autoit wrapper options
;#AutoIt3Wrapper_UseX64=Y

#Region Global Variables
Global $options
Global $profiles
Global $adapters

#include <GUIConstantsEx.au3>

; Global constants, for code readability
Global Const $wbemFlagReturnImmediately = 0x10
Global Const $wbemFlagForwardOnly = 0x20

Global $screenshot = 0
Global $sProfileName

;set profile name based on installation and script dir
_setProfilesIniLocation()


;GUI stuff
Global $winName = "RPW IP Config Tool"
Global $winVersion = "3.0"
Global $winDate = "8/2/2022"
Global $hgui
Global $guiWidth = 600
Global $guiHeight = 625
Global $footerHeight = 16
Global $tbarHeight = 0
Global $dscale = 1
Global $iDPI = 0

Global $headingHeight = 20
Global $menuHeight, $captionHeight
Global $MinToTray, $RestoreItem, $aboutitem, $exititem, $exititemtray

Global $aAccelKeys[13][2]

;GUI Fonts
Global $MyGlobalFontName = "Arial"
Global $MyGlobalFontSize = 9.5
Global $MYGlobalFontSizeLarge = 11
Global $MyGlobalFontColor = 0x000000
Global $MyGlobalFontBKColor = $GUI_BKCOLOR_TRANSPARENT
Global $MyGlobalFontHeight = 0

;GUI Indicator Colors
Global $values_match_bk_color = 0xFFFFFF
Global $values_no_match_bk_color = 0xFFDEBB

;GUI variables for selection update functions
Local $stashedGuiProfiles = _Profiles()
Global $stashedGuiProfile = _Profiles_createProfile($stashedGuiProfiles, "stashedGuiProfile")
Global $blockApplyButtonColorUpdate
Global $lastHoverWasProfile = False
Global $firstScan = True

; GUI listview color control variables
GLobal $fCursorInListView 
Global $iLVx
Global $iLVy
Global $iLVw
Global $iLVh
Global $hLV
Global $iHot
Global $iHotPrev

;Statusbar
Global $statusbarHeight = 20
Global $statusChild, $RestartChild
Global $statustext, $statuserror, $sStatusMessage
Global $wgraphic, $showWarning

;Menu Items
Global $filemenu, $applyitem, $renameitem, $newitem, $saveitem, $deleteitem, $clearitem, $createLinkItem, $profilesOpenItem, $profilesImportItem, $profilesExportItem, $exititem, $netConnItem
Global $viewmenu, $refreshitem, $send2trayitem, $blacklistitem
Global $toolsmenu, $pullitem, $disableitem, $releaseitem, $renewitem, $cycleitem, $settingsitem
Global $helpmenu, $helpitem, $changelogitem, $checkUpdatesItem, $debugmenuitem, $infoitem

Global $lvcon_rename, $lvcon_delete, $lvcon_arrAz, $lvcon_arrZa, $lvcreateLinkItem
Global $lvcontext

;Settings window
Global $ck_mintoTray, $ck_startinTray, $ck_saveAdapter, $cmb_langSelect

Global $timerstart, $timervalue

Global $movetosubnet
Global $mdblTimerInit = 0, $mdblTimerDiff = 1000, $mdblClick = 0, $mDblClickTime = 500
Global $dragging = False, $dragitem = 0, $contextSelect = 0
Global $prevWinPos, $winPosTimer, $writePos
Global $OpenFileFlag, $ImportFileFlag, $ExportFileFlag

; CONTROLS
Global $combo_adapters, $combo_dummy, $selected_adapter, $lDescription, $lMac
Global $list_profiles, $input_filter, $filter_dummy, $dummyUp, $dummyDown
Global $lv_oldName, $lv_newName, $lv_editIndex, $lv_doneEditing, $lv_newItem, $lv_startEditing, $lv_editing, $lv_aboutEditing, $lvTabKey
Global $radio_IpAuto, $radio_IpMan, $ip_Ip, $ip_Subnet, $ip_Gateway, $dummyTab
Global $radio_DnsAuto, $radio_DnsMan, $ip_DnsPri, $ip_DnsAlt
Global $label_CurrentIp, $label_CurrentSubnet, $label_CurrentGateway
Global $label_CurrentDnsPri, $label_CurrentDnsAlt
Global $label_CurrentDhcp, $label_CurrentAdapterState
Global $link, $computerName, $domainName
Global $blacklistLV

Global $headingSelect, $headingProfiles, $headingIP, $headingCurrent
Global $label_CurrIp, $label_CurrSubnet, $label_CurrGateway, $label_CurrDnsPri, $label_CurrDnsAlt, $label_CurrDhcp, $label_CurrAdapterState
Global $label_DnsPri, $label_DnsAlt, $ck_dnsReg, $label_ip, $label_subnet, $label_gateway

; TOOLBAR
Global $oToolbar, $oToolbar2, $tbButtonApply, $tbButtonAddRoute
Global $updateAddRouteButtonFlag = True

; LANGUAGE VARIABLES
Global $oLangStrings

; MOUSE STATUS VARIABLES
Global $disableLeftClick = False
Global $selected_lv_index

; ASYNC COORDINATION
Global $_reserveAsync = False
Global $last_command = ""

; ASYNC HALT  VARIABLE
#EndRegion Global Variables

#include "libraries\Json\json.au3"
#include "data\adapters.au3"
#include "data\options.au3"
#include "data\profiles.au3"
#include "hexIcons.au3"
#include "languages.au3"
#include "libraries\asyncRun.au3"
#include "libraries\StringSize.au3"
#include "libraries\Toast.au3"
#include "libraries\_NetworkStatistics.au3"
#include "libraries\GuiFlatToolbar.au3"
#include "functions.au3"
#include "events.au3"
#include "network.au3"
#include "forms\_form_main.au3"
#include "forms\_form_about.au3"
#include "forms\_form_changelog.au3"
#include "forms\_form_debug.au3"
#include "forms\_form_blacklist.au3"
#include "forms\_form_settings.au3"
#include "forms\_form_update.au3"
#include "forms\_form_restart.au3"
#include "cli.au3"

#Region PROGRAM CONTROL
;create the main 'objects'
$options = _Options()
$profiles = _Profiles()
$adapters = Adapter()

;check to see if called with command line arguments
CheckCmdLine()

;create a new window message
Global $iMsg = _WinAPI_RegisterWindowMessage('newinstance_message')

;Check if already running. If running, send a message to the first
;instance to show a popup message then close this instance.
If _Singleton("RPW IP Config Tool", 1) = 0 Then
	_WinAPI_PostMessage(0xffff, $iMsg, 0x101, 0)
	Exit
EndIf


;begin main program
_main()
#EndRegion PROGRAM CONTROL

;------------------------------------------------------------------------------
; Title........: _main
; Description..: initial program setup & main running loop
;------------------------------------------------------------------------------
Func _main()
	_print("starting")
	_initLang()
	_print("init lang")
	; popuplate current adapter names and mac addresses
	;_loadAdapters()

	; get current DPI scale factor
	$dscale = _GDIPlus_GraphicsGetDPIRatio()
	$iDPI = $dscale * 96

	;get profiles list
	_loadProfiles()
	_print("load profiles")

	;get OS language OR selected language storage in profile
	$selectedLang = $options.Language
	If $selectedLang <> "" And $oLangStrings.OSLang <> $selectedLang Then
		$oLangStrings.OSLang = $selectedLang
	EndIf
	If $selectedLang = "" Then
		$options.Language = $oLangStrings.OSLang
		IniWrite($sProfileName, "options", "Language", $oLangStrings.OSLang)
	EndIf

	_setLangStrings($oLangStrings.OSLang)
	_print("set lang")

	;make the GUI
	_form_main()
	_print("make GUI")

	;get list of adapters and current IP info
	_print("load adapters")

	;watch for new program instances
	GUIRegisterMsg($iMsg, '_NewInstance')

	_updateCombo()

	_refresh(1)
	ControlListView($hgui, "", $list_profiles, "Select", 0)

	;get system double-click time
	$retval = DllCall('user32.dll', 'uint', 'GetDoubleClickTime')
	$mDblClickTime = $retval[0]

	;see if we should display the changelog
	;~ _checkChangelog()

	;get the domain
	GUICtrlSetData($domainName, _DomainComputerBelongs())

	$iHot = -1

	$counter = 1
	Local $filePath
	_print("Running")
	While 1
;~ 		If $dragging Then
;~ 			Local $aLVHit = _GUICtrlListView_HitTest(GUICtrlGetHandle($list_profiles))
;~ 			Local $iCurr_Index = $aLVHit[0]
;~ 			If $iCurr_Index >= $dragitem Then
;~ 				_GUICtrlListView_SetInsertMark($list_profiles, $iCurr_Index, True)
;~ 			Else
;~ 				_GUICtrlListView_SetInsertMark($list_profiles, $iCurr_Index, False)
;~ 			EndIf
;~ 		EndIf

		If $lv_doneEditing Then
			_onLvDoneEdit()
		EndIf

		If $lv_startEditing And Not $lv_editing Then
			_onRename()
		EndIf

		If $movetosubnet Then
			_MoveToSubnet()
		EndIf

		If $OpenFileFlag Then
			$OpenFileFlag = 0
			$filePath = FileOpenDialog($oLangStrings.dialog.selectFile, @ScriptDir, $oLangStrings.dialog.ini & " (*.ini)", $FD_FILEMUSTEXIST, "profiles.ini")
			If Not @error Then 
				$sProfileName = $filePath
				$options = _Options()
				$profiles = _Profiles()
				_refresh(1)
				_setStatus($oLangStrings.message.loadedFile & " " & $filePath, 0)
			EndIf
		EndIf

		If $ImportFileFlag Then
			$ImportFileFlag = 0
			$filePath = FileOpenDialog($oLangStrings.dialog.selectFile, @ScriptDir, $oLangStrings.dialog.ini & " (*.ini)", $FD_FILEMUSTEXIST, "profiles.ini")
			If Not @error Then
				_ImportProfiles($filePath)
				_refresh(1)
				_setStatus($oLangStrings.message.doneImporting, 0)
			EndIf
		EndIf

		If $ExportFileFlag Then
			$ExportFileFlag = 0
			$filePath = FileSaveDialog($oLangStrings.dialog.selectFile, @ScriptDir, $oLangStrings.dialog.ini & " (*.ini)", $FD_PROMPTOVERWRITE, "profiles.ini")
			If Not @error Then
				If StringRight($filePath, 4) <> ".ini" Then
					$filePath &= ".ini"
				EndIf
				FileCopy($sProfileName, $filePath, $FC_OVERWRITE)
				_setStatus($oLangStrings.message.fileSaved & ": " & $filePath, 0)
			EndIf
		EndIf

		If $lvTabKey And Not IsHWnd(_GUICtrlListView_GetEditControl(ControlGetHandle($hgui, "", $list_profiles))) Then
			$lvTabKey = False
			Send("{TAB}")
		EndIf

		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE
				Exit
		EndSwitch

		_handleHoverItemChange()
		_highlightUnsavedProfile()

		Local $selectedItemIndex = _GUICtrlListView_GetSelectedIndices($list_profiles)
		if $selectedItemIndex <> $iHot And $iHot <> -1 Then
			$blockApplyButtonColorUpdate = True
		Else
			$blockApplyButtonColorUpdate = False
		EndIf

		$counter = $counter + 1
		;~ _updateApplyButtonColor()
		Sleep(100)
		
	WEnd
EndFunc   ;==>_main

;------------------------------------------------------------------------------
; Title........: _NewInstance
; Description..: Called when a new program instance posts the message we were watching for.
;                Bring the running program instance to the foreground.
;------------------------------------------------------------------------------
Func _NewInstance($hWnd, $iMsg, $iwParam, $ilParam)
	If $iwParam == "0x00000101" Then
;~ 		TrayTip("", "Simple IP Config is already running", 1)

;~ 		$sMsg  = 'Simple IP Config is already running'
;~ 		_Toast_Set(0, 0xAAAAAA, 0x000000, 0xFFFFFF, 0x000000, 10, "", 250, 250)
;~ 		$aRet = _Toast_Show(0, "Simple IP Config", $sMsg, -5, False) ; Delay can be set here because script continues

		_maximize()
	EndIf
EndFunc   ;==>_NewInstance


Func _setProfilesIniLocation()
	Local $isPortable = True

	;if profiles.ini exists in the exe directory, always choose that first, otherwise check for install
	If FileExists(@ScriptDir & "\profiles.ini") Then
		$isPortable = True
	Else
		;get install path and check if running from installed or other directory
		Local $sDisplayName
		;~ Local $InstallPath = _GetInstalledPath("Simple IP Config", $sDisplayName)

		If @error Then
			;program is not installed
			$isPortable = True
		Else
			;program is installed, check if running from install directory
			Local $scriptPath = @ScriptDir
			If StringRight(@ScriptDir, 1) <> "\" Then
				$scriptPath &= "\"
			EndIf

			;~ If $InstallPath = $scriptPath Then
			;~ 	$isPortable = False
			;~ Else
				$isPortable = True
			;~ EndIf
		EndIf
	EndIf

	If $isPortable Then
		$sProfileName = @ScriptDir & "\profiles.ini"
	Else
		If Not FileExists(@LocalAppDataDir & "\RPW IP Config") Then
			DirCreate(@LocalAppDataDir & "\RPW IP Config")
		EndIf
		$sProfileName = @LocalAppDataDir & "\RPW IP Config\profiles.ini"
	EndIf
EndFunc
