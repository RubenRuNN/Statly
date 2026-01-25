# StoreKit 2 Testing Guide

## Quick Setup for Local Testing

1. **Add StoreKit Configuration File to Xcode:**
   - The `Products.storekit` file has been created in the project root
   - In Xcode, go to **Product > Scheme > Edit Scheme...**
   - Select **Run** in the left sidebar
   - Go to the **Options** tab
   - Under **StoreKit Configuration**, select `Products.storekit`
   - Click **Close**

2. **Run the App:**
   - Build and run the app
   - The subscription product should now load from the local StoreKit Configuration file
   - You can test purchases without needing App Store Connect setup

## Testing Scenarios

### Test Subscription Purchase:
1. Open the app and tap the crown icon in the navigation bar
2. You should see the subscription view with pricing
3. Tap "Subscribe to Premium"
4. A StoreKit purchase dialog will appear
5. Select "Purchase" to complete the transaction
6. The app should update to show Premium status

### Test Subscription Status:
- After purchasing, the app should show "Premium Active"
- All premium features should be unlocked:
  - Can create more than 2 widgets
  - Logo option is enabled
  - All refresh intervals are available

### Test Free Version Limits:
1. To test free version, you can modify the StoreKit Configuration:
   - Change `"subscriptionStatus" : "subscribed"` to `"expired"` or remove the subscription
   - Or simply don't purchase and test the limits:
     - Try creating a 3rd widget → should show upgrade prompt
     - Try enabling logo → should be disabled
     - Try selecting 5min refresh → should be limited to 2 hours max

### Test Restore Purchases:
1. Tap "Restore Purchases" button
2. StoreKit will check for existing subscriptions
3. If a subscription exists in the configuration, it will be restored

## StoreKit Configuration File Details

The `Products.storekit` file includes:
- **Product ID**: `com.swipeuplabs.statly.premium`
- **Price**: $4.99/month
- **Status**: Pre-configured as "subscribed" for testing

### Modifying the Configuration:

You can edit `Products.storekit` to test different scenarios:

**Test Expired Subscription:**
```json
"subscriptionStatus" : "expired"
```

**Test Different Prices:**
```json
"displayPrice" : "9.99"
```

**Test Different Periods:**
```json
"recurringSubscriptionPeriod" : "P1Y"  // 1 year
"recurringSubscriptionPeriod" : "P1W"   // 1 week
```

## Production Setup (App Store Connect)

When ready for production:

1. **Create Subscription in App Store Connect:**
   - Go to App Store Connect > Your App > Subscriptions
   - Create a new subscription group
   - Add subscription with ID: `com.swipeuplabs.statly.premium`
   - Set pricing and duration
   - Submit for review

2. **Remove StoreKit Configuration:**
   - In Xcode Scheme settings, remove the StoreKit Configuration
   - The app will now use real App Store Connect products

## Troubleshooting

**"Loading subscription options" forever:**
- Make sure `Products.storekit` is selected in Scheme settings
- Check that the product ID matches: `com.swipeuplabs.statly.premium`
- Check Xcode console for error messages

**Product not found:**
- Verify the product ID in `SubscriptionManager.swift` matches the StoreKit Configuration
- Make sure the StoreKit Configuration file is added to the Xcode project

**Purchase not working:**
- Ensure you're testing on a device or simulator with StoreKit testing enabled
- Check that the subscription status in StoreKit Configuration is set correctly
