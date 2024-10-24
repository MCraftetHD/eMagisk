##########################################################################################
# Config Flags
##########################################################################################

# Set to true if you do *NOT* want Magisk to mount
# any files for you. Most modules would NOT want
# to set this flag to true
SKIPMOUNT=false

# Set to true if you need to load system.prop
PROPFILE=true

# Set to true if you need post-fs-data script
POSTFSDATA=false

# Set to true if you need late_start service script
LATESTARTSERVICE=true

# Set what you want to display when installing your module

print_modname() {
    version=$(sed -n "s/^version=//p" $TMPDIR/module.prop)
    versionCode=$(sed -n "s/^versionCode=//p" $TMPDIR/module.prop)
    ui_print " _____________________________________________________"
    ui_print "|                                                     |"
    ui_print "|             >   e M a g i s k   <                   |"
    ui_print "|                                                     |"
    ui_print "|                                                     |"
    ui_print "|                         modified by Marcelyth       |"
    ui_print "|                                                     |"
    ui_print "|                                                     |"
    ui_print " _____________________________________________________"
    ui_print "|                                                     |"
    ui_print "|       Utility binaries, bash, pre-configs           |"
    ui_print "|      and services for Cosmog ATVs... all in one.    |"
    ui_print "|                vJp2                                 |"
    ui_print "|                                                     |"
    ui_print "|                                                     |"
    ui_print "|original version by emi (@emi#0001) - emi@pokemod.dev|"
    ui_print "|         Pokemod.dev  | Discord.gg/Pokemod           |"
    ui_print "|_____________________________________________________|"
    ui_print " "
}

# Copy/extract your module files into $MODPATH in on_install.
on_install() {
    # The following is the default implementation: extract $ZIPFILE/system to $MODPATH
    # Extend/change the logic to whatever you want
    ui_print "- Extracting module files"
    unzip -o "$ZIPFILE" 'system/*' -d $MODPATH >&2
    unzip -o "$ZIPFILE" 'custom/*' -d $TMPDIR >&2
    if [ -d /system/xbin ]; then
        BIN=/system/xbin
        mv $MODPATH/system/bin "$MODPATH$BIN"
    else
        BIN=/system/bin
    fi
    ui_print "- Setting BIN: $BIN."

    # Avoids issues with grepping the version code from modules.prop:
    touch $MODPATH/version_lock
    echo "$versionCode" > $MODPATH/version_lock
    ui_print "> Saved version_lock $versionCode"

    # find $MODPATH -type f | sed 's/_update//'
    # find $TMPDIR -type f | sed -e 's|/dev/tmp/||' -e 's|custom/|/sdcard/|'
    if [ -d /sdcard ]; then
        SDCARD=/sdcard
    elif [ -d /storage/emulated/0 ]; then
        SDCARD=/storage/emulated/0
    fi
    ui_print "- Setting SDCARD: $SDCARD."

    sed -i "s|<SDCARD>|$SDCARD|g" $MODPATH/system/etc/mkshrc
    sed -i "s|<BIN>|$BIN|g" $MODPATH/system/etc/mkshrc
    sed -i "s|<SDCARD>|$SDCARD|g" $TMPDIR/custom/bashrc
    sed -i "s|<SDCARD>|$SDCARD|g" $TMPDIR/custom/ATVServices.sh

    for filepath in $TMPDIR/custom/*; do
        filename=${filepath##*/}
        [ "$filename" == "ATVServices.sh" ] && continue
        # if [ -f "$SDCARD/.${filename}" ] || [ -d "$SDCARD/${filename}" ]]; then
        #     ui_print "   $SDCARD/.${filename} is already intalled! Backing up to $SDCARD/EmagiskBackups/"
        #     mkdir -p "$SDCARD/EmagiskBackups"
        #     cp -rf "$SDCARD/.${filename}" "$SDCARD/EmagiskBackups/${filename}.bak"
        # fi
        ui_print "   Copying ${filename} to $SDCARD/.${filename}"
        cp -rf "$TMPDIR/custom/${filename}" "$SDCARD/.${filename}"
    done

    ui_print " "
    ui_print " "
    ui_print "================================================"
    ui_print " >>> Installing ATV services..."
    cp -rf "$TMPDIR/custom/ATVServices.sh" "$MODPATH/ATVServices.sh"
    ui_print "================================================"
}

# Only some special files require specific permissions
# This function will be called after on_install is done
# The default permissions should be good enough for most cases

set_permissions() {
    # The following is the default rule, DO NOT remove
    set_perm_recursive $MODPATH 0 0 1755 0744

    # Here are some examples:
    set_perm_recursive $MODPATH$BIN 0 0 1755 0777
    # set_perm $MODPATH/$BIN/bash 0 0 1755  0644
    # set_perm $MODPATH/$BIN/eventrec 0 0 1755  0644
    # set_perm $MODPATH/$BIN/strace 0 0 1755  0644
    # set_perm $MODPATH/$BIN/tcpdump 0 0 1755  0644
    # set_perm $MODPATH/$BIN/nano 0 0 1755  0644
    # set_perm $MODPATH/$BIN/nano.bin 0 0 1755  0644
}

# You can add more functions to assist your custom script code
