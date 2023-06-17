# Hashcat's Portable Workspace [![Tester](https://github.com/hashcat26/workspace/actions/workflows/tester.yml/badge.svg)](https://github.com/hashcat26/workspace/actions/workflows/tester.yml)
Workspace setup written in [PowerShell](https://www.powershellgallery.com), a Windows command-line shell and scripting language.

Getting this repository:
---------------------------------
To get this repository, run `curl -kLo hashcat.zip https://github.com/hashcat26/workspace/archive/refs/heads/master.zip`.

Extracting and cleanup:
---------------------------------
To extract the files and perform cleanup, run `tar -xf hashcat.zip & del hashcat.zip & robocopy /move /s workspace-master .`.

Running the setup:
---------------------------------
To proceed with the portable workspace setup, do `powershell ./setup.ps1`.
