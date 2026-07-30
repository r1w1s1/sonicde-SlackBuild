SonicDE Binary Packages
=======================

This directory contains SonicDE binary packages for Slackware-current.

Release versions
----------------

This release is based on KDE Frameworks 6.28.0 and Plasma 6.7.3. SonicDE
packages retain the upstream component version in their filenames, so the
release does not use one single version number for every package.

Supported environment
---------------------

The supported installation environment is Slackware-current with the KDE
desktop set installed. SonicDE replaces selected KDE components and is not a
complete desktop environment when installed by itself.

Installing on a system without KDE
----------------------------------

This mode is experimental. A system without KDE must already provide the
normal Slackware build/runtime base plus the required Qt6, Plasma and KDE
Frameworks libraries. The following external packages are currently known to
be required in addition to the normal base system:

  qt6
  aurorae
  polkit
  qcoro
  kpmcore
  kdsoap-ws-discovery-client
  frameworkintegration
  plasma-wayland-protocols
  systemsettings

Additional dependencies may be required as the package set evolves. Installing
only the SonicDE packages on a minimal system is not expected to produce a
working desktop.

When using KWin's default Aurorae decoration, `aurorae` must be installed.
The Breeze decoration can be selected instead when the corresponding KDE
package is installed.

Manual installation
-------------------

Import the public release key and verify the metadata before installing:

  gpg --import GPG-KEY
  gpg --verify CHECKSUMS.md5.asc CHECKSUMS.md5
  md5sum --check CHECKSUMS.md5

After verification, install the packages with Slackware's package tools. Use
`upgradepkg old%new` when replacing an installed Slackware/KDE package, and
install packages in dependency order when installing on a minimal system.

This release does not yet provide `PACKAGES.TXT`; therefore `slackpkg+`
integration is not available yet. Manual download and installation are
supported.
