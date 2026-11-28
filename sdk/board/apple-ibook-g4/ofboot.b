<CHRP-BOOT>
<COMPATIBLE>
MacRISC MacRISC3 MacRISC4
</COMPATIBLE>
<DESCRIPTION>
Swift Linux
</DESCRIPTION>
<BOOT-SCRIPT>
" screen" output
boot &device;:&partition;,\\zImage root=/dev/sdb3 rootwait ro console=tty0
</BOOT-SCRIPT>
</CHRP-BOOT>
