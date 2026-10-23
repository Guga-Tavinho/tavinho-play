#!/bin/sh
set -eu
here=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
cd "$here"
: "${RE510_FIRMWARE_DIR:?Defina RE510_FIRMWARE_DIR com a raiz extraida da V1.11.0}"
fw=$RE510_FIRMWARE_DIR
mkdir -p build
cc=${CC:-mipsel-linux-gnu-gcc}
if [ -n "${RE510_MIPS_TOOLCHAIN:-}" ]; then
 tc=$RE510_MIPS_TOOLCHAIN
 export LD_LIBRARY_PATH="$tc/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
 cc="$tc/usr/bin/mipsel-linux-gnu-gcc-10"
 set -- -B"$tc/usr/bin/" -B"$tc/usr/lib/gcc-cross/mipsel-linux-gnu/10/"
else
 set --
fi
"$cc" "$@" -mips32r2 -mabi=32 -mhard-float -mfp32 -fPIC -G0 -O2 \
 -Wall -Wextra -Werror -fno-builtin -nostdlib -shared \
 -Wl,--hash-style=sysv -Wl,-soname,re510time63.so -Wl,--no-as-needed \
 -L"$fw/rootfs/lib" -L"$fw/mslib" -L"$fw/mslib/ginga/lib/ginga" \
 re510time63.c native_access.c \
 -l:liblua.so -l:libipcClient.so.1.0.4 -l:libnclipcclientmanager.so \
 -l:libgingaccplayer.so -l:libc.so.6 -o build/re510time63.so \
 2>build/compilacao.log
printf 'Criado: %s/build/re510time63.so\n' "$here"
