#!/bin/sh -e
# Copyright (c) 2024 Roger Brown.
# Licensed under the MIT License.

VERSION=8.0.8
SDKVERSION=8.0.108
VERS=8.0
URL="https://github.com/sec/dotnet-core-freebsd-source-build/releases/download/$SDKVERSION-vmr"
ROOTDIR=usr/share/dotnet
RIDARCH=$(uname -p)
MAINTAINER=rhubarb-geek-nz@users.sourceforge.net

rm -f *.plist *.manifest *.pkg

case "$RIDARCH" in
	amd64 )
		RIDARCH=x64
		;;
	aarch64 )
		RIDARCH=arm64
		;;
	* )
		;;
esac

RID="freebsd-$RIDARCH"

for d in \
	dotnet-sdk-$SDKVERSION-$RID.tar.gz
do
	if test ! -f $d
	then
		if curl --location --fail --silent "$URL/$d" --output "$d"
		then
			ls -ld "$d"
		else
			rm "$d"
			false
		fi
	fi
done

for d in \
	"dotnet-runtime-$VERS" \
	"dotnet-hostfxr-$VERS" \
	"dotnet-host" \
	"aspnetcore-runtime-$VERS" \
	"aspnetcore-targeting-pack-$VERS" \
	"dotnet-targeting-pack-$VERS" \
	"dotnet-apphost-pack-$VERS" \
	"netstandard-targeting-pack-2.1" \
	"dotnet-sdk-$VERS"
do
	if test -d "$d"
	then
		chmod -R +w "$d"
		rm -rf "$d"
	fi
	mkdir -p "$d/$ROOTDIR"
done

mkdir -p "dotnet-runtime-deps-$VERS"

(
	set -e
	cd "dotnet-host/$ROOTDIR"
	tar xfz -
	find * -type f -name "lib*.so" | xargs chmod -x
) < "dotnet-sdk-$SDKVERSION-$RID.tar.gz"

mkdir \
	"aspnetcore-runtime-$VERS/$ROOTDIR/shared" \
	"netstandard-targeting-pack-2.1/$ROOTDIR/packs" \
	"dotnet-targeting-pack-$VERS/$ROOTDIR/packs" \
	"aspnetcore-targeting-pack-$VERS/$ROOTDIR/packs" \
	"dotnet-sdk-$VERS/$ROOTDIR/packs"

while read WHAT SRC DEST
do
	echo "$SRC/$ROOTDIR/$WHAT" "->" "$DEST/$ROOTDIR/$WHAT"
	mv "$SRC/$ROOTDIR/$WHAT" "$DEST/$ROOTDIR/$WHAT"
done <<EOF
host dotnet-host dotnet-hostfxr-$VERS
shared dotnet-host dotnet-runtime-$VERS
packs dotnet-host dotnet-apphost-pack-$VERS
shared/Microsoft.AspNetCore.App dotnet-runtime-$VERS aspnetcore-runtime-$VERS
sdk dotnet-host dotnet-sdk-$VERS
sdk-manifests dotnet-host dotnet-sdk-$VERS
templates dotnet-host dotnet-sdk-$VERS
packs/NETStandard.Library.Ref dotnet-apphost-pack-$VERS netstandard-targeting-pack-2.1
packs/Microsoft.NETCore.App.Ref dotnet-apphost-pack-$VERS dotnet-targeting-pack-$VERS
packs/Microsoft.AspNetCore.App.Ref dotnet-apphost-pack-$VERS aspnetcore-targeting-pack-$VERS
packs/Microsoft.NETCore.App.Runtime.$RID dotnet-apphost-pack-$VERS dotnet-sdk-$VERS
packs/Microsoft.AspNetCore.App.Runtime.$RID dotnet-apphost-pack-$VERS dotnet-sdk-$VERS
EOF

for d in metadata
do
	rm -rf "dotnet-host/$ROOTDIR/$d"
done
mkdir -p dotnet-host/usr/bin
ln -s /$ROOTDIR/dotnet dotnet-host/usr/bin/dotnet

(
	cat << EOF
name dotnet-runtime-deps-$VERS
version $VERSION
comment dotnet-runtime-deps-freebsd $VERSION
www https://github.com/dotnet/core
origin dotnet/dotnet-runtime-deps-$VERS
desc: <<EOD
.NET is a development platform that you can use to build command-line applications, microservices and modern websites. It is open source, cross-platform and is supported by Microsoft. We hope you enjoy using it! If you do, please consider joining the active community of developers that are contributing to the project on GitHub (https://github.com/dotnet/core). We happily accept issues and PRs.
EOD
maintainer $MAINTAINER
prefix /
licenses: [
    "MIT"
]
categories: [
    "dotnet"
]
EOF
	echo "deps: {"
	for d in libinotify openssl icu
	do
		ORIGIN=$(pkg info -q --origin $d)
		VERS=$(pkg info $d | grep Version | while read A B C D; do echo $C; break; done | sed "y/,/ /" | while read E F; do echo $E; done)
		if test "$d" = "icu"
		then
			echo "   $d: {origin: $ORIGIN, version: $VERS}"
		else
			echo "   $d: {origin: $ORIGIN, version: $VERS},"
		fi
	done
	echo "}"
) > dotnet-runtime-deps-$VERS.manifest

(
	cat << EOF
name dotnet-host
version $VERSION
comment Microsoft .NET Host - $VERSION
www https://github.com/dotnet/core
origin dotnet/dotnet-host
desc: <<EOD
.NET is a development platform that you can use to build command-line applications, microservices and modern websites. It is open source, cross-platform and is supported by Microsoft. We hope you enjoy using it! If you do, please consider joining the active community of developers that are contributing to the project on GitHub (https://github.com/dotnet/core). We happily accept issues and PRs.
EOD
maintainer $MAINTAINER
prefix /
licenses: [
    "MIT"
]
categories: [
    "dotnet"
]
EOF
) > dotnet-host.manifest

(
	cat << EOF
name dotnet-hostfxr-$VERS
version $VERSION
comment Microsoft .NET Host FX Resolver - $VERSION
www https://github.com/dotnet/core
origin dotnet/dotnet-hostfxr-$VERS
desc: <<EOD
.NET is a development platform that you can use to build command-line applications, microservices and modern websites. It is open source, cross-platform and is supported by Microsoft. We hope you enjoy using it! If you do, please consider joining the active community of developers that are contributing to the project on GitHub (https://github.com/dotnet/core). We happily accept issues and PRs.
EOD
maintainer $MAINTAINER
prefix /
licenses: [
    "MIT"
]
categories: [
    "dotnet"
]
EOF
	echo "deps: {"
	echo "   dotnet-host: {origin: dotnet/dotnet-host, version: $VERSION}"
	echo "}"
) > dotnet-hostfxr-$VERS.manifest

(
	cat << EOF
name dotnet-runtime-$VERS
version $VERSION
comment Microsoft.NETCore.App.Runtime $VERSION
www https://github.com/dotnet/core
origin dotnet/dotnet-runtime-$VERS
desc: <<EOD
.NET is a development platform that you can use to build command-line applications, microservices and modern websites. It is open source, cross-platform and is supported by Microsoft. We hope you enjoy using it! If you do, please consider joining the active community of developers that are contributing to the project on GitHub (https://github.com/dotnet/core). We happily accept issues and PRs.
EOD
maintainer $MAINTAINER
prefix /
licenses: [
    "MIT"
]
categories: [
    "dotnet"
]
EOF
	echo "deps: {"
	echo "   dotnet-hostfxr-$VERS: {origin: dotnet/dotnet-hostfxr-$VERS, version: $VERSION}",
	echo "   dotnet-runtime-deps-$VERS: {origin: dotnet/dotnet-runtime-deps-$VERS, version: $VERSION}"
	echo "}"
) > dotnet-runtime-$VERS.manifest

(
	cat << EOF
name aspnetcore-runtime-$VERS
version $VERSION
comment Microsoft.AspNetCore.App $VERSION
www https://github.com/dotnet/core
origin dotnet/aspnetcore-runtime-$VERS
desc: <<EOD
Shared Framework for hosting of Microsoft ASP.NET Core applications. It is open source, cross-platform and is supported by Microsoft. We hope you enjoy using it! If you do, please consider joining the active community of developers that are contributing to the project on GitHub (https://github.com/dotnet/aspnetcore). We happily accept issues and PRs.
EOD
maintainer $MAINTAINER
prefix /
licenses: [
    "MIT"
]
categories: [
    "dotnet"
]
EOF
	echo "deps: {"
	echo "   dotnet-runtime-$VERS: {origin: dotnet/dotnet-runtime-$VERS, version: $VERSION}"
	echo "}"
) > aspnetcore-runtime-$VERS.manifest

(
	cat << EOF
name netstandard-targeting-pack-2.1
version 2.1.0
comment NETStandard.Library.Ref 2.1.0
www https://github.com/dotnet/core
origin dotnet/netstandard-targeting-pack-2.1
desc: <<EOD
.NET Core is a development platform that you can use to build command-line applications, microservices and modern websites. It is open source, cross-platform and is supported by Microsoft. We hope you enjoy using it! If you do, please consider joining the active community of developers that are contributing to the project on GitHub (https://github.com/dotnet/core). We happily accept issues and PRs.
EOD
maintainer $MAINTAINER
prefix /
licenses: [
    "MIT"
]
categories: [
    "dotnet"
]
EOF
) > netstandard-targeting-pack-2.1.manifest

(
	cat << EOF
name aspnetcore-targeting-pack-$VERS
version $VERSION
comment Microsoft.AspNetCore.App.Ref $VERSION
www https://github.com/dotnet/core
origin dotnet/aspnetcore-targeting-pack-$VERS
desc: <<EOD
Shared Framework for hosting of Microsoft ASP.NET Core applications. It is open source, cross-platform and is supported by Microsoft. We hope you enjoy using it! If you do, please consider joining the active community of developers that are contributing to the project on GitHub (https://github.com/dotnet/aspnetcore). We happily accept issues and PRs.
EOD
maintainer $MAINTAINER
prefix /
licenses: [
    "MIT"
]
categories: [
    "dotnet"
]
EOF
	echo "deps: {"
	echo "   dotnet-targeting-pack-$VERS: {origin: dotnet/dotnet-targeting-pack-$VERS, version: $VERSION}"
	echo "}"
) > aspnetcore-targeting-pack-$VERS.manifest

(
	cat << EOF
name dotnet-targeting-pack-$VERS
version $VERSION
comment Microsoft.NETCore.App.Ref $VERSION
www https://github.com/dotnet/core
origin dotnet/dotnet-targeting-pack-$VERS
desc: <<EOD
 .NET is a development platform that you can use to build command-line applications, microservices and modern websites. It is open source, cross-platform and is supported by Microsoft. We hope you enjoy using it! If you do, please consider joining the active community of developers that are contributing to the project on GitHub (https://github.com/dotnet/core). We happily accept issues and PRs.
EOD
maintainer $MAINTAINER
prefix /
licenses: [
    "MIT"
]
categories: [
    "dotnet"
]
EOF
) > dotnet-targeting-pack-$VERS.manifest

(
	cat << EOF
name dotnet-apphost-pack-$VERS
version $VERSION
comment Microsoft.NETCore.App.Host $VERSION
www https://github.com/dotnet/core
origin dotnet/dotnet-apphost-pack-$VERS
desc: <<EOD
 .NET is a development platform that you can use to build command-line applications, microservices and modern websites. It is open source, cross-platform and is supported by Microsoft. We hope you enjoy using it! If you do, please consider joining the active community of developers that are contributing to the project on GitHub (https://github.com/dotnet/core). We happily accept issues and PRs.
EOD
maintainer $MAINTAINER
prefix /
licenses: [
    "MIT"
]
categories: [
    "dotnet"
]
EOF
	echo "deps: {"
	for d in krb5
	do
		ORIGIN=$(pkg info -q --origin $d)
		VERS=$(pkg info $d | grep Version | while read A B C D; do echo $C; break; done | sed "y/,/ /" | while read E F; do echo $E; done)
		if test "$d" = "krb5"
		then
			echo "   $d: {origin: $ORIGIN, version: $VERS}"
		else
			echo "   $d: {origin: $ORIGIN, version: $VERS},"
		fi
	done
	echo "}"
) > dotnet-apphost-pack-$VERS.manifest

(
	cat << EOF
name dotnet-sdk-$VERS
version $SDKVERSION
comment Microsoft .NET SDK $SDKVERSION
www https://github.com/dotnet/core
origin dotnet/dotnet-sdk-$VERS
desc: <<EOD
 .NET is a development platform that you can use to build command-line applications, microservices and modern websites. It is open source, cross-platform and is supported by Microsoft. We hope you enjoy using it! If you do, please consider joining the active community of developers that are contributing to the project on GitHub (https://github.com/dotnet/core). We happily accept issues and PRs.
EOD
maintainer $MAINTAINER
prefix /
licenses: [
    "MIT"
]
categories: [
    "dotnet"
]
EOF
	echo "deps: {"
	echo "   dotnet-runtime-$VERS: {origin: dotnet/dotnet-runtime-$VERS, version: $VERSION},"
	echo "   aspnetcore-runtime-$VERS: {origin: aspnetcore/dotnet-runtime-$VERS, version: $VERSION},"
	echo "   netstandard-targeting-pack-2.1: {origin: netstandard/dotnet-targeting-pack-2.1, version: 2.1.0},"
	echo "   dotnet-apphost-pack-$VERS: {origin: dotnet/dotnet-apphost-pack-$VERS, version: $VERSION},"
	echo "   dotnet-targeting-pack-$VERS: {origin: dotnet/dotnet-targeting-pack-$VERS, version: $VERSION},"
	echo "   aspnetcore-targeting-pack-$VERS: {origin: aspnetcore/dotnet-targeting-pack-$VERS, version: $VERSION}"
	echo "}"
) > dotnet-sdk-$VERS.manifest

for d in \
	aspnetcore-runtime-$VERS \
	aspnetcore-targeting-pack-$VERS \
	dotnet-host \
	dotnet-hostfxr-$VERS \
	dotnet-runtime-$VERS \
	dotnet-targeting-pack-$VERS \
	dotnet-apphost-pack-$VERS \
	netstandard-targeting-pack-2.1 \
	dotnet-sdk-$VERS
do
(
	cd $d
	find $ROOTDIR -type f | xargs chmod -w
	find "$ROOTDIR" -type d | while read N
	do
		echo @dir $N
	done
	find "$ROOTDIR" -type f | (
		while read N
		do
			echo "$N"
		done
	)
	find usr -type l
) > $d.plist
done

touch "dotnet-runtime-deps-$VERS.plist"

for d in *.manifest
do
	BASE=$(echo "$d" | sed "s/\.manifest//" | while read A B; do echo $A; done)
	grep "^comment " "$d" | while read A B; do echo $B; done
	pkg create -M "$d" -o . -r "$BASE" -v -p "$BASE.plist"
done
