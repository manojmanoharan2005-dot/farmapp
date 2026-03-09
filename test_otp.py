"""
Test OTP Sending Functionality
This script tests the Twilio SMS integration
"""
import os
from dotenv import load_dotenv
from utils.sms_gateway import SMSGateway
from utils.otp_manager import OTPManager

# Load environment variables
load_dotenv()

print("=" * 60)
print("🧪 TESTING OTP FUNCTIONALITY")
print("=" * 60)

# Initialize OTP Manager
otp_manager = OTPManager()

# Test phone number (replace with your actual phone number to receive SMS)
test_phone = "+13203968843"  # Replace with your phone number
test_email = "test@example.com"

print(f"\n📱 Test Phone Number: {test_phone}")
print(f"📧 Test Email: {test_email}")

# Generate OTP
print("\n🔢 Generating OTP...")
otp = otp_manager.generate_otp()
print(f"✅ Generated OTP: {otp}")

# Send OTP via SMS
print(f"\n📤 Sending OTP via SMS to {test_phone}...")
success = SMSGateway.send_otp(test_phone, otp)

if success:
    print("✅ SMS sent successfully!")
    print(f"💬 Check your phone {test_phone} for the OTP")
else:
    print("❌ Failed to send SMS")
    print("💡 Check the console output above for error details")

print("\n" + "=" * 60)
print("🏁 TEST COMPLETE")
print("=" * 60)
