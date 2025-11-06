# MFA Testing Checklist

Use this checklist to systematically test all MFA scenarios. Test on both simulator and real device where indicated.

---

## Pre-Testing Setup

### Backend Setup
- [ ] Spring Boot application starts without errors
- [ ] H2 console accessible at http://localhost:8080/h2-console
- [ ] Test enrollment endpoint with curl succeeds
- [ ] Logs show clear output
- [ ] Database tables created correctly

### iOS Setup  
- [ ] App builds without errors
- [ ] Info.plist has NSFaceIDUsageDescription
- [ ] Base URL points to correct backend (localhost:8080)
- [ ] Simulator has Face ID enrolled (Features > Face ID > Enrolled)
- [ ] Real device available for Secure Enclave tests

---

## Scenario 1: Happy Path - Biometric Enrollment
**Test on**: Simulator ✅ | Real Device ✅

### Setup
- [ ] Simulator: Face ID enrolled
- [ ] Real Device: Face ID/Touch ID enrolled
- [ ] No previous enrollment exists

### Steps
1. [ ] Launch app
2. [ ] App shows "Not Enrolled" status
3. [ ] Tap "Enroll with Face ID/Touch ID"
4. [ ] System permission prompt appears (iOS may cache this)
5. [ ] Tap "OK" or "Allow"
6. [ ] Face ID/Touch ID prompt appears
7. [ ] Authenticate successfully
8. [ ] App shows "Enrollment Successful"
9. [ ] Check server: Device registered with public key

### Verification
- [ ] Key created in keychain with .userPresence flag
- [ ] Public key sent to server
- [ ] Server has device record with SECURE_ENCLAVE method
- [ ] Local storage shows enrolled status
- [ ] Can retrieve key from keychain

### Expected Logs
```
iOS: Creating Secure Enclave key with .userPresence
iOS: Key created successfully
iOS: Testing key with biometric prompt
iOS: Signature created
iOS: Registering with server
iOS: Enrollment successful
Backend: Received enrollment request
Backend: Public key saved
Backend: Device enrolled: [deviceId]
```

---

## Scenario 2: User Declines System Biometric Permission
**Test on**: Simulator ✅ | Real Device ✅

### Setup
- [ ] Fresh app install OR remove Face ID permission in Settings
- [ ] Face ID enrolled on device

### Steps
1. [ ] Launch app
2. [ ] Tap "Enroll with Face ID"
3. [ ] System asks "Allow [App] to use Face ID?"
4. [ ] Tap "Don't Allow"
5. [ ] App catches LAError.userCancel
6. [ ] Alert appears: "Use Passcode Instead?"
7. [ ] Tap "Yes"
8. [ ] Passcode prompt appears
9. [ ] Enter passcode
10. [ ] Success with passcode method

### Verification
- [ ] First key creation abandoned
- [ ] Second key created with .devicePasscode flag
- [ ] Server has device with SECURE_ENCLAVE method (still uses SE, just passcode-only)
- [ ] Local storage shows passcode method
- [ ] Future authentication uses passcode, not biometrics

### Expected Behavior
- [ ] No biometric prompt on future logins
- [ ] Direct to passcode entry
- [ ] Key still in Secure Enclave (on real device)

---

## Scenario 3: User Chooses Passcode Only
**Test on**: Simulator ✅ | Real Device ✅

### Setup
- [ ] Face ID available but user prefers passcode
- [ ] No previous enrollment

### Steps
1. [ ] Launch app
2. [ ] App shows both options: "Use Face ID" and "Use Passcode Only"
3. [ ] Tap "Use Passcode Only"
4. [ ] Passcode prompt appears immediately (no biometric)
5. [ ] Enter passcode
6. [ ] Success

### Verification
- [ ] Key created with .devicePasscode flag from start
- [ ] No biometric prompt attempted
- [ ] Server registered correctly
- [ ] Tag used: "com.app.mfa.passcode"

---

## Scenario 4: No Biometrics Enrolled on Device
**Test on**: Simulator ⚠️ (limited) | Real Device ✅

### Setup (Real Device)
- [ ] Go to Settings > Face ID & Passcode
- [ ] Reset Face ID
- [ ] Ensure passcode is still set

### Setup (Simulator)
- [ ] Features > Face ID > No Enrolled

### Steps
1. [ ] Launch app
2. [ ] App detects no biometrics
3. [ ] Only shows "Use Passcode" option
4. [ ] Message: "Your device doesn't have biometric authentication set up"
5. [ ] Tap "Enroll with Passcode"
6. [ ] Passcode prompt appears
7. [ ] Success

### Verification
- [ ] DeviceCapability returns .passcodeOnly
- [ ] No biometric option shown
- [ ] Enrollment completes with passcode method

---

## Scenario 5: No Device Security (Critical Edge Case)
**Test on**: Simulator ❌ (cannot test) | Real Device ✅

### Setup (Real Device Only)
1. [ ] Disable Face ID in Settings
2. [ ] Remove passcode completely

### Steps
1. [ ] Launch app
2. [ ] App detects no security
3. [ ] DeviceCapability returns .none
4. [ ] Alert appears: "Device security required"
5. [ ] "Open Settings" button provided
6. [ ] "Use SMS Only" button as fallback
7. [ ] Cannot proceed with Secure Enclave enrollment

### Verification
- [ ] No key creation attempted
- [ ] If user selects SMS fallback, registers without public key
- [ ] Server shows SMS_OTP method for this device

### Note
This scenario is extremely rare in practice. Most users have at least a passcode set.

---

## Scenario 6: Successful Authentication with Biometrics
**Test on**: Simulator ✅ | Real Device ✅

### Setup
- [ ] Device enrolled with biometric method
- [ ] Backend running
- [ ] Valid user exists

### Steps
1. [ ] Open authentication screen
2. [ ] Enter username
3. [ ] Tap "Sign In"
4. [ ] App requests challenge from server
5. [ ] Challenge received (base64 nonce)
6. [ ] App initiates signature
7. [ ] Face ID/Touch ID prompt appears
8. [ ] Authenticate successfully
9. [ ] Signature sent to server
10. [ ] Server validates signature
11. [ ] Success screen with token

### Verification
- [ ] Challenge created and stored in DB
- [ ] Challenge not expired
- [ ] Signature verification succeeds
- [ ] Challenge marked as used
- [ ] Device lastUsed timestamp updated
- [ ] Token returned to client

### Expected Logs
```
iOS: Requesting challenge
Backend: Challenge generated: [challengeId]
iOS: Challenge received
iOS: Initiating signature
iOS: Biometric prompt shown
iOS: Signature created
iOS: Sending signature to server
Backend: Verifying signature
Backend: Signature valid
Backend: Authentication successful
iOS: Token received
```

---

## Scenario 7: Authentication with SMS Fallback
**Test on**: Simulator ✅ | Real Device ✅

### Setup
- [ ] Device enrolled with SMS_OTP method
- [ ] OR Secure Enclave unavailable at auth time

### Steps
1. [ ] Enter username
2. [ ] Tap "Sign In"
3. [ ] Server determines SMS required
4. [ ] OTP sent (check backend logs)
5. [ ] OTP input screen appears
6. [ ] Enter correct 6-digit OTP
7. [ ] Tap "Verify"
8. [ ] Server validates OTP
9. [ ] Success

### Verification
- [ ] OTP generated (6 digits)
- [ ] OTP saved with expiration
- [ ] Backend logs show: "📱 SMS to +1234567890: Your OTP is 123456"
- [ ] OTP validation succeeds
- [ ] OTP marked as used
- [ ] Cannot reuse same OTP

### Test Invalid OTP
- [ ] Enter wrong OTP
- [ ] Server returns error
- [ ] User can retry
- [ ] After 3 failures, suggest new OTP

---

## Scenario 8: Device Security Removed After Enrollment
**Test on**: Simulator ❌ (cannot test fully) | Real Device ✅

### Setup (Real Device)
1. [ ] Enroll device with Face ID
2. [ ] Verify enrollment successful
3. [ ] Go to Settings > Face ID & Passcode
4. [ ] Turn off Face ID
5. [ ] Remove passcode

### Steps
1. [ ] Return to app (or relaunch)
2. [ ] App performs security check
3. [ ] Detects no authentication available
4. [ ] Shows critical alert
5. [ ] Auto-downgrades to SMS method
6. [ ] Notifies server of downgrade
7. [ ] Old key remains but unusable

### Verification
- [ ] DeviceCapability returns .none
- [ ] App updates local method to .smsOTP
- [ ] Server updated: method changed to SMS_OTP
- [ ] publicKey nullified on server (optional)
- [ ] User informed clearly
- [ ] Can still log in with SMS

### Expected Alert
```
"Security Required"
"Device passcode was removed. Multi-factor authentication has been 
downgraded to SMS verification. Set up device security to restore 
stronger protection."
```

---

## Scenario 9: Security Restored - Upgrade Prompt
**Test on**: Simulator ❌ | Real Device ✅

### Setup
1. [ ] Device on SMS_OTP method (from Scenario 8)
2. [ ] Set up Face ID again in Settings
3. [ ] Set device passcode

### Steps
1. [ ] Launch app
2. [ ] App detects security now available
3. [ ] Prompt appears: "Upgrade to Biometric Security?"
4. [ ] Message explains benefits
5. [ ] Tap "Upgrade"
6. [ ] New key creation flow
7. [ ] Face ID enrollment
8. [ ] Success - upgraded to Secure Enclave

### Verification
- [ ] DeviceCapability now returns .biometricsAvailable
- [ ] New key pair created
- [ ] New public key sent to server
- [ ] Server method updated to SECURE_ENCLAVE
- [ ] Old SMS_OTP record updated, not duplicated

---

## Scenario 10: Switch Authentication Method
**Test on**: Simulator ✅ | Real Device ✅

### Test A: Biometric → Passcode Only
1. [ ] Enrolled with Face ID
2. [ ] Go to Settings in app
3. [ ] Tap "Switch to Passcode Only"
4. [ ] Confirmation dialog
5. [ ] Tap "Confirm"
6. [ ] Old biometric key deleted
7. [ ] New passcode key created
8. [ ] Passcode prompt appears
9. [ ] Success
10. [ ] Server updated with new public key

### Test B: Passcode → Biometric
1. [ ] Enrolled with passcode only
2. [ ] Face ID available on device
3. [ ] Go to Settings in app
4. [ ] Tap "Enable Face ID"
5. [ ] System permission prompt
6. [ ] Approve
7. [ ] Face ID enrollment
8. [ ] Success

### Verification for Both
- [ ] Old key tag deleted from keychain
- [ ] New key tag present
- [ ] Server has new public key
- [ ] deviceId unchanged
- [ ] enrolledAt unchanged
- [ ] lastUsed updated

---

## Error Handling Tests

### Test: Challenge Expiration
1. [ ] Request challenge
2. [ ] Wait 6 minutes (challenge expires in 5)
3. [ ] Attempt to use expired challenge
4. [ ] Server returns "Challenge expired"
5. [ ] App requests new challenge

### Test: Challenge Reuse
1. [ ] Complete authentication successfully
2. [ ] Try to reuse same challenge/signature
3. [ ] Server returns "Challenge already used"
4. [ ] App requests new challenge

### Test: Invalid Signature
1. [ ] Request challenge
2. [ ] Modify signature before sending
3. [ ] Server validation fails
4. [ ] Returns "Invalid signature"
5. [ ] User can retry

### Test: Network Timeout
1. [ ] Stop backend server
2. [ ] Attempt enrollment or authentication
3. [ ] App shows network error
4. [ ] Clear error message
5. [ ] Retry option available

### Test: Biometric Lockout
1. [ ] Fail Face ID 5 times
2. [ ] LAError.biometryLockout thrown
3. [ ] App automatically offers passcode
4. [ ] Passcode entry works
5. [ ] Message: "Face ID locked. Use passcode."

### Test: User Cancels Authentication
1. [ ] Initiate sign in
2. [ ] Face ID prompt appears
3. [ ] Tap "Cancel"
4. [ ] App catches LAError.userCancel
5. [ ] Returns to sign-in screen
6. [ ] Can retry immediately

---

## Testing Dashboard Verification

### Device Status Display
- [ ] Shows Secure Enclave availability correctly
- [ ] Shows biometric type (Face ID/Touch ID/None)
- [ ] Shows passcode status
- [ ] Shows current enrollment status
- [ ] Shows current MFA method
- [ ] Updates in real-time

### Test Actions Work
- [ ] Each button performs correct action
- [ ] Results logged to results list
- [ ] Timestamps accurate
- [ ] Success/failure indicated clearly
- [ ] Error details expandable

### Results Log
- [ ] Chronological order (newest first)
- [ ] Color coding works (green/red/yellow)
- [ ] Tap to expand details
- [ ] Clear log button works
- [ ] Persists across app restarts (optional)

---

## Backend API Tests (Independent of iOS)

### Test with curl

**Enroll Device:**
```bash
curl -X POST http://localhost:8080/api/v1/mfa/enroll \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "phoneNumber": "+1234567890",
    "publicKey": "base64key",
    "method": "secureEnclave",
    "deviceId": "test-device-123",
    "deviceModel": "Test Device"
  }'
```
- [ ] Returns 200 OK
- [ ] Response shows success: true
- [ ] Check H2 console: Device record created

**Request Challenge:**
```bash
curl -X POST http://localhost:8080/api/v1/auth/initiate \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "deviceId": "test-device-123"
  }'
```
- [ ] Returns challenge (base64)
- [ ] Returns challengeId
- [ ] expiresIn = 300
- [ ] Check DB: Challenge record created

**Request OTP:**
```bash
curl -X POST http://localhost:8080/api/v1/auth/request-otp \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "phoneNumber": "+1234567890"
  }'
```
- [ ] Returns success
- [ ] Backend logs show OTP
- [ ] Check DB: OTP record created

**Verify OTP:**
```bash
curl -X POST http://localhost:8080/api/v1/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "otp": "123456"
  }'
```
- [ ] Valid OTP returns success
- [ ] Invalid OTP returns error
- [ ] Used OTP cannot be reused

---

## Performance Tests

### Key Creation Speed
- [ ] Biometric key creation: < 1 second
- [ ] Passcode key creation: < 1 second
- [ ] No noticeable delay for user

### Signature Speed
- [ ] Sign operation: < 500ms (excluding user auth time)
- [ ] Network round-trip: < 2 seconds on local network
- [ ] Full authentication: < 5 seconds

### UI Responsiveness
- [ ] No blocking on main thread
- [ ] Loading indicators shown during operations
- [ ] Can cancel operations
- [ ] App doesn't freeze

---

## Device-Specific Tests

### Test on iPhone (Real Device)
- [ ] Face ID enrollment works
- [ ] Face ID authentication works
- [ ] Secure Enclave key created
- [ ] Cannot export private key
- [ ] Key survives app reinstall (if keychain backup enabled)

### Test on iPhone with Touch ID (if available)
- [ ] Touch ID works instead of Face ID
- [ ] Same functionality
- [ ] UI adapts (shows "Touch ID" not "Face ID")

### Test on iPad (if supporting)
- [ ] Larger screen layouts work
- [ ] Same functionality as iPhone

---

## Regression Tests (After Code Changes)

Run these after any significant changes:

**Quick Smoke Test (5 minutes):**
- [ ] App launches
- [ ] Backend starts
- [ ] Enrollment works (one method)
- [ ] Authentication works

**Full Test Suite (30 minutes):**
- [ ] All 10 scenarios
- [ ] All error handling tests
- [ ] Both simulator and device
- [ ] All API endpoints

---

## Test Results Summary

Date Tested: _______________
Tested By: _______________
Environment: Simulator ☐ Real Device ☐ Both ☐

| Scenario | Simulator | Real Device | Notes |
|----------|-----------|-------------|-------|
| 1. Biometric enrollment | ☐ | ☐ | |
| 2. Biometric decline | ☐ | ☐ | |
| 3. Passcode only choice | ☐ | ☐ | |
| 4. No biometrics | ☐ | ☐ | |
| 5. No security | ☐ | ☐ | |
| 6. Biometric auth | ☐ | ☐ | |
| 7. SMS fallback | ☐ | ☐ | |
| 8. Security removed | ☐ | ☐ | |
| 9. Security restored | ☐ | ☐ | |
| 10. Method switching | ☐ | ☐ | |

**Issues Found:**
[List any issues discovered during testing]

**Overall Assessment:**
- [ ] Ready for demo
- [ ] Needs minor fixes
- [ ] Needs major work

---

## Tips for Effective Testing

1. **Test systematically** - Don't skip steps
2. **Document everything** - Note what worked and what didn't
3. **Test on real device** - Simulator has limitations
4. **Check backend logs** - Verify server-side behavior
5. **Clean state between tests** - Unenroll before re-testing
6. **Take screenshots** - Document UI states
7. **Note timestamps** - Helps debug timing issues
8. **Test error paths** - They're just as important as happy paths
9. **Use H2 console** - Inspect database state directly
10. **Have fun** - Testing can reveal interesting edge cases!

---

Remember: The goal is not just to check boxes, but to truly understand how MFA works in all scenarios and ensure the implementation is robust and user-friendly.
