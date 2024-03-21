; shadow.nsi
;
; This script creates an installer for the Shadow compiler for Windows. 
;
;--------------------------------

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

  VIProductVersion "0.8.5"
  VIAddVersionKey /LANG=${LANG_ENGLISH} "ProductName" "Shadow Compiler"
  VIAddVersionKey /LANG=${LANG_ENGLISH} "Comments" "Licensed under the Apache License, Version 2.0; you may not use this file except in compliance with the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0"
  VIAddVersionKey /LANG=${LANG_ENGLISH} "CompanyName" "Team Shadow"
  VIAddVersionKey /LANG=${LANG_ENGLISH} "LegalCopyright" "Copyright 2024 Team Shadow"
  VIAddVersionKey /LANG=${LANG_ENGLISH} "FileDescription" "Shadow Compiler"
  VIAddVersionKey /LANG=${LANG_ENGLISH} "FileVersion" "0.8.5"

;--------------------------------

;--------------------------------

; Pages

Page components
Page directory
Page instfiles

UninstPage uninstConfirm
UninstPage instfiles

;--------------------------------

; The stuff to install
Section "Shadow Compiler (required)"

  SectionIn RO
  
  ; Set output path to the installation directory.
  SetOutPath $INSTDIR
  
  ; Put files there
  File "shadow.jar"
  File "shadowc.cmd"
  File "shadox.cmd"
  File "shadow.json"
  File "LICENSE.txt"

  File /nonfatal /a /r "docs\" # Documentation
  File /nonfatal /a /r "include\" # C headers
  File /nonfatal /a /r "src\" # Standard library source
  
  
  ; Write the installation path into the registry
  WriteRegStr HKLM SOFTWARE\Shadow "Install_Dir" "$INSTDIR"
  
  ; Write the uninstall keys for Windows
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Shadow" "DisplayName" "Shadow"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Shadow" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Shadow" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Shadow" "NoRepair" 1
  WriteUninstaller "$INSTDIR\uninstall.exe"
  
SectionEnd

; Optional section (can be disabled by the user)
Section "Start Menu Shortcuts"

  CreateDirectory "$SMPROGRAMS\Shadow"
  CreateShortcut "$SMPROGRAMS\Shadow\Uninstall.lnk" "$INSTDIR\uninstall.exe"  

SectionEnd

;--------------------------------

; Uninstaller

Section "Uninstall"
  
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

