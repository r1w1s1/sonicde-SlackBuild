# SonicDE SlackBuild for Slackware

SonicDE provides selected KDE/Plasma replacement packages for Slackware-current.
It is not currently a standalone desktop package set. Keep the Slackware KDE
packages that SonicDE does not replace.

## Requirements

Use an up-to-date Slackware-current system with KDE installed. The main
Slackware `polkit` package is also required:

```sh
slackpkg install kde
slackpkg install polkit
```

Do not remove KDE packages before installing SonicDE. Some SonicDE packages
replace KDE packages, while others continue to use KDE, Qt6, Plasma, and
integration packages from Slackware.

## Download

The public SonicDE package area is:

<https://slackware.nl/people/r1w1s1/>

To download the complete release, install `lftp` and run:

```sh
mkdir -p sonicde-release
lftp -c "open https://slackware.nl; mirror --verbose --continue --parallel=4 /people/r1w1s1/ sonicde-release"
```

The `mirror` command downloads the directory contents; `--continue` allows an
interrupted download to resume. The release currently supports manual package
installation. `slackpkg+` metadata such as `PACKAGES.TXT` will be added later.

Verify the downloaded release before installing it:

```sh
cd sonicde-release
gpg --import GPG-KEY
gpg --verify CHECKSUMS.md5.asc CHECKSUMS.md5
md5sum --check CHECKSUMS.md5
```

## Build and install

```sh
cd sonicde
./sonicde_checkout.sh -c -f sonic
UPGRADE=yes SKIPBUILT=no EXITFAIL=yes ./sonicde.SlackBuild sonic
```

With `UPGRADE=yes`, packages listed in `package-renames` replace their matching
KDE/Plasma packages automatically. Do not install replacement packages beside
their original packages with plain `installpkg`.

After installation, restart the graphical session and validate the result:

```sh
./sonicde_validate_install.sh
./sonicde_remove_replaced.sh -n
```

Do not remove the remaining KDE set after installation. For Slackware-current
updates, update Slackware first, then rebuild and reinstall SonicDE replacements.

## Maintainers

Builds in a minimal chroot, dependency troubleshooting, package completeness,
and distribution checks are documented in [`README.chroot`](README.chroot).

Implementation notes are in [`SONICDE-NOTES.txt`](SONICDE-NOTES.txt).
