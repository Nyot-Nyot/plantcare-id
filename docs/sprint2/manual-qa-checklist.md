# Sprint 2 Task 9: Manual QA Checklist

## Overview

This checklist covers end-to-end manual testing for Sprint 2's Plant Identification feature (Task 1-8). Use this during QA sessions to validate the complete user journey.

**Test Environment:**

-   Device/Emulator: ********\_********
-   OS Version: ********\_********
-   App Version: ********\_********
-   Backend URL: ********\_********
-   Date: ********\_********
-   Tester: ********\_********

---

## 1. Environment & Configuration

### 1.1 Initial Setup

-   [ ] Backend orchestrator is running (`python backend/main.py`)
-   [ ] For Android emulator: `adb reverse tcp:8001 tcp:8001` configured
-   [ ] `.env` file contains valid `ORCHESTRATOR_URL`
-   [ ] `.env` file contains valid `PLANT_ID_API_KEY` (backend)
-   [ ] App launches without crashes
-   [ ] No console errors on startup

---

## 2. Camera & Gallery Integration

### 2.1 Camera Permissions

-   [ ] First launch: Camera permission dialog appears
-   [ ] **Grant permission**: Camera screen loads successfully
-   [ ] **Deny permission**: Error message displayed with clear instructions
-   [ ] Permission can be re-granted from settings

### 2.2 Camera Capture Flow

-   [ ] Camera viewfinder displays live feed
-   [ ] Overlay tips visible (focus, distance guidance in Indonesian)
-   [ ] Capture button is accessible and responsive
-   [ ] Gallery shortcut button visible
-   [ ] Captured image shows in preview
-   [ ] Preview has "Retake" and "Submit" buttons
-   [ ] Retake button returns to camera
-   [ ] Submit button proceeds to identification

### 2.3 Gallery Import Flow

-   [ ] Gallery button opens system photo picker
-   [ ] Can select existing plant photo
-   [ ] Selected image shows in preview
-   [ ] Same "Retake"/"Submit" flow as camera capture
-   [ ] Invalid file types show error message

---

## 3. Image Validation & Compression

### 3.1 Image Validation

-   [ ] Images < 800px show warning message
-   [ ] Images >= 800px accepted
-   [ ] Optimal resolution (>=1024px) mentioned in tips
-   [ ] Non-image files rejected with clear error
-   [ ] Corrupted images handled gracefully

### 3.2 Compression

-   [ ] Large images (>2MB) automatically compressed
-   [ ] Compression maintains aspect ratio
-   [ ] Compressed image quality acceptable
-   [ ] Compression happens before upload (loading state visible)
-   [ ] Upload progress indicator appears

---

## 4. API Integration & Request Flow

### 4.1 Successful Identification

-   [ ] Loading skeleton/indicator appears during upload
-   [ ] Upload completes within reasonable time (<10s for good network)
-   [ ] Result screen appears with identification data
-   [ ] No errors in console/logs

### 4.2 Health Assessment (checkHealth=true)

-   [ ] When enabled: health status included in result
-   [ ] Health status shows "Sehat" or "Tidak Sehat"
-   [ ] Disease suggestions appear when unhealthy
-   [ ] Health assessment increases response time slightly (expected)

### 4.3 Error Handling

-   [ ] **Backend offline**: Clear error message in Indonesian
-   [ ] **Network timeout**: Timeout message with retry option
-   [ ] **Plant.id API error**: Appropriate error message
-   [ ] **Invalid API response**: Handled gracefully
-   [ ] Retry button works after error
-   [ ] Can return to camera after error

### 4.4 Cancellation

-   [ ] Can cancel upload mid-request
-   [ ] Cancel button visible during upload
-   [ ] Cancelled request doesn't show result
-   [ ] Can start new identification after cancel

---

## 5. Identify Result Screen

### 5.1 Result Display

-   [ ] Thumbnail of uploaded image visible
-   [ ] Common name (nama lokal) displayed
-   [ ] Scientific name (nama latin) displayed
-   [ ] Confidence score shown as percentage
-   [ ] Confidence progress bar matches percentage
-   [ ] Provider badge shows "Plant.id"
-   [ ] Top suggestions list visible (if available)

### 5.2 Low Confidence Warning

-   [ ] Confidence < 70%: Warning banner appears
-   [ ] Warning message in Indonesian
-   [ ] "Retake" action available
-   [ ] "Try Gallery" action available
-   [ ] Warning is prominent but not blocking

### 5.3 Actions

-   [ ] "Save to Collection" button visible
-   [ ] "View Guide" button visible (may be placeholder)
-   [ ] "Retake" button returns to camera
-   [ ] All buttons responsive and clearly labeled

---

## 6. Save to Collection

### 6.1 Save Flow

-   [ ] Click "Save to Collection" shows confirmation
-   [ ] Success toast/snackbar appears
-   [ ] Entry saves to local database
-   [ ] Image thumbnail saved locally
-   [ ] Metadata (confidence, names, date) saved

### 6.2 Persistence

-   [ ] Restart app: Collection persists
-   [ ] View collection screen: Saved item appears
-   [ ] Item shows correct thumbnail and name
-   [ ] Item shows correct confidence score

### 6.3 Sync Stub

-   [ ] `syncCollection()` function exists (no-op or minimal implementation)
-   [ ] No sync errors in logs
-   [ ] Ready for future sync implementation

---

## 7. Offline & Caching Behavior

### 7.1 Online Cache Behavior

-   [ ] **First identification**: Fresh API call, result cached
-   [ ] **Repeat same image** (within 24h): Cache hit indicated
-   [ ] Cache indicator shows "📜 Dari Cache" or similar
-   [ ] Cached result loads instantly
-   [ ] Cached result matches original API response

### 7.2 Offline Behavior

-   [ ] **Disable network** (airplane mode)
-   [ ] **Submit cached image**: Shows cached result
-   [ ] Offline indicator shows "📵 Offline" or similar
-   [ ] **Submit new image**: Clear offline error message
-   [ ] Error message in Indonesian suggests going online
-   [ ] Re-enable network: Next submission works

### 7.3 Cache Management

-   [ ] Cache automatically cleans up after identification
-   [ ] Cache TTL = 24 hours (test by manipulating system time if needed)
-   [ ] Expired cache entries removed automatically
-   [ ] `getCacheStats()` returns valid data (dev tools)

### 7.4 Cache/Offline Indicators

-   [ ] Cached result shows cache banner/badge
-   [ ] Offline result shows offline banner/badge
-   [ ] Indicators have distinct colors (info blue for cache, warning orange for offline)
-   [ ] Indicators clearly communicated in Indonesian

---

## 8. UI/UX Quality

### 8.1 Responsiveness

-   [ ] Works on portrait orientation
-   [ ] Works on landscape orientation (if supported)
-   [ ] Safe area respected (no content behind notch/nav bar)
-   [ ] Touch targets >=44x44pt
-   [ ] Smooth transitions between screens

### 8.2 Accessibility

-   [ ] Text readable at default system font size
-   [ ] Sufficient color contrast (WCAG AA minimum)
-   [ ] Important actions have clear labels
-   [ ] Error messages are clear and actionable

### 8.3 Loading States

-   [ ] Loading indicators for all async operations
-   [ ] Skeleton screens for data fetching
-   [ ] No blank screens during loading
-   [ ] Loading states cancellable where appropriate

### 8.4 Indonesian Localization

-   [ ] All UI text in Indonesian
-   [ ] Error messages in Indonesian
-   [ ] Tips and guidance in Indonesian
-   [ ] Scientific names preserved in Latin (expected)

---

## 9. Performance

### 9.1 Response Times

-   [ ] Camera launch: < 2s
-   [ ] Image capture: < 1s
-   [ ] Compression: < 2s for large images
-   [ ] API call: < 10s on good network
-   [ ] Cache retrieval: < 500ms
-   [ ] Screen transitions: < 300ms

### 9.2 Resource Usage

-   [ ] No memory leaks (test with repeated identifications)
-   [ ] Camera releases properly when navigating away
-   [ ] No excessive battery drain
-   [ ] Image files cleaned up after use

---

## 10. Edge Cases & Error Scenarios

### 10.1 Edge Cases

-   [ ] Very small image (< 100px): Handled with error
-   [ ] Very large image (> 10MB): Compressed successfully
-   [ ] Extreme aspect ratios: Handled gracefully
-   [ ] Multiple rapid submissions: Queued or blocked appropriately
-   [ ] Back button during upload: Handled gracefully

### 10.2 API Edge Cases

-   [ ] Plant.id returns 0 suggestions: Handled with message
-   [ ] Plant.id returns very low confidence (<10%): Warning shown
-   [ ] Plant.id timeout: Retry option available
-   [ ] Plant.id rate limit: Clear error message

### 10.3 Database Edge Cases

-   [ ] Save while offline: Deferred sync (if implemented)
-   [ ] Database full: Error handling
-   [ ] Corrupt database: Handled with migration or reset

---

## 11. Security & Privacy

-   [ ] Camera access only when needed
-   [ ] Images not stored unnecessarily
-   [ ] API keys not exposed in client code
-   [ ] HTTPS used for API calls
-   [ ] No sensitive data in logs

---

## 12. Regression Testing

### 12.1 Existing Features

-   [ ] Authentication still works (if implemented)
-   [ ] Home screen accessible
-   [ ] Navigation between screens intact
-   [ ] Other features unaffected by Sprint 2 changes

---

## Test Results Summary

**Total Tests:** **\_\_\_**
**Passed:** **\_\_\_**
**Failed:** **\_\_\_**
**Blocked:** **\_\_\_**

### Critical Issues Found:

1. ***
2. ***
3. ***

### Non-Critical Issues:

1. ***
2. ***

### Notes:

---

---

---

**QA Verdict:** ⬜ PASS | ⬜ FAIL | ⬜ PASS WITH MINOR ISSUES

**Signed Off By:** ********\_\_\_******** **Date:** ****\_\_\_****
