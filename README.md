# windows-installer
Shadow installer for Windows

Prerequisites:
- Install NSIS 3 (https://nsis.sourceforge.io/Download)
- Install Ultra-Modern UI plugin (https://nsis.sourceforge.io/Ultra-Modern_UI)

To build the installer:
- Build the version of `shadow.jar` you want to install
- Clone the `windows-installer` repository
- Copy `shadow.jar` into the repository directory
- Copy the `include` directory with the appropriate version Shadow C include files into the repository directory
- Create a `src` directory in the repository directory
- Copy the `shadow` directory and required `.ll` files from the compiler `src` directory into the repository's `src` directory
- Delete the `test` directory from inside the `shadow` directory (since it will cause errors when the compiler later tries to build the standard library)
- Use NSIS to compile the `shadow.nsi` script

