# Linux 7.0-series patches

Fixes that belong to the kernel series rather than to the SM8250 devices, so
they are kept in their own BR2_GLOBAL_PATCH_DIR entry and applied after the
device set - the order upstream uses.

`0010-msm-resource-cleanup.patch` releases the DPU topology when a resource
reservation fails, so a partial reservation cannot wedge every later atomic
commit. It touches `disp/dpu1/` only, which no patch in `../patches/linux/`
does, so the two sets are independent.

Source and the rest of the series (including the two patches deliberately not
imported): see ../patches/README.md.
