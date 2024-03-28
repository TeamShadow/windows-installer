!include LogicLib.nsh
!include Sections.nsh
!include x64.nsh

!define SHADOW_VERSION "0.8.5.0"
!define MIN_JAVA_VERSION 17
!define LLVM_INSTALLER "LLVM-18.1.2-win64.exe"
!define LLVM_VERSION 18
!define LLVM_FULL_VERSION "18.1.2"

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


; The name of the installer
Name "Shadow"

; The file to write
OutFile "shadow-installer.exe"

; Request application privileges for Windows Vista
RequestExecutionLevel admin

; Build Unicode installer
Unicode True

; The default installation directory
InstallDir $PROGRAMFILES\Shadow

; Registry key to check for directory (so if you install again, it will 
; overwrite the old one automatically)
InstallDirRegKey HKLM "Software\Shadow" "Install_Dir"

LoadLanguageFile "${NSISDIR}\Contrib\Language files\English.nlf"
;--------------------------------
;Version Information

  VIProductVersion ${SHADOW_VERSION}
  VIAddVersionKey /LANG=${LANG_ENGLISH} "ProductName" "Shadow Compiler"
  VIAddVersionKey /LANG=${LANG_ENGLISH} "Comments" "Licensed under the Apache License, Version 2.0; you may not use this file except in compliance with the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0"
  VIAddVersionKey /LANG=${LANG_ENGLISH} "CompanyName" "Team Shadow"
  VIAddVersionKey /LANG=${LANG_ENGLISH} "LegalCopyright" "Copyright 2024 Team Shadow"
  VIAddVersionKey /LANG=${LANG_ENGLISH} "FileDescription" "Shadow Compiler"
  VIAddVersionKey /LANG=${LANG_ENGLISH} "FileVersion" ${SHADOW_VERSION}

;--------------------------------

;--------------------------------

; Pages

Page components
Page directory
Page instfiles

UninstPage uninstConfirm
UninstPage instfiles

!macro removeLLVM UN
Function ${UN}removeLLVM
  Pop $2
  ReadRegStr $0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\LLVM" "UninstallString"
  StrLen $1 $0
  ${If} $1 > 0
    MessageBox MB_YESNO "Do you want to uninstall the $2 toolchain?" IDYES remove IDNO doNotRemove    
  ${Else}
    Return
  ${EndIf}
remove:
  ExecWait $0
  Return
doNotRemove:
  Return
FunctionEnd
!macroend
!insertmacro removeLLVM "" 
!insertmacro removeLLVM "un."


;--------------------------------
Section "LLVM ${LLVM_FULL_VERSION} Toolchain" LLVM_FLAG
  InitPluginsDir
  Push "existing LLVM"
  Call removeLLVM
  ;File /oname=$PLUGINSDIR\${LLVM_INSTALLER} ${LLVM_INSTALLER}
  ;ExecWait '"$PLUGINSDIR\${LLVM_INSTALLER}"' $0
  ;${If} $0 = 0 ; successful install    
  ;  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Shadow" "LLVMInstalled" 1    
  ;${EndIf}
SectionEnd

Section "VS Build Tools"
  SectionIn RO
  InitPluginsDir
  
  File /oname=$PLUGINSDIR\vs_BuildTools.exe vs_BuildTools.exe
  ExecWait '"$PLUGINSDIR\vs_BuildTools.exe"'  
SectionEnd

Section "Shadow ${SHADOW_VERSION}"

  SectionIn RO
  
  ; Set output path to the installation directory.
  SetOutPath $INSTDIR
  
  ; Put files there
  File "shadow.jar"
  File "shadowc.cmd"
  File "shadox.cmd"
  File "shadow.json"
  File "LICENSE.txt"
  File "PathEd.exe"

  ;File /nonfatal /a /r "docs\" # Documentation
  ;File /nonfatal /a /r "include\" # C headers
  ;File /nonfatal /a /r "src\" # Standard library source
  
  
  ; Write the installation path into the registry
  WriteRegStr HKLM SOFTWARE\Shadow "Install_Dir" "$INSTDIR"
  
  ; Write the uninstall keys for Windows
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Shadow" "DisplayName" "Shadow"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Shadow" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Shadow" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Shadow" "NoRepair" 1
  WriteUninstaller "$INSTDIR\uninstall.exe"

  ; Add Shadow to path
  ExecWait '".\PathEd.exe" add "$INSTDIR\bin"'
SectionEnd

; Optional section (can be disabled by the user)
Section "Start Menu Shortcuts"

  CreateDirectory "$SMPROGRAMS\Shadow"
  CreateShortcut "$SMPROGRAMS\Shadow\Uninstall.lnk" "$INSTDIR\uninstall.exe"  

SectionEnd

;--------------------------------

; Uninstaller

Section "Uninstall"
  ; Remove LLVM if installed by Shadow installer
  ReadRegDWORD $0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Shadow" "LLVMInstalled"
  ${If} $0 = 1
    Push "LLVM"
    Call un.removeLLVM
  ${EndIf}

  ; Remove Shadow path  
  ExecWait '".\PathEd.exe" remove "$INSTDIR\bin"'
  
  ; Remove registry keys
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Shadow"
  DeleteRegKey HKLM SOFTWARE\Shadow

  ; Remove files and uninstaller
  Delete "$INSTDIR\shadow.jar"
  Delete "$INSTDIR\shadowc.cmd"
  Delete "$INSTDIR\shadox.cmd"
  Delete "$INSTDIR\shadow.json"
  Delete "$INSTDIR\LICENSE.txt"
  Delete "$INSTDIR\uninstall.exe"

  RMDir /r "$INSTDIR\docs"
  RMDir /r "$INSTDIR\include"
  RMDir /r "$INSTDIR\src"
    
  ; Remove shortcuts, if any
  Delete "$SMPROGRAMS\Shadow\*.lnk"

  ; Remove directories
  RMDir "$SMPROGRAMS\Shadow"
  RMDir "$INSTDIR"
SectionEnd


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
	nsExec::ExecToStack  'cmd /c "java -version"'
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
	Quit
missingJava:
    MessageBox MB_OK "No Java run-time environment found.$\n$\nNote that the location of java.exe must be added to the PATH environment variable for the Shadow compiler to function."
	Quit
done:
FunctionEnd

Function checkLLVMVersion
	nsExec::ExecToStack  'cmd /c "clang --version"'
  Pop $0 ; not equal to 0 if failed
	IntCmp $0 0 foundLLVM missingLLVM missingLLVM
foundLLVM:    
	Pop $0 ; version
	${Explode}  $1  ' ' $0 ; separates based on space
	Pop $0 ; should contain 'clang'
	Pop $0 ; should contain 'version'
  Pop $0 ; should contain actual version (e.g. '16.0.0')
	${Explode}  $1  "." $0 ; separates based on .
	Pop $0 ; should contain major version (e.g. 16)
	IntCmp $0 ${LLVM_VERSION} suggestInstallLLVM allowInstallLLVM doNotInstallLLVM
suggestInstallLLVM:
  !insertmacro UnselectSection ${LLVM_FLAG}
  Return
allowInstallLLVM:  
  !insertmacro SelectSection ${LLVM_FLAG}
  Return
doNotInstallLLVM:  
  !insertmacro UnselectSection ${LLVM_FLAG}
  !insertmacro SetSectionFlag ${LLVM_FLAG} ${SF_RO}
  Return
missingLLVM:  
  !insertmacro SetSectionFlag ${LLVM_FLAG} ${SF_RO}
  Return
FunctionEnd

Function .onInit
   Call checkJavaVersion
   Call checkLLVMVersion
FunctionEnd

