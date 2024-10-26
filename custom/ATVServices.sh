#!/system/bin/sh

# Base stuff we need
POGOPKG=com.nianticlabs.pokemongo
MITMPKG="com.nianticlabs.pokemongo.ares"
setprop net.dns1 1.1.1.1 && setprop net.dns2 8.8.8.8

# Stops MITM and Pogo and restarts MITM MappingService
force_restart() {
    pogo_pid=$(pidof $POGOPKG)
    if [ -n "$pogo_pid" ]; then
        killall $POGOPKG
    fi
    mitm_pid=$(pidof $MITMPKG)
    if [[ -n "$mitm_pid" ]]; then
        killall $MITMPKG
        sleep 60
        am start -n "$MITMPKG/.MainActivity"
        log -p i -t eMagiskcosmogJp "Cosmog was restarted!"
    fi
}

autoupdate() {
    local last_check_file="/data/local/tmp/.last_autoupdate_check"
    local check_interval=86400  # 24 hours in seconds

    # Check if the last update was within the allowed interval
    if [ -f "$last_check_file" ]; then
        last_check_time=$(stat -c %Y "$last_check_file")
        current_time=$(date +%s)
        if (( (current_time - last_check_time) < check_interval )); then
            log -p i -t eMagiskcosmogJp "[AUTOUPDATE] Skipping auto-update due to check interval."
            return
        fi
    fi

    # Update logic
    autoupdate_url="https://raw.githubusercontent.com/MCraftetHD/eMagisk/master/custom/ATVServices.sh"
    script_path="/data/adb/modules/emagisk/ATVServices.sh"
    
    # Download the script with `curl` and capture HTTP status code
    curl_output=$(curl -sSL --insecure -o updated_script.sh -w "%{http_code}" "$autoupdate_url")
    
    # Verify if the file was downloaded successfully and the HTTP status code is 200
    if [[ "$curl_output" -eq 200 && -s updated_script.sh && "$(head -n 1 updated_script.sh)" == '#!/system/bin/sh' ]]; then
        if ! cmp -s updated_script.sh "$script_path"; then
            log -p i -t eMagiskcosmogJp "[AUTOUPDATE] New update available. Updating the script."
            mv updated_script.sh "$script_path"
            chmod +x "$script_path"
            log -p i -t eMagiskcosmogJp "[AUTOUPDATE] Script successfully updated and permissions set."
            nohup "$script_path" >/dev/null 2>&1 &
            pkill -f "$0"
        else
            log -p i -t eMagiskcosmogJp "[AUTOUPDATE] Script is already up-to-date."
        fi
    else
        log -p e -t eMagiskcosmogJp "[AUTOUPDATE] Update failed. HTTP Status: $curl_output. Check script content or permissions."
        [[ -s updated_script.sh ]] || log -p e -t eMagiskcosmogJp "[AUTOUPDATE] Downloaded script is empty or missing."
    fi
    
    # Update the timestamp for the last check
    touch "$last_check_file"
}


# Launch Cosmog every 20 minutes and monitor logcat for "IntegritySolver"
# Launch health check and MITM monitoring
#monitor_and_launch() {
#    log -p i -t eMagiskcosmogJp "Started health check!"

    # First check if the MITM package is installed
#    if result=$(check_mitmpkg); then
#        (
#            log -p i -t eMagiskcosmogJp "eMagisk: Astu's fork part. Starting health check service in 4 minutes... MITM: $MITMPKG"
#            counter=0
#            rdmDeviceID=1
#            log -p i -t eMagiskcosmogJp "Start counter at $counter"
#            
#            while true; do
#                current_time=$(date +"%H:%M")
#
#                # Check if com.nianticlabs.pokemongo is running
#                BUSYBOX_PS_OUTPUT=$(busybox ps | grep -E "com\.nianticlabs\.pokemongo")
#                
#                if [ -n "$BUSYBOX_PS_OUTPUT" ]; then
#                    log -p i -t eMagiskcosmogJp "com.nianticlabs.pokemongo is running. Adjusting I/O priority..."
#                    ionice -p $(pidof com.nianticlabs.pokemongo) -c 0 -n 0
#                    pids=$(/data/adb/magisk/busybox ps -T | /data/adb/magisk/busybox grep pokemongo | /data/adb/magisk/busybox cut -d' ' -f1 | /data/adb/magisk/busybox xargs)
#                    for i in $pids; do /data/adb/magisk/busybox chrt -r -p 99 $i & done
#                fi
#
#                log -p i -t eMagiskcosmogJp "Checking logcat for IntegritySolver in the last minute..."
#                if logcat -d -v time | awk -v curr_time="$current_time" '$1 ~ /^[0-9]{2}-[0-9]{2}$/ && $2 >= curr_time { found=1 } /IntegritySolver/ && found { exit 0 } END { exit 1 }'; then
#                    log -p i -t eMagiskcosmogJp "IntegritySolver found in logcat. No restart needed."
#                else
#                    log -p e -t eMagiskcosmogJp "IntegritySolver not found. Restarting $MITMPKG."
#                    am start -n $MITMPKG/.MainActivity
#                fi
#
#                # Clear logcat buffer every hour
#                current_minute=$(date +%M)
#                if [ "$current_minute" = "00" ]; then
#                    logcat -c
#                fi
#
#                sleep 300  # 5 minutes
#            done
#        ) &
#    else
#        log -p i -t eMagiskcosmogJp "MITM isn't installed on this device! The daemon will stop."
#    fi
#}


# Check if the magiskhide binary exists
if type magiskhide >/dev/null 2>&1; then
	# Enable Magiskhide if not enabled
	if ! magiskhide status; then
		log -p i -t eMagiskcosmogJp "Enabling MagiskHide"
		magiskhide enable
	fi

	# Add Pokemon Go to magiskhide if it isn't
	if ! magiskhide ls | grep -q -m1 "$POGOPKG"; then
		log -p i -t eMagiskcosmogJp "Adding PoGo to MagiskHide"
		magiskhide add "$POGOPKG"
	fi
fi

# Give all mitm services root permissions
# Check if magisk version is 23000 or less
if [ "$(magisk -V)" -le 23000 ]; then
	for package in "$MITMPKG" com.android.shell; do
		packageUID=$(dumpsys package "$package" | grep userId | head -n1 | cut -d= -f2)
		policy=$(sqlite3 /data/adb/magisk.db "select policy from policies where package_name='$package'")
		if [ "$policy" != 2 ]; then
			log -p i -t eMagiskcosmogJp "$package current policy is $policy. Adding root permissions..."
			if ! sqlite3 /data/adb/magisk.db "DELETE from policies WHERE package_name='$package'" ||
				! sqlite3 /data/adb/magisk.db "INSERT INTO policies (uid,package_name,policy,until,logging,notification) VALUES($packageUID,'$package',2,0,1,1)"; then
				log -p i -t eMagiskcosmogJp "ERROR: Could not add $package (UID: $packageUID) to Magisk's DB."
			fi
		else
			log -p i -t eMagiskcosmogJp "Root permissions for $package are OK!"
		fi
	done
else
	for package in "$MITMPKG" com.android.shell; do
		packageUID=$(dumpsys package "$package" | grep userId | head -n1 | cut -d= -f2)
		policy=$(sqlite3 /data/adb/magisk.db "select policy from policies where package_name='$package'")
		if [ "$policy" != 2 ]; then
			log -p i -t eMagiskcosmogJp "$package current policy is $policy. Adding root permissions..."
			if ! sqlite3 /data/adb/magisk.db "DELETE from policies WHERE package_name='$package'" ||
				! sqlite3 /data/adb/magisk.db "INSERT INTO policies (uid, policy, until, logging, notification) VALUES ($packageUID, 2, 0, 1, 1)"; then
				log -p i -t eMagiskcosmogJp "ERROR: Could not add $package (UID: $packageUID) to Magisk's DB."
			fi
   		else
			log -p i -t eMagiskcosmogJp "Root permissions for $package are OK!"
	  	fi
    	done
fi

# Set mitm mock location permission as ignore

if ! appops get $MITMPKG android:mock_location | grep -qm1 'No operations'; then
	log -p i -t eMagiskcosmogJp "Removing mock location permissions from $MITMPKG"
	appops set $MITMPKG android:mock_location 2
fi

# Disable all location providers

if ! settings get 2>/dev/null; then
	log -p i -t eMagiskcosmogJp "Checking allowed location providers as 'shell' user"
	allowedProviders=".$(su shell -c settings get secure location_providers_allowed)"
else
	log -p i -t eMagiskcosmogJp "Checking allowed location providers"
	allowedProviders=".$(settings get secure location_providers_allowed)"
fi

if [ "$allowedProviders" != "." ]; then
	log -p i -t eMagiskcosmogJp "Disabling location providers..."
	if ! settings put secure location_providers_allowed -gps,-wifi,-bluetooth,-network >/dev/null; then
		log -p i -t eMagiskcosmogJp "Running as 'shell' user"
		su shell -c 'settings put secure location_providers_allowed -gps,-wifi,-bluetooth,-network'
	fi
fi

# Make sure the device doesn't randomly turn off

if [ "$(settings get global stay_on_while_plugged_in)" != 3 ]; then
	log -p i -t eMagiskcosmogJp "Setting Stay On While Plugged In"
	settings put global stay_on_while_plugged_in 3
fi

# Disable package verifier

if [ "$(settings get global package_verifier_enable)" != 0 ]; then
	log -p i -t eMagiskcosmogJp "Disable package verifier"
	settings put global package_verifier_enable 0
fi
if [ "$(settings get global verifier_verify_adb_installs)" != 0 ]; then
	log -p i -t eMagiskcosmogJp "Disable package verifier over adb"
	settings put global verifier_verify_adb_installs 0
fi

# Disable play protect

if [ "$(settings get global package_verifier_user_consent)" != -1 ]; then
	log -p i -t eMagiskcosmogJp "Disable play protect"
	settings put global package_verifier_user_consent -1
fi

# Check if ADB is disabled (adb_enabled is set to 0)

adb_status=$(settings get global adb_enabled)
if [ "$adb_status" -eq 0 ]; then
	log -p i -t eMagiskcosmogJp "ADB is currently disabled. Enabling it..."
	settings put global adb_enabled 1
fi

# Check if ADB over Wi-Fi is disabled (adb_wifi_enabled is set to 0)

adb_wifi_status=$(settings get global adb_wifi_enabled)
if [ "$adb_wifi_status" -eq 0 ]; then
    log -p i -t eMagiskcosmogJp "ADB over Wi-Fi is currently disabled. Enabling it..."
    settings put global adb_wifi_enabled 1
fi

# Check and set permissions for adb_keys

adb_keys_file="/data/misc/adb/adb_keys"
if [ -e "$adb_keys_file" ]; then
	current_permissions=$(stat -c %a "$adb_keys_file")
	if [ "$current_permissions" -ne 640 ]; then
		log -p i -t eMagiskcosmogJp  "Changing permissions for $adb_keys_file to 640..."
		chmod 640 "$adb_keys_file"
	fi
fi

# Download cacert to use certs instead of curl -k 

cacert_path="/data/local/tmp/cacert.pem"
if [ ! -f "$cacert_path" ]; then
	log -p i -t eMagiskcosmogJp "Downloading cacert.pem..."
	curl -k -o "$cacert_path" https://curl.se/ca/cacert.pem
fi

# Main program starts here
force_restart
autoupdate
#monitor_and_launch
while true
do
    sleep 600 # Wait for 600 seconds (10 minutes)
    am start -n com.nianticlabs.pokemongo.ares/com.nianticlabs.pokemongo.ares.MainActivity
    log -p i -t eMagiskcosmogJp "Put Cosmog infront. Waiting 10 miutes to do it again."
done
#ENDOFFILE
