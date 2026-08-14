### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

### AnyKernel setup
# global properties
properties() { '
kernel.string=
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=surya
device.name2=karna
device.name3=
device.name4=
device.name5=
supported.versions=11 - 16
supported.patchlevels=
supported.vendorpatchlevels=
'; } # end properties


### AnyKernel install
## boot files attributes
boot_attributes() {
set_perm_recursive 0 0 755 644 $ramdisk/*;
set_perm_recursive 0 0 750 750 $ramdisk/init* $ramdisk/sbin;
} # end attributes

# begin build.prop loader
load_build_props() {
    if [ ! -f "/system/build.prop" ] && [ ! -f "/system_root/system/build.prop" ]; then
        mount /system 2>/dev/null || mount /system_root 2>/dev/null
    fi

    if [ -f "/system/build.prop" ]; then
        SYSTEM_BUILD_PROP="/system/build.prop"
    elif [ -f "/system_root/system/build.prop" ]; then
        SYSTEM_BUILD_PROP="/system_root/system/build.prop"
    fi

    if [ -n "$SYSTEM_BUILD_PROP" ]; then
        PROP_MIUI=$(file_getprop "$SYSTEM_BUILD_PROP" ro.miui.ui.version.code)
    fi
} # end build.prop loader

# begin legacy bootargs patch
patch_legacy_bootargs() {
    ui_print " "

    if [ -n "$PROP_MIUI" ]; then
        ui_print "MIUI $PROP_MIUI detected, defaulting to legacy bootargs"
        patch_cmdline init.is_legacy_timestamp init.is_legacy_timestamp=1
        return
    fi

    if [ "$ANDROID_VERSION" -lt 13 ]; then
        ui_print "Enabling legacy timestamp bootarg..."
        patch_cmdline init.is_legacy_timestamp init.is_legacy_timestamp=1
    else
        ui_print "Disabling legacy timestamp bootarg..."
        patch_cmdline init.is_legacy_timestamp init.is_legacy_timestamp=0
    fi
} # end legacy bootargs patch

# Android version strings
if [ -f "$AKHOME/android_ver" ]; then
    ANDROID_VERSION=$(cat "$AKHOME/android_ver")
fi

# boot shell variables
block=auto;
is_slot_device=0;
ramdisk_compression=auto;
patch_vbmeta_flag=auto;

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh;

# boot install
dump_boot; # use split_boot to skip ramdisk unpack, e.g. for devices with init_boot ramdisk

# patch legacy
load_build_props;
patch_legacy_bootargs;

# init.rc
backup_file init.rc;
replace_string init.rc "cpuctl cpu,timer_slack" "mount cgroup none /dev/cpuctl cpu" "mount cgroup none /dev/cpuctl cpu,timer_slack";

# init.tuna.rc
backup_file init.tuna.rc;
insert_line init.tuna.rc "nodiratime barrier=0" after "mount_all /fstab.tuna" "\tmount ext4 /dev/block/platform/omap/omap_hsmmc.0/by-name/userdata /data remount nosuid nodev noatime nodiratime barrier=0";
append_file init.tuna.rc "bootscript" init.tuna;

# fstab.tuna
backup_file fstab.tuna;
patch_fstab fstab.tuna /system ext4 options "noatime,barrier=1" "noatime,nodiratime,barrier=0";
patch_fstab fstab.tuna /cache ext4 options "barrier=1" "barrier=0,nomblk_io_submit";
patch_fstab fstab.tuna /data ext4 options "data=ordered" "nomblk_io_submit,data=writeback";
append_file fstab.tuna "usbdisk" fstab;

write_boot; # use flash_boot to skip ramdisk repack, e.g. for devices with init_boot ramdisk
## end boot install
