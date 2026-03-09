"""
Email Gateway Integration for OTP Delivery
Uses Brevo (formerly Sendinblue) for sending emails
"""
import os
from typing import Tuple
import sib_api_v3_sdk
from sib_api_v3_sdk.rest import ApiException


class EmailGateway:
    """Handle Email sending via Brevo (Sendinblue)"""
    
    @staticmethod
    def send_otp_email(to_email: str, otp: str, purpose: str = "verification") -> Tuple[bool, str]:
        """
        Send OTP via Brevo Email
        Args:
            to_email: Recipient email address
            otp: OTP code to send
            purpose: Either 'verification' (registration) or 'reset' (password reset)
        Returns:
            (success, message)
        """
        api_key = os.environ.get('BREVO_API_KEY')
        sender_email = os.environ.get('BREVO_SENDER_EMAIL', 'noreply@smartfarming.com')
        sender_name = os.environ.get('BREVO_SENDER_NAME', 'Smart Farming Assistant')
        
        if not api_key or 'your_' in api_key:
            # Development mode - print OTP to console
            print(f"[DEV MODE] Email OTP for {to_email}: {otp}")
            return True, "OTP generated (email not sent - dev mode)"
        
        # Configure Brevo API
        configuration = sib_api_v3_sdk.Configuration()
        configuration.api_key['api-key'] = api_key
        
        api_instance = sib_api_v3_sdk.TransactionalEmailsApi(sib_api_v3_sdk.ApiClient(configuration))
        
        # Prepare email content based on purpose
        if purpose == "reset":
            subject = "Password Reset OTP - Smart Farming Assistant"
            html_content = f"""
            <!DOCTYPE html>
            <html>
            <head>
                <style>
                    body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                    .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                    .header {{ background-color: #4CAF50; color: white; padding: 20px; text-align: center; border-radius: 5px 5px 0 0; }}
                    .content {{ background-color: #f9f9f9; padding: 30px; border-radius: 0 0 5px 5px; }}
                    .otp-box {{ background-color: #fff; border: 2px dashed #4CAF50; padding: 20px; text-align: center; margin: 20px 0; font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #4CAF50; }}
                    .footer {{ text-align: center; margin-top: 20px; font-size: 12px; color: #666; }}
                    .warning {{ color: #d32f2f; font-weight: bold; }}
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <h1>🌾 Password Reset Request</h1>
                    </div>
                    <div class="content">
                        <p>Hello Farmer,</p>
                        <p>You requested to reset your password. Use the OTP below to proceed:</p>
                        <div class="otp-box">{otp}</div>
                        <p><strong>This OTP is valid for 5 minutes.</strong></p>
                        <p class="warning">⚠️ Never share this code with anyone!</p>
                        <p>If you didn't request this password reset, please ignore this email and your password will remain unchanged.</p>
                        <p>Best regards,<br>Smart Farming Assistant Team</p>
                    </div>
                    <div class="footer">
                        <p>This is an automated message, please do not reply.</p>
                    </div>
                </div>
            </body>
            </html>
            """
        else:  # verification
            subject = "Email Verification OTP - Smart Farming Assistant"
            html_content = f"""
            <!DOCTYPE html>
            <html>
            <head>
                <style>
                    body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                    .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                    .header {{ background-color: #2196F3; color: white; padding: 20px; text-align: center; border-radius: 5px 5px 0 0; }}
                    .content {{ background-color: #f9f9f9; padding: 30px; border-radius: 0 0 5px 5px; }}
                    .otp-box {{ background-color: #fff; border: 2px dashed #2196F3; padding: 20px; text-align: center; margin: 20px 0; font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #2196F3; }}
                    .footer {{ text-align: center; margin-top: 20px; font-size: 12px; color: #666; }}
                    .warning {{ color: #d32f2f; font-weight: bold; }}
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <h1>🌾 Welcome to Smart Farming Assistant!</h1>
                    </div>
                    <div class="content">
                        <p>Hello,</p>
                        <p>Thank you for registering! Please verify your email address using the OTP below:</p>
                        <div class="otp-box">{otp}</div>
                        <p><strong>This OTP is valid for 5 minutes.</strong></p>
                        <p class="warning">⚠️ Never share this code with anyone!</p>
                        <p>If you didn't create an account with us, please ignore this email.</p>
                        <p>Best regards,<br>Smart Farming Assistant Team</p>
                    </div>
                    <div class="footer">
                        <p>This is an automated message, please do not reply.</p>
                    </div>
                </div>
            </body>
            </html>
            """
        
        # Create SendSmtpEmail object
        send_smtp_email = sib_api_v3_sdk.SendSmtpEmail(
            to=[{"email": to_email}],
            sender={"name": sender_name, "email": sender_email},
            subject=subject,
            html_content=html_content,
            text_content=f"Your OTP is: {otp}. Valid for 5 minutes. Do not share this code with anyone."
        )
        
        try:
            print(f"[Brevo] Sending OTP email to {to_email}...")
            api_response = api_instance.send_transac_email(send_smtp_email)
            print(f"[Brevo] Response: {api_response}")
            
            if api_response.message_id:
                return True, "OTP sent successfully to your email"
            else:
                return False, "Failed to send OTP email"
                
        except ApiException as e:
            error_msg = f"Brevo API Error: {e}"
            print(f"[Brevo Error] {error_msg}")
            return False, error_msg
            
        except Exception as e:
            error_msg = f"Email service error: {str(e)}"
            print(f"[Email Exception] {error_msg}")
            return False, error_msg
    
    @staticmethod
    def send_otp(email: str, otp: str, purpose: str = "verification") -> Tuple[bool, str]:
        """
        Wrapper method to maintain compatibility with existing code
        """
        return EmailGateway.send_otp_email(email, otp, purpose)
