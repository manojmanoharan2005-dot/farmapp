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
        
        print(f"[DEBUG] EmailGateway.send_otp_email: to={to_email}, purpose={purpose}")
        # Prepare email content based on purpose
        if purpose == "reset":
            subject = "Password Reset Request - Smart Farming Assistant"
            html_content = f"""
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="utf-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                    body {{
                        font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
                        background-color: #f9fafb;
                        margin: 0;
                        padding: 0;
                        -webkit-font-smoothing: antialiased;
                    }}
                    .container {{
                        max-width: 600px;
                        margin: 40px auto;
                        background-color: #ffffff;
                        border-radius: 8px;
                        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
                        overflow: hidden;
                        border: 1px solid #e5e7eb;
                    }}
                    .header {{
                        background-color: #111827;
                        padding: 32px;
                        text-align: center;
                    }}
                    .header h1 {{
                        color: #ffffff;
                        font-size: 24px;
                        font-weight: 700;
                        margin: 0;
                        letter-spacing: -0.025em;
                    }}
                    .content {{
                        padding: 48px;
                    }}
                    .greeting {{
                        font-size: 18px;
                        font-weight: 600;
                        color: #111827;
                        margin-bottom: 16px;
                    }}
                    .message {{
                        font-size: 16px;
                        color: #4b5563;
                        line-height: 1.6;
                        margin-bottom: 32px;
                    }}
                    .otp-box {{
                        background-color: #f3f4f6;
                        border-radius: 12px;
                        padding: 40px;
                        text-align: center;
                        margin: 32px 0;
                        border: 2px dashed #d1d5db;
                    }}
                    .otp-label {{
                        display: block;
                        font-size: 14px;
                        font-weight: 600;
                        color: #6b7280;
                        text-transform: uppercase;
                        letter-spacing: 0.05em;
                        margin-bottom: 16px;
                    }}
                    .otp-code {{
                        font-size: 42px;
                        font-weight: 800;
                        color: #111827;
                        letter-spacing: 12px;
                        font-family: 'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, monospace;
                    }}
                    .validity {{
                        font-size: 14px;
                        color: #92400e;
                        background-color: #fffbeb;
                        padding: 12px 16px;
                        border-radius: 6px;
                        border-left: 4px solid #f59e0b;
                        margin-bottom: 32px;
                    }}
                    .security-notice {{
                        font-size: 13px;
                        color: #6b7280;
                        border-top: 1px solid #f3f4f6;
                        padding-top: 24px;
                        line-height: 1.5;
                    }}
                    .footer {{
                        padding: 32px;
                        background-color: #f9fafb;
                        text-align: center;
                        border-top: 1px solid #e5e7eb;
                    }}
                    .footer p {{
                        font-size: 12px;
                        color: #9ca3af;
                        margin: 4px 0;
                    }}
                    .footer a {{
                        color: #111827;
                        text-decoration: underline;
                    }}
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <h1>Smart Farming Assistant</h1>
                    </div>
                    <div class="content">
                        <p class="greeting">Password Reset Request</p>
                        <p class="message">
                            We received a request to reset the password for your account. To proceed with the reset process, please use the following one-time verification code. This code is unique to this request and will expire shortly.
                        </p>
                        
                        <div class="otp-box">
                            <span class="otp-label">Verification Code</span>
                            <div class="otp-code">{otp}</div>
                        </div>
                        
                        <div class="validity">
                            This code is valid for <strong>5 minutes</strong>. If you did not request a password reset, you can safely ignore this email.
                        </div>
                        
                        <div class="security-notice">
                            <strong>Security Reminder:</strong> Our team will never ask you for this code or your password over email or phone. Please keep your account details confidential.
                        </div>
                    </div>
                    <div class="footer">
                        <p>&copy; 2026 Smart Farming Assistant Inc. All rights reserved.</p>
                        <p>123 Agri-Tech Square, Bangalore, KA, India</p>
                        <p>
                            <a href="#">Security Center</a> &bull; 
                            <a href="#">Privacy Policy</a> &bull; 
                            <a href="#">Terms of Service</a>
                        </p>
                    </div>
                </div>
            </body>
            </html>
            """
        else:  # verification
            subject = "Verify Your Account - Smart Farming Assistant"
            html_content = f"""
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="utf-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                    body {{
                        font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
                        background-color: #f9fafb;
                        margin: 0;
                        padding: 0;
                        -webkit-font-smoothing: antialiased;
                    }}
                    .container {{
                        max-width: 600px;
                        margin: 40px auto;
                        background-color: #ffffff;
                        border-radius: 8px;
                        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
                        overflow: hidden;
                        border: 1px solid #e5e7eb;
                    }}
                    .header {{
                        background-color: #166534;
                        padding: 32px;
                        text-align: center;
                    }}
                    .header h1 {{
                        color: #ffffff;
                        font-size: 24px;
                        font-weight: 700;
                        margin: 0;
                        letter-spacing: -0.025em;
                    }}
                    .content {{
                        padding: 48px;
                    }}
                    .greeting {{
                        font-size: 22px;
                        font-weight: 700;
                        color: #111827;
                        margin-bottom: 24px;
                        letter-spacing: -0.02em;
                    }}
                    .message {{
                        font-size: 16px;
                        color: #4b5563;
                        line-height: 1.6;
                        margin-bottom: 32px;
                    }}
                    .otp-box {{
                        background-color: #f0fdf4;
                        border-radius: 12px;
                        padding: 40px;
                        text-align: center;
                        margin: 32px 0;
                        border: 2px solid #bbf7d0;
                    }}
                    .otp-label {{
                        display: block;
                        font-size: 14px;
                        font-weight: 600;
                        color: #166534;
                        text-transform: uppercase;
                        letter-spacing: 0.05em;
                        margin-bottom: 16px;
                    }}
                    .otp-code {{
                        font-size: 42px;
                        font-weight: 800;
                        color: #111827;
                        letter-spacing: 12px;
                        font-family: 'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, monospace;
                    }}
                    .validity {{
                        font-size: 14px;
                        color: #166534;
                        background-color: #f0fdf4;
                        padding: 12px 16px;
                        border-radius: 6px;
                        border-left: 4px solid #22c55e;
                        margin-bottom: 32px;
                    }}
                    .features-grid {{
                        display: grid;
                        grid-template-columns: 1fr 1fr;
                        gap: 16px;
                        margin: 32px 0;
                        padding: 24px;
                        background-color: #f9fafb;
                        border-radius: 12px;
                    }}
                    .feature-item {{
                        font-size: 14px;
                        color: #4b5563;
                        display: flex;
                        align-items: center;
                    }}
                    .feature-bullet {{
                        color: #22c55e;
                        margin-right: 8px;
                        font-weight: bold;
                    }}
                    .footer {{
                        padding: 32px;
                        background-color: #f9fafb;
                        text-align: center;
                        border-top: 1px solid #e5e7eb;
                    }}
                    .footer p {{
                        font-size: 12px;
                        color: #9ca3af;
                        margin: 4px 0;
                    }}
                    .footer a {{
                        color: #111827;
                        text-decoration: underline;
                    }}
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <h1>Smart Farming Assistant</h1>
                    </div>
                    <div class="content">
                        <p class="greeting">Welcome to the Platform</p>
                        <p class="message">
                            Thank you for joining Smart Farming Assistant. To get started and secure your account, please verify your email address by entering the verification code provided below.
                        </p>
                        
                        <div class="otp-box">
                            <span class="otp-label">Your Verification Code</span>
                            <div class="otp-code">{otp}</div>
                        </div>
                        
                        <div class="validity">
                            This code is valid for <strong>5 minutes</strong>. If the code expires, you can request a new one from the registration page.
                        </div>

                        <p class="message" style="margin-bottom: 8px;"><strong>As a verified member, you can now access:</strong></p>
                        <div class="features-grid">
                            <div class="feature-item"><span class="feature-bullet">&bull;</span> Crop Recommendations</div>
                            <div class="feature-item"><span class="feature-bullet">&bull;</span> Market Price Tracking</div>
                            <div class="feature-item"><span class="feature-bullet">&bull;</span> Equipment Marketplace</div>
                            <div class="feature-item"><span class="feature-bullet">&bull;</span> Activity Management</div>
                        </div>
                    </div>
                    <div class="footer">
                        <p>&copy; 2026 Smart Farming Assistant Inc. All rights reserved.</p>
                        <p>123 Agri-Tech Square, Bangalore, KA, India</p>
                        <p>
                            <a href="#">Help Center</a> &bull; 
                            <a href="#">Privacy Policy</a> &bull; 
                            <a href="#">Terms of Service</a>
                        </p>
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
