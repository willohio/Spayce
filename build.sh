#!/bin/sh

git fetch origin
git reset --hard origin/master

COMMITS_FROM=`/bin/date -u -v-1d +"%a %b %e %H:%M:%S %Y %z"`

echo "Get commits from: ${COMMITS_FROM}"
COMMIT_LOG=`git log --after="${COMMITS_FROM}"`

if [ -n "${COMMIT_LOG}" ]; then
  # Do something when var is non-zero length
  echo "Got commit details!"
  echo ${COMMIT_LOG}

  buildPlist="SpayceBook/Supporting Files/Spayce-Info.plist"
  buildNumber=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$buildPlist")
  buildNumber=$(($buildNumber + 1))
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "$buildPlist"

  git add -A
  git commit -m"Incremented version number to $buildNumber for the nightly build"
  git push origin master

  PRODUCT_NAME="Spayce"
  API_TOKEN="4ecc5ec0b994c815efc2cd1730bb734a_MTMzNjgzMDIwMTMtMDktMzAgMDA6MDM6NDAuMjUwNDc4"
  TEAM_TOKEN="04b24d864096e4227ae9494b4182f3b3_Mjc3NjY0MjAxMy0wOS0yOSAwMDo1NDo0NS40Njk3NTY"
  SIGNING_IDENTITY="iPhone Distribution: Spayce, Inc. (RUXUGY997C)"
  PROVISIONING_PROFILE="${HOME}/Library/MobileDevice/Provisioning Profiles/6F3E02A4-7B9F-4779-812D-55307861F506.mobileprovision"
  GROWL="growlnotify -a Xcode -w"

  DATE=$(/bin/date +"%Y-%m-%d")
  ARCHIVE=$(/bin/ls -t "${HOME}/Library/Developer/Xcode/Archives/${DATE}" | /usr/bin/grep xcarchive | /usr/bin/sed -n 1p)
  DSYM="${HOME}/Library/Developer/Xcode/Archives/${DATE}/${ARCHIVE}/dSYMs/${PRODUCT_NAME}.app.dSYM"
  APP="${HOME}/Library/Developer/Xcode/Archives/${DATE}/${ARCHIVE}/Products/Applications/${PRODUCT_NAME}.app"

  echo "Creating .ipa for ${PRODUCT_NAME}" | ${GROWL}

  /bin/rm "/tmp/${PRODUCT_NAME}.ipa"
  /usr/bin/xcrun -sdk iphoneos PackageApplication -v "${APP}" -o "/tmp/${PRODUCT_NAME}.ipa" --sign "${SIGNING_IDENTITY}" --embed "${PROVISIONING_PROFILE}"

  echo "Created .ipa for ${PRODUCT_NAME}" | ${GROWL}

  echo "Zipping .dSYM for ${PRODUCT_NAME}" | ${GROWL}

  /bin/rm "/tmp/${PRODUCT_NAME}.dSYM.zip"
  /usr/bin/zip -r "/tmp/${PRODUCT_NAME}.dSYM.zip" "${DSYM}"

  echo "Created .dSYM for ${PRODUCT_NAME}" | ${GROWL}

  echo "Uploading to TestFlight" | ${GROWL}

  /usr/bin/curl "http://testflightapp.com/api/builds.json" \
  -F file=@"/tmp/${PRODUCT_NAME}.ipa" \
  -F dsym=@"/tmp/${PRODUCT_NAME}.dSYM.zip" \
  -F api_token="${API_TOKEN}" \
  -F team_token="${TEAM_TOKEN}" \
  -F notify=True \
  -F distribution_lists="Spayce" \
  -F notes="${COMMIT_LOG}"

  echo "Uploaded to TestFlight" | ${GROWL} -s && /usr/bin/open "https://testflightapp.com/dashboard/builds/"
else
  echo "No changes!"
fi
