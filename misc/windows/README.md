# Native Windows build

RemoteBox runs natively on Windows (no WSL or X server) using the MSYS2 UCRT64
builds of Perl and GTK 3.

## Setting up the build environment

From PowerShell, in the repository root (admin rights are not needed):

    powershell -ExecutionPolicy Bypass -File misc\windows\setup-msys2.ps1 [-Msys2Root C:\msys64]

This downloads and extracts MSYS2 if it is not already present, updates it,
installs GTK 3 and the Perl modules RemoteBox needs. The Perl GTK bindings are
not packaged by MSYS2, so they are built from CPAN. The script is safe to re-run.

Then run RemoteBox from the source tree:

    misc\windows\remotebox-dev.cmd

To run Perl directly instead, `C:\msys64\ucrt64\bin` must come **first** in
`PATH`. Perl does not search its own directory for the DLLs that XS modules
such as Glib and Cairo depend on, and older copies of shared DLLs from other
toolchains (Strawberry Perl, TDM-GCC, ...) elsewhere on `PATH` break loading:

    set PATH=C:\msys64\ucrt64\bin;%PATH%
    perl remotebox

## Files

| File | Purpose |
|---|---|
| `setup-msys2.ps1` | Installs/updates MSYS2, then runs `setup-deps.sh` |
| `setup-deps.sh` | Installs packages and builds Perl modules inside UCRT64 |
| `remotebox-dev.cmd` | Runs RemoteBox from the source tree with the right `PATH` |
| `perl5/Msys2ImportLibs.pm` | Build-time fix so XS modules link against GLib's DLL import libraries rather than the static archives |
| `patches/Cairo-1.109-msys2.patch` | Win64 and cairo 1.18 fixes for the Perl Cairo bindings |
