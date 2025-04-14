# Grocery App

A Flutter application that fetches product data from a Google Sheet and displays it in a user-friendly interface. The app allows users to browse products by category, select different weight options, and add items to a cart for checkout.

## Features

- Fetches product data from a Google Sheets web app
- Displays products categorized by type
- Shows product details with available weight options
- Allows selection of weight or per-unit pricing based on available data
- Shopping cart functionality with quantity adjustment
- Checkout process with order summary

## Google Sheet Integration

The app connects to a Google Sheet with the following structure:

- Product name column (labeled as "TELUGU")
- Weight columns (labeled as "1K", "0.5K", "250G", "100G", "50G", "25G", and "10G")
- Per unit price column (labeled as "₹/N")
- Product type column (e.g., flours_and_grains, salts_and_sugars, spices_and_condiments)

The app intelligently handles empty or invalid data in the sheet, only showing options that have valid prices.

## Running the App

1. Make sure you have Flutter installed on your machine
2. Clone this repository
3. Run `flutter pub get` to install dependencies
4. Connect a device or start an emulator
5. Run `flutter run` to start the app

## Google Sheets Web App

The app connects to a Google Sheets web app at the following URL:

```
https://script.google.com/macros/s/AKfycbxNP4QfPQp6KihAsaYQppSL_vHFON7P0ngpKdWkNFRWBnjLzxBpwq13qSrWVG5CLYfAcg/exec
```

This web app provides a JSON API for accessing the product data.
# grocery-app
