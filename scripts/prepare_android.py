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

    # 1. Backup custom Kotlin files and xml
    kotlin_src = "android/app/src/main/kotlin/com/lingoflow/app"
    if os.path.exists(kotlin_src):
        dest_k = os.path.join(backup_dir, "kotlin_app")
        shutil.rmtree(dest_k, ignore_errors=True)
        shutil.copytree(kotlin_src, dest_k)
        print("[+] Backed up Kotlin files successfully.")

    file_paths_xml = "android/app/src/main/res/xml/file_paths.xml"
    if os.path.exists(file_paths_xml):
        shutil.copy2(file_paths_xml, os.path.join(backup_dir, "file_paths.xml"))

    # 2. Re-create clean android directory with Flutter's official tool
    if os.path.exists("android"):
        shutil.rmtree("android")
    
    print("[+] Recreating clean android scaffold via 'flutter create'...")
    run_cmd("flutter create --org com.lingoflow --platforms android .")

    # 3. Clean generated Kotlin folders and install our custom package
    kotlin_root = "android/app/src/main/kotlin"
    for item in os.listdir(kotlin_root):
        item_path = os.path.join(kotlin_root, item)
        if os.path.isdir(item_path):
            shutil.rmtree(item_path)

    target_app_kotlin = os.path.join(kotlin_root, "com", "lingoflow", "app")
    os.makedirs(target_app_kotlin, exist_ok=True)
    backed_k = os.path.join(backup_dir, "kotlin_app")
    for f in os.listdir(backed_k):
        shutil.copy2(os.path.join(backed_k, f), os.path.join(target_app_kotlin, f))
    print(f"[+] Installed Kotlin source files: {os.listdir(target_app_kotlin)}")

    # 4. Restore file_paths.xml for FileProvider
    res_xml_dir = "android/app/src/main/res/xml"
    os.makedirs(res_xml_dir, exist_ok=True)
    xml_backup = os.path.join(backup_dir, "file_paths.xml")
    if os.path.exists(xml_backup):
        shutil.copy2(xml_backup, os.path.join(res_xml_dir, "file_paths.xml"))
    else:
        with open(os.path.join(res_xml_dir, "file_paths.xml"), "w", encoding="utf-8") as xf:
            xf.write('<?xml version="1.0" encoding="utf-8"?>\n<paths xmlns:android="http://schemas.android.com/apk/res/android">\n    <external-files-path name="my_downloads" path="Download" />\n    <external-path name="external_files" path="." />\n</paths>\n')

    # 5. Patch AndroidManifest.xml
    manifest_path = "android/app/src/main/AndroidManifest.xml"
    with open(manifest_path, "r", encoding="utf-8") as mf:
        content = mf.read()

    # Remove package="..." attribute
    content = re.sub(r'\s*package="[^"]*"', '', content)

    # Set explicit MainActivity class path
    content = re.sub(r'android:name="\.MainActivity"', 'android:name="com.lingoflow.app.MainActivity"', content)

    # Insert permissions before <application>
    permissions = """
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />
"""
    if "RECEIVE_BOOT_COMPLETED" not in content:
        content = content.replace("<application", permissions + "\n    <application", 1)

    # Insert Service & Provider inside <application>
    service_and_provider = """
        <service
            android:name="com.lingoflow.app.LingoNotificationListenerService"
            android:label="LingoFlow WhatsApp Notification Listener"
            android:permission="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE"
            android:exported="true">
            <intent-filter>
                <action android:name="android.service.notification.NotificationListenerService" />
            </intent-filter>
        </service>

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
        content = content.replace("</application>", service_and_provider + "\n    </application>")

    with open(manifest_path, "w", encoding="utf-8") as mf:
        mf.write(content)
    print("[+] Patched AndroidManifest.xml successfully.")

    # 6. Patch app build.gradle (.kts or groovy)
    gradle_file = "android/app/build.gradle.kts" if os.path.exists("android/app/build.gradle.kts") else "android/app/build.gradle"
    print(f"[+] Patching {gradle_file}...")

    with open(gradle_file, "r", encoding="utf-8") as gf:
        gcontent = gf.read()

    is_kts = gradle_file.endswith(".kts")

    if is_kts:
        gcontent = re.sub(r'namespace\s*=\s*"[^"]*"', 'namespace = "com.lingoflow.app"', gcontent)
        gcontent = re.sub(r'applicationId\s*=\s*"[^"]*"', 'applicationId = "com.lingoflow.app"', gcontent)
        gcontent = re.sub(r'minSdk\s*=\s*flutter\.minSdkVersion', 'minSdk = 23', gcontent)
        if "androidx.core:core-ktx" not in gcontent:
            gcontent += '\ndependencies {\n    implementation("androidx.core:core-ktx:1.12.0")\n}\n'
    else:
        gcontent = re.sub(r'namespace\s+("[^"]*"|\'[^\']*\')', 'namespace "com.lingoflow.app"', gcontent)
        gcontent = re.sub(r'applicationId\s+("[^"]*"|\'[^\']*\')', 'applicationId "com.lingoflow.app"', gcontent)
        gcontent = re.sub(r'minSdkVersion\s+flutter\.minSdkVersion', 'minSdkVersion 23', gcontent)
        gcontent = re.sub(r'minSdk\s*=\s*flutter\.minSdkVersion', 'minSdk = 23', gcontent)
        if "androidx.core:core-ktx" not in gcontent:
            gcontent += '\ndependencies {\n    implementation "androidx.core:core-ktx:1.12.0"\n}\n'

    with open(gradle_file, "w", encoding="utf-8") as gf:
        gf.write(gcontent)
    print(f"[+] Patched {gradle_file} successfully.")

if __name__ == "__main__":
    main()
