hexdump -ve '1/1 "%.2x "' $out/lib/wine/x86_64-windows/explorer.exe > $out/lib/wine/x86_64-windows/explorer.exe.hex && \
    f="00 6d 00 61 00 63 00 2c 00 78 00 31 00 31 00 00 00" && \
    r="00 6e 00 75 00 6c 00 6c 00 00 00 00 00 00 00 00 00" && \
    grep -q "$f" $out/lib/wine/x86_64-windows/explorer.exe.hex && \
    sed -i "s/$f/$r/g" $out/lib/wine/x86_64-windows/explorer.exe.hex && \
    xxd -r -ps $out/lib/wine/x86_64-windows/explorer.exe.hex $out/lib/wine/x86_64-windows/explorer.exe && \
    rm $out/lib/wine/x86_64-windows/explorer.exe.hex
