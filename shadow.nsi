; shadow.nsi
;
; This script creates an installer for the Shadow compiler for Windows. 
;
;--------------------------------


; Actions:
; Check if Java is installed with version 17 or greater
; If not, exit
; Check if LLVM is installed
; Make optional if is installed but the bundled version is the same/newer?
; Install Visual Studio stuff (vs_BuildTools.exe) see: https://stackoverflow.com/questions/62551793/how-to-automate-from-command-line-the-installation-of-a-visual-studio-build-to
; Copy files
; Add shadow bin directory to path
; Make uninstaller
; Run Shadow library build

; Build Unicode installer
Unicode True

; The name of the installer
Name "Shadow"

; The file to write
OutFile "shadow-installer.exe"


; The default installation directory
InstallDir $PROGRAMFILES64\Shadow

; Registry key to check for directory (so if you install again, it will 
; overwrite the old one automatically)
InstallDirRegKey HKLM "Software\Shadow" "Install_Dir"


; Request application privileges for Windows Vista
RequestExecutionLevel admin

!include LogicLib.nsh
!include Sections.nsh
!include x64.nsh
!include WinCore.nsh


!define SHADOW_VERSION "0.8.5.0"
!define MIN_JAVA_VERSION 17
!define JAVA_DOWNLOAD_URL "https://www.oracle.com/java/technologies/downloads/"



;--------------------------------
;Interface Settings

 
 !define MUI_ABORTWARNING
 !define MUI_UNABORTWARNING
 
  !define UMUI_PAGEBGIMAGE
  !define UMUI_UNPAGEBGIMAGE
  !define UMUI_LEFTIMAGE_BMP "Left_Shadow.bmp"

 
!include "UMUI.nsh"

 ;Pages

  !insertmacro MUI_PAGE_LICENSE "License.txt"
  !define MUI_PAGE_CUSTOMFUNCTION_LEAVE CountSDKs  
  !insertmacro MUI_PAGE_COMPONENTS   
  !insertmacro MUI_PAGE_DIRECTORY
  !insertmacro MUI_PAGE_INSTFILES
  
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES

;--------------------------------
;Languages



 !insertmacro MUI_LANGUAGE "English"



;LoadLanguageFile "${NSISDIR}\Contrib\UltraModernUI\Language files\English.nsh"
;--------------------------------
;Version Information

  VIProductVersion ${SHADOW_VERSION}
  VIAddVersionKey  "ProductName" "Shadow Compiler"
  VIAddVersionKey "Comments" "Licensed under the Apache License, Version 2.0; you may not use this file except in compliance with the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0"
  VIAddVersionKey "CompanyName" "Team Shadow"
  VIAddVersionKey  "LegalCopyright" "Copyright 2024 Team Shadow"
  VIAddVersionKey  "FileDescription" "Shadow Compiler"
  VIAddVersionKey  "FileVersion" ${SHADOW_VERSION}

;--------------------------------

;--------------------------------

; Usage:
; ${Trim} $trimmedString $originalString
 
!define Trim "!insertmacro Trim"
!define un.Trim "!insertmacro un.Trim"
 
!macro Trim ResultVar String
  Push "${String}"
  Call Trim
  Pop "${ResultVar}"
!macroend

!macro un.Trim ResultVar String
  Push "${String}"
  Call un.Trim
  Pop "${ResultVar}"
!macroend

; Trim
;   Removes leading & trailing whitespace from a string
; Usage:
;   Push 
;   Call Trim
;   Pop 
!macro TRIMMING un
Function ${un}Trim
	Exch $R1 ; Original string
	Push $R2
 
Loop:
	StrCpy $R2 "$R1" 1
	StrCmp "$R2" " " TrimLeft
	StrCmp "$R2" "$\r" TrimLeft
	StrCmp "$R2" "$\n" TrimLeft
	StrCmp "$R2" "$\t" TrimLeft
	GoTo Loop2
TrimLeft:	
	StrCpy $R1 "$R1" "" 1
	Goto Loop
 
Loop2:
	StrCpy $R2 "$R1" 1 -1
	StrCmp "$R2" " " TrimRight
	StrCmp "$R2" "$\r" TrimRight
	StrCmp "$R2" "$\n" TrimRight
	StrCmp "$R2" "$\t" TrimRight
	GoTo Done
TrimRight:	
	StrCpy $R1 "$R1" -1
	Goto Loop2
 
Done:
	Pop $R2
	Exch $R1
FunctionEnd
!macroend

!insertmacro TRIMMING ""
!insertmacro TRIMMING "un."

Var vsBuildOptions


Section "Windows SDK 10" SecSDK10
 StrCpy $vsBuildOptions "$vsBuildOptions --add Microsoft.VisualStudio.Component.Windows10SDK.20348"
 WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Shadow" "Windows10SDK" "20348"  
SectionEnd

Section "Windows SDK 11" SecSDK11
 StrCpy $vsBuildOptions "$vsBuildOptions --add Microsoft.VisualStudio.Component.Windows11SDK.22621"
 WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Shadow" "Windows11SDK" "22621"  
SectionEnd

Section "Visual Studio Build Tools for Clang" SecVisualStudio
  SectionIn RO
  InitPluginsDir 
  
  File /oname=$PLUGINSDIR\vs_BuildTools.exe vs_BuildTools.exe
  ExecWait '"$PLUGINSDIR\vs_BuildTools.exe" $vsBuildOptions'  
  
  ; Set output path to the installation directory.
  SetOutPath $INSTDIR
  File "PathEditor.jar" 

  nsExec::ExecToStack '"$PROGRAMFILES\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Llvm.Clang -property installationPath'
  Pop $0 ; 0 if success
  ${If} $0 = 0 
    Pop $0 ; path
    ${Trim} $0 $0
    StrCpy $0 "$0\VC\Tools\Llvm\x64\bin"
  ${Else}
    StrCpy $0 'C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\Llvm\x64\bin' ; likely default  
  ${EndIf}

  ; Add Clang to path
  nsExec::Exec 'java -jar PathEditor.jar add "$0"'  
SectionEnd

Section "Shadow ${SHADOW_VERSION}" SecShadow
  SectionIn RO

  SetDetailsPrint textonly
  DetailPrint "Shadow compiler, documentation, and standard library."
  SetDetailsPrint listonly
  
  SetOutPath "$INSTDIR\include"
  File /nonfatal /a /r "include\" # C headers
  SetOutPath "$INSTDIR\src"
  File /nonfatal /a /r "src\" # Standard library source
  CreateDirectory "$INSTDIR\bin"

  ; Set output path to the installation directory.
  SetOutPath $INSTDIR
    
  ; Put files there
  File "shadow.jar"
  File "shadowc.cmd"
  File "shadox.cmd"
  File "shadow.json"
  File "LICENSE.txt"  
    
  ; Write the installation path into the registry
  WriteRegStr HKLM SOFTWARE\Shadow "Install_Dir" "$INSTDIR"
  
  ; Write the uninstall keys for Windows
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Shadow" "DisplayName" "Shadow"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Shadow" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Shadow" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Shadow" "NoRepair" 1
  WriteUninstaller "$INSTDIR\uninstall.exe"

  ; Add Shadow to path
  nsExec::Exec 'java -jar "$INSTDIR\PathEditor.jar" add "$INSTDIR"'  

  ; https://stackoverflow.com/questions/38245621/nsis-refresh-environment-during-setup
  Call RefreshProcessEnvironmentPath

  ExpandEnvStrings $0 %COMSPEC%  
  ; Generate documentation
  nsExec::Exec '"$0" /c ""$INSTDIR\shadox.cmd" "$INSTDIR\src" "-d" "$INSTDIR\docs""'  
  ; Compile standard library
  nsExec::Exec '"$0" /c "cd /D "$INSTDIR" & "shadowc.cmd" "-b""'  
SectionEnd

; Optional section (can be disabled by the user)
Section "Start Menu Shortcuts" SecStartMenu

  CreateDirectory "$SMPROGRAMS\Shadow"
  CreateShortcut "$SMPROGRAMS\Shadow\Uninstall.lnk" "$INSTDIR\uninstall.exe"  

SectionEnd

;--------------------------------

; Uninstaller

Section "Uninstall"

  Var /GLOBAL vsBuildRemove
  Var /GLOBAL vsBuildPath

  nsExec::ExecToStack '"$PROGRAMFILES\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Llvm.Clang -property installationPath'
  Pop $0 ; 0 if success
  ${If} $0 = 0  
    Pop $vsBuildPath ; path
    ${un.Trim} $vsBuildPath $vsBuildPath
  ${Else}
    StrCpy $vsBuildPath 'C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools' ; likely default  
  ${EndIf}

  StrCpy $0 '$vsBuildPath\VC\Tools\Llvm\x64\bin'

  ; Remove Clang from path  
  nsExec::Exec 'java -jar "$INSTDIR\PathEditor.jar" remove "$0"'  

  ; Remove Shadow path  
  nsExec::Exec 'java -jar "$INSTDIR\PathEditor.jar" remove "$INSTDIR"'  

  MessageBox MB_YESNO "Remove Visual Studio Build Tools?" IDYES removeVSBuildTools IDNO keepVSBuildTools

removeVSBuildTools:
  ; Remove Visual Studio Build Tools
  StrCpy $vsBuildRemove "--passive --remove Microsoft.VisualStudio.Workload.VCTools --remove Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --remove Microsoft.VisualStudio.Component.VC.Llvm.Clang"

  ReadRegStr $0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Shadow" "Windows10SDK"
  ${If} $0 != ""
    StrCpy $vsBuildRemove "$vsBuildRemove --remove Microsoft.VisualStudio.Component.Windows10SDK.$0"
  ${EndIf}

  ReadRegStr $0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Shadow" "Windows11SDK"
  ${If} $0 != ""
    StrCpy $vsBuildRemove "$vsBuildRemove --remove Microsoft.VisualStudio.Component.Windows11SDK.$0"
  ${EndIf}

  ExecWait '"$PROGRAMFILES\Microsoft Visual Studio\Installer\setup.exe" modify --installPath $vsBuildPath $vsBuildRemove'
keepVSBuildTools:
  
  ; Remove registry keys
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Shadow"
  DeleteRegKey HKLM SOFTWARE\Shadow

  ; Remove files and uninstaller
  Delete "$INSTDIR\shadow.jar"
  Delete "$INSTDIR\shadowc.cmd"
  Delete "$INSTDIR\shadox.cmd"
  Delete "$INSTDIR\shadow.json"
  Delete "$INSTDIR\LICENSE.txt"
  Delete "$INSTDIR\PathEditor.jar"
  Delete "$INSTDIR\uninstall.exe"  

  RMDir /r "$INSTDIR\docs"
  RMDir /r "$INSTDIR\include"
  RMDir /r "$INSTDIR\src"
  RMDir /r "$INSTDIR\bin"
    
  ; Remove shortcuts, if any
  Delete "$SMPROGRAMS\Shadow\*.lnk"

  ; Remove directories
  RMDir "$SMPROGRAMS\Shadow"
  RMDir "$INSTDIR"
SectionEnd

;--------------------------------
;Descriptions

  ;Language strings
  LangString DESC_SecSDK10 ${LANG_ENGLISH} "Installs Windows 10 SDK, used for development of Windows native programs.$\n$\nNote that at least one Windows SDK is required for compiling any Shadow program."
  LangString DESC_SecSDK11 ${LANG_ENGLISH} "Installs Windows 11 SDK, used for development of Windows native programs.$\n$\nNote that at least one Windows SDK is required for compiling any Shadow program."
  LangString DESC_SecVisualStudio ${LANG_ENGLISH} "Installs Visual Studio Build Tools, including LLVM and Clang infrastructure used for compiling Shadow intermediate code and Visual Studio tools for linking executables."
  LangString DESC_SecShadow ${LANG_ENGLISH} "Installs core Shadow compiler and documentation tools."
  LangString DESC_SecStartMenu ${LANG_ENGLISH} "Adds Shadow and uninstall link to start menu.$\n(Optional)"

  ;Assign language strings to sections
  !insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SecSDK10} $(DESC_SecSDK10)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecSDK11} $(DESC_SecSDK11)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecVisualStudio} $(DESC_SecVisualStudio)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecShadow} $(DESC_SecShadow)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecStartMenu} $(DESC_SecStartMenu)
  !insertmacro MUI_FUNCTION_DESCRIPTION_END

Function CountSDKs
  SectionGetFlags "${SecSDK10}" $0
  IntOp $1 $0 & ${SF_SELECTED}
  SectionGetFlags "${SecSDK11}" $0
  IntOp $0 $0 & ${SF_SELECTED}
  IntOp $1 $1 + $0  
  IntCmp $1 1 doneCounting notEnough doneCounting
notEnough:
  MessageBox MB_OK|MB_ICONSTOP "You must select at least one SDK."
  Abort     ;stay at page
doneCounting:
  Return
FunctionEnd 


!define Explode "!insertmacro Explode"
 
!macro  Explode Length  Separator   String
    Push    `${Separator}`
    Push    `${String}`
    Call    Explode
    Pop     `${Length}`
!macroend
 
Function Explode
  ; Initialize variables
  Var /GLOBAL explString
  Var /GLOBAL explSeparator
  Var /GLOBAL explStrLen
  Var /GLOBAL explSepLen
  Var /GLOBAL explOffset
  Var /GLOBAL explTmp
  Var /GLOBAL explTmp2
  Var /GLOBAL explTmp3
  Var /GLOBAL explArrCount
 
  ; Get input from user
  Pop $explString
  Pop $explSeparator
 
  ; Calculates initial values
  StrLen $explStrLen $explString
  StrLen $explSepLen $explSeparator
  StrCpy $explArrCount 1
 
  ${If}   $explStrLen <= 1          ;   If we got a single character
  ${OrIf} $explSepLen > $explStrLen ;   or separator is larger than the string,
    Push    $explString             ;   then we return initial string with no change
    Push    1                       ;   and set array's length to 1
    Return
  ${EndIf}
 
  ; Set offset to the last symbol of the string
  StrCpy $explOffset $explStrLen
  IntOp  $explOffset $explOffset - 1
 
  ; Clear temp string to exclude the possibility of appearance of occasional data
  StrCpy $explTmp   ""
  StrCpy $explTmp2  ""
  StrCpy $explTmp3  ""
 
  ; Loop until the offset becomes negative
  ${Do}
    ;   If offset becomes negative, it is time to leave the function
    ${IfThen} $explOffset == -1 ${|} ${ExitDo} ${|}
 
    ;   Remove everything before and after the searched part ("TempStr")
    StrCpy $explTmp $explString $explSepLen $explOffset
 
    ${If} $explTmp == $explSeparator
        ;   Calculating offset to start copy from
        IntOp   $explTmp2 $explOffset + $explSepLen ;   Offset equals to the current offset plus length of separator
        StrCpy  $explTmp3 $explString "" $explTmp2
 
        Push    $explTmp3                           ;   Throwing array item to the stack
        IntOp   $explArrCount $explArrCount + 1     ;   Increasing array's counter
 
        StrCpy  $explString $explString $explOffset 0   ;   Cutting all characters beginning with the separator entry
        StrLen  $explStrLen $explString
    ${EndIf}
 
    ${If} $explOffset = 0                       ;   If the beginning of the line met and there is no separator,
                                                ;   copying the rest of the string
        ${If} $explSeparator == ""              ;   Fix for the empty separator
            IntOp   $explArrCount   $explArrCount - 1
        ${Else}
            Push    $explString
        ${EndIf}
    ${EndIf}
 
    IntOp   $explOffset $explOffset - 1
  ${Loop}
 
  Push $explArrCount
FunctionEnd

Function checkJavaVersion
  ExpandEnvStrings $0 %COMSPEC%
	nsExec::ExecToStack  '$0 /c "java -version"'
  Pop $0 ; not equal to 0 if failed
	IntCmp $0 0 foundJava missingJava missingJava
foundJava:    
	Pop $0 ; version
	${Explode}  $1  '"' $0 ; separates based on "
	Pop $0 ; should contain 'java version "'
	Pop $0 ; should contain actual version number (e.g. '19.0.1')
	${Explode}  $1  "." $0 ; separates based on .
	Pop $0 ; should contain major version (e.g. 19)
	IntCmp $0 1 nextDigit testVersion testVersion ; old Java was always 1.x, like 1.8 for Java 8
nextDigit:
	Pop $0
	Goto testVersion
testVersion:
	IntCmp $0 ${MIN_JAVA_VERSION} done badJavaVersion done
badJavaVersion:
	MessageBox MB_OK "Java $0 found, but Java ${MIN_JAVA_VERSION} or higher is required for Shadow."
  ExecShell open "${JAVA_DOWNLOAD_URL}"
	Quit
missingJava:
    MessageBox MB_OK "No Java run-time environment found.$\nJava ${MIN_JAVA_VERSION} or higher is required for Shadow.$\n$\nNote that the location of java.exe must be added to the PATH environment variable for the Shadow compiler to function."
    ExecShell open "${JAVA_DOWNLOAD_URL}"
	Quit
done:
FunctionEnd

!ifndef NSIS_CHAR_SIZE
    !define NSIS_CHAR_SIZE 1
    !define SYSTYP_PTR i
!else
    !define SYSTYP_PTR p
!endif
!ifndef ERROR_MORE_DATA
    !define ERROR_MORE_DATA 234
!endif

Function RegReadExpandStringAlloc
    System::Store S
    Pop $R2 ; reg value
    Pop $R3 ; reg path
    Pop $R4 ; reg hkey
    System::Alloc 1 ; mem
    StrCpy $3 0 ; size

    loop:
        System::Call 'SHLWAPI::SHGetValue(${SYSTYP_PTR}R4,tR3,tR2,i0,${SYSTYP_PTR}sr2,*ir3r3)i.r0' ; NOTE: Requires SHLWAPI 4.70 (IE 3.01+ / Win95OSR2+)
        ${If} $0 = 0
            Push $2
            Push $0
        ${Else}
            System::Free $2
            ${If} $0 = ${ERROR_MORE_DATA}
                IntOp $3 $3 + ${NSIS_CHAR_SIZE} ; Make sure there is room for SHGetValue to \0 terminate
                System::Alloc $3
                Goto loop
            ${Else}
                Push $0
            ${EndIf}
        ${EndIf}
    System::Store L
FunctionEnd

Function RefreshProcessEnvironmentPath
    System::Store S
    Push ${HKEY_CURRENT_USER}
    Push "Environment"
    Push "Path"
    Call RegReadExpandStringAlloc
    Pop $0

    ${IfThen} $0 <> 0 ${|} System::Call *(i0)${SYSTYP_PTR}.s ${|}
    Pop $1
    Push ${HKEY_LOCAL_MACHINE}
    Push "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
    Push "Path"
    Call RegReadExpandStringAlloc
    Pop $0

    ${IfThen} $0 <> 0 ${|} System::Call *(i0)${SYSTYP_PTR}.s ${|}
    Pop $2
    System::Call 'KERNEL32::lstrlen(t)(${SYSTYP_PTR}r1)i.R1'
    System::Call 'KERNEL32::lstrlen(t)(${SYSTYP_PTR}r2)i.R2'
    System::Call '*(&t$R2 "",&t$R1 "",i)${SYSTYP_PTR}.r0' ; The i is 4 bytes, enough for a ';' separator and a '\0' terminator (Unicode)
    StrCpy $3 ""

    ${If} $R1 <> 0
    ${AndIf} $R2 <> 0
        StrCpy $3 ";"
    ${EndIf}

    System::Call 'USER32::wsprintf(${SYSTYP_PTR}r0,t"%s%s%s",${SYSTYP_PTR}r2,tr3,${SYSTYP_PTR}r1)?c'
    System::Free $1
    System::Free $2
    System::Call 'KERNEL32::SetEnvironmentVariable(t"PATH",${SYSTYP_PTR}r0)'
    System::Free $0
    System::Store L
FunctionEnd


Function .onInit
  StrCpy $vsBuildOptions "--wait --passive --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.VC.Llvm.Clang"
  Call checkJavaVersion
  ReadRegStr $0 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" CurrentMajorVersionNumber
  ${If} $0 < 10
    MessageBox MB_OK "Shadow requires Windows 10 or later."
    Quit
  ${Else}
    !insertmacro SelectSection ${SecSDK10}}
    !insertmacro UnselectSection ${SecSDK11}
  ${EndIf}
FunctionEnd

