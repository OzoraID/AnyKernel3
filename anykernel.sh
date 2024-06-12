# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
kernel.string=
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=beryllium
device.name2=PocoF1
device.name3=PocophoneF1
device.name4=
device.name5=
device.name6=
device.name7=
device.name8=
supported.versions=
supported.patchlevels=
'; } # end properties

# shell variables
block=/dev/block/bootdevice/by-name/boot;
is_slot_device=0;
ramdisk_compression=auto;
patch_vbmeta_flag=auto;


## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. tools/ak3-core.sh;


## AnyKernel file attributes
# set permissions/ownership for included ramdisk files
set_perm_recursive 0 0 755 644 $ramdisk/*;
set_perm_recursive 0 0 750 750 $ramdisk/init* $ramdisk/sbin;


## AnyKernel boot install
dump_boot;

# begin ramdisk changes

# Import Remover
. /tmp/anykernel/tools/remover.sh;

# Clear
  ui_print "1";
  sleep 1
  ui_print "2";
  sleep 1
  ui_print "3";
  ui_print "x-----------------------------------------------x";

# Keycheck
INSTALLER=$(pwd)
KEYCHECK=$INSTALLER/tools/keycheck
chmod 755 $KEYCHECK

keytest() {
    (/system/bin/getevent -lc 1 2>&1 | /system/bin/grep VOLUME | /system/bin/grep " DOWN" > $INSTALLER/events) || return 1
    return 0
}

choose() {
    # note from chainfire @xda-developers: getevent behaves weird when piped, and busybox grep likes that even less than toolbox/toybox grep
    while true; do
        /system/bin/getevent -lc 1 2>&1 | /system/bin/grep VOLUME | /system/bin/grep " DOWN" > $INSTALLER/events
        if (`cat $INSTALLER/events 2>/dev/null | /system/bin/grep VOLUME >/dev/null`); then
            break
        fi
    done

    if (`cat $INSTALLER/events 2>/dev/null | /system/bin/grep VOLUMEUP >/dev/null`); then
        return 0
    else
        return 1
    fi
}

chooseportold() {
  # Calling it first time detects previous input. Calling it second time will do what we want
  $bin/keycheck
  $bin/keycheck
  SEL=$?
  if [ "$1" == "UP" ]; then
    UP=$SEL
  elif [ "$1" == "DOWN" ]; then
    DOWN=$SEL
  elif [ $SEL -eq $UP ]; then
    return 0
  elif [ $SEL -eq $DOWN ]; then
    return 1
  else
    abort "Vol key not detected!!!"
  fi
}

if keytest; then
  FUNCTION=chooseport
else
  FUNCTION=chooseportold
  ui_print "Press Vol Up Again..."
  ui_print " "
  $FUNCTION "UP"
  ui_print "Press Vol Down..."
  $FUNCTION "DOWN"
fi

abort_main(){
  ui_print " "
	ui_print "Image not found"
	ui_print "Aborting install kernel :"
  ui_print " "
	abort;
}

# Install Kernel

# Clear
  ui_print "x-----------------------------------------------x";
  ui_print "1";
  sleep 1
  ui_print "2";
  sleep 1
  ui_print "3";
  ui_print "x-----------------------------------------------x";
  sleep 1

kernel_image=$home/kernel/
if [[ -f $kernel_image/NSE/Image.gz-dtb ]] || [[ -f $kernel_image/SE/Image.gz-dtb ]]; then
	ui_print "Choose Kernel Version.. "
	ui_print "x-----------------------------------------------x"
  sleep 1
	ui_print "NSE ( No System Ext )"
  sleep 1
        ui_print "SE ( System Ext ) "
	ui_print "x-----------------------------------------------x"
  sleep 1
	ui_print "1. NSE : a9-a11"
  ui_print " "
  sleep 1
	ui_print "2. SE : a12-a14"
  sleep 1
	ui_print "x-----------------------------------------------x"
	ui_print " Vol+ = NSE, Vol- = SE "
	ui_print "x-----------------------------------------------x"
  sleep 1
	ui_print "1. NSE Version "
  ui_print " "
  sleep 1
	ui_print "2. SE Version "
	ui_print "x-----------------------------------------------x"
  sleep 2
  ui_print " "

	if $FUNCTION; then
  ui_print "-> Kernel NSE selected.."
  ui_print "-> Wait... "
  sleep 2
  ui_print "-> Kernel NSE Installed"
	if [[ -f $kernel_image/NSE/Image.gz-dtb ]]; then
	cp $kernel_image/NSE/Image.gz-dtb $home/Image.gz-dtb
		else
			abort_main;
		fi;
	else
  ui_print "-> Kernel SE selected.."
  ui_print "-> Wait... "
  sleep 2
  ui_print "-> Kernel SE Installed "
	if [[ -f $kernel_image/SE/Image.gz-dtb ]]; then
	cp $kernel_image/SE/Image.gz-dtb $home/Image.gz-dtb
		else
			abort_main;
		fi;
	fi

  ui_print " "
  ui_print "-> Installing KURUMI Kernel "
	ui_print "-> Enjoy... "
else
	abort_main;
fi;

# Selinux Permissive
#patch_cmdline androidboot.selinux androidboot.selinux=permissive

# migrate from /overlay to /overlay.d to enable SAR Magisk
if [ -d $ramdisk/overlay ]; then
  rm -rf $ramdisk/overlay;
fi;

# end ramdisk changes

write_boot;
## end boot install
