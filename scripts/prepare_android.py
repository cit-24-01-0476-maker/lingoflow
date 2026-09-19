import os
import shutil
import re
import subprocess

def run_cmd(cmd):
    print(f"--> Executing: {cmd}")
    res = subprocess.run(cmd, shell=True)
    if res.returncode != 0:
        raise Exception(f"Command failed with code {res.returncode}: {cmd}")

def main():
    backup_dir = "/tmp/lingo_backup"
    os.makedirs(backup_dir, exist_ok=True)

    # 1. Backup our Kotlin files
    found_kotlin = None
    for root, dirs, files in os.walk("android/app/src/main/kotlin"):
        if "MainActivity.kt" in files:
            found_kotlin = root
            break

    if found_kotlin:
        dest_k = os.path.join(backup_dir, "kotlin_src")
        shutil.rmtree(dest_k, ignore_errors=True)
        shutil.copytree(found_kotlin, dest_k)
        print(f"[+] Backed up Kotlin files from {found_kotlin}")

    # 2. Recreate clean android scaffold
    if os.path.exists("android"):
        shutil.rmtree("android")
    
    print("[+] Running flutter create --org com.lingoflow --platforms android .")
    run_cmd("flutter create --org com.lingoflow --platforms android .")

    # 3. Copy our Kotlin files into the generated com/lingoflow/lingoflow package
    target_kotlin = "android/app/src/main/kotlin/com/lingoflow/lingoflow"
    os.makedirs(target_kotlin, exist_ok=True)
    backed_k = os.path.join(backup_dir, "kotlin_src")
    if os.path.exists(backed_k):
        for f in os.listdir(backed_k):
            shutil.copy2(os.path.join(backed_k, f), os.path.join(target_kotlin, f))
        print(f"[+] Restored Kotlin files to {target_kotlin}: {os.listdir(target_kotlin)}")

    # 4. Create file_paths.xml for FileProvider
    res_xml = "android/app/src/main/res/xml"
    os.makedirs(res_xml, exist_ok=True)
    with open(os.path.join(res_xml, "file_paths.xml"), "w", encoding="utf-8") as f:
        f.write('<?xml version="1.0" encoding="utf-8"?>\n<paths xmlns:android="http://schemas.android.com/apk/res/android">\n    <external-files-path name="my_downloads" path="Download" />\n    <external-path name="external_files" path="." />\n</paths>\n')
    print("[+] Created file_paths.xml")

    # 5. Patch AndroidManifest.xml
    manifest_file = "android/app/src/main/AndroidManifest.xml"
    with open(manifest_file, "r", encoding="utf-8") as f:
        content = f.read()

    # Remove package="..." if present
    content = re.sub(r'\s*package="[^"]*"', '', content)

    # Add permissions
    permissions = """
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />
    <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
"""
    if "REQUEST_INSTALL_PACKAGES" not in content:
        content = content.replace("<application", permissions + "\n    <application", 1)

    # Add Service and Provider inside <application>
    extra_tags = """
        <service
            android:name=".LingoNotificationListenerService"
            android:label="LingoFlow WhatsApp Notification Listener"
            android:permission="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE"
            android:exported="true">
            <intent-filter>
                <action android:name="android.service.notification.NotificationListenerService" />
            </intent-filter>
        </service>

        <service
            android:name=".FloatingBubbleService"
            android:label="LingoFlow Assistive Touch Floating Bubble"
            android:exported="false" />

        <provider
            android:name="androidx.core.content.FileProvider"
            android:authorities="${applicationId}.fileprovider"
            android:exported="false"
            android:grantUriPermissions="true">
            <meta-data
                android:name="android.support.FILE_PROVIDER_PATHS"
                android:resource="@xml/file_paths" />
        </provider>
"""
    if "LingoNotificationListenerService" not in content:
        content = content.replace("</application>", extra_tags + "\n    </application>")

    with open(manifest_file, "w", encoding="utf-8") as f:
        f.write(content)
    print("[+] Patched AndroidManifest.xml")

if __name__ == "__main__":
    main()
