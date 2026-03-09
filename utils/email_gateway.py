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
            subject = "🔐 Password Reset OTP - Smart Farming Assistant"
            html_content = f"""
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                    * {{ margin: 0; padding: 0; box-sizing: border-box; }}
                    body {{ 
                        font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
                        line-height: 1.6; 
                        color: #2c3e50;
                        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                        padding: 40px 20px;
                    }}
                    .email-wrapper {{ 
                        max-width: 600px; 
                        margin: 0 auto; 
                        background: #ffffff;
                        border-radius: 16px;
                        overflow: hidden;
                        box-shadow: 0 20px 60px rgba(0,0,0,0.3);
                    }}
                    .header {{ 
                        background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
                        padding: 40px 30px;
                        text-align: center;
                    }}
                    .header-icon {{
                        width: 80px;
                        height: 80px;
                        background: rgba(255,255,255,0.2);
                        border-radius: 50%;
                        display: inline-flex;
                        align-items: center;
                        justify-content: center;
                        font-size: 40px;
                        margin-bottom: 15px;
                    }}
                    .header h1 {{ 
                        color: #ffffff; 
                        font-size: 28px;
                        font-weight: 600;
                        margin: 0;
                        text-shadow: 0 2px 4px rgba(0,0,0,0.1);
                    }}
                    .content {{ 
                        padding: 40px 30px;
                        background: #ffffff;
                    }}
                    .greeting {{
                        font-size: 18px;
                        color: #2c3e50;
                        margin-bottom: 20px;
                        font-weight: 500;
                    }}
                    .message {{
                        font-size: 15px;
                        color: #5a6c7d;
                        margin-bottom: 30px;
                        line-height: 1.8;
                    }}
                    .otp-container {{
                        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                        border-radius: 12px;
                        padding: 30px;
                        text-align: center;
                        margin: 30px 0;
                        box-shadow: 0 8px 24px rgba(102, 126, 234, 0.3);
                    }}
                    .otp-label {{
                        color: rgba(255,255,255,0.9);
                        font-size: 13px;
                        font-weight: 600;
                        letter-spacing: 1px;
                        text-transform: uppercase;
                        margin-bottom: 15px;
                    }}
                    .otp-code {{ 
                        background: #ffffff;
                        color: #667eea;
                        padding: 20px 30px;
                        border-radius: 8px;
                        font-size: 36px;
                        font-weight: 700;
                        letter-spacing: 8px;
                        display: inline-block;
                        font-family: 'Courier New', monospace;
                        box-shadow: inset 0 2px 4px rgba(0,0,0,0.1);
                    }}
                    .validity {{
                        background: #fff3cd;
                        border-left: 4px solid #ffc107;
                        padding: 15px 20px;
                        border-radius: 8px;
                        margin: 25px 0;
                        font-size: 14px;
                        color: #856404;
                    }}
                    .validity strong {{
                        display: block;
                        margin-bottom: 5px;
                        font-size: 15px;
                    }}
                    .warning-box {{ 
                        background: #ffe5e5;
                        border-left: 4px solid #dc3545;
                        padding: 15px 20px;
                        border-radius: 8px;
                        margin: 20px 0;
                    }}
                    .warning-box p {{
                        color: #842029;
                        font-size: 14px;
                        margin: 0;
                    }}
                    .warning-icon {{
                        font-size: 20px;
                        margin-right: 8px;
                    }}
                    .footer-note {{
                        color: #6c757d;
                        font-size: 14px;
                        margin-top: 30px;
                        padding-top: 20px;
                        border-top: 2px solid #e9ecef;
                    }}
                    .signature {{
                        margin-top: 30px;
                        font-size: 15px;
                        color: #495057;
                    }}
                    .signature strong {{
                        color: #667eea;
                        display: block;
                        font-size: 16px;
                    }}
                    .footer {{ 
                        background: #f8f9fa;
                        padding: 25px 30px;
                        text-align: center;
                        border-top: 1px solid #e9ecef;
                    }}
                    .footer p {{
                        color: #6c757d;
                        font-size: 13px;
                        margin: 5px 0;
                    }}
                    .footer-links {{
                        margin-top: 15px;
                    }}
                    .footer-links a {{
                        color: #667eea;
                        text-decoration: none;
                        margin: 0 10px;
                        font-size: 12px;
                    }}
                </style>
            </head>
            <body>
                <div class="email-wrapper">
                    <div class="header">
                        <div class="header-icon">🔐</div>
                        <h1>Password Reset Request</h1>
                    </div>
                    <div class="content">
                        <p class="greeting">Hello, Farmer! 👨‍🌾</p>
                        <p class="message">
                            We received a request to reset your password for your Smart Farming Assistant account. 
                            To proceed with resetting your password, please use the One-Time Password (OTP) below:
                        </p>
                        
                        <div class="otp-container">
                            <div class="otp-label">Your One-Time Password</div>
                            <div class="otp-code">{otp}</div>
                        </div>
                        
                        <div class="validity">
                            <strong>⏰ Valid for 5 minutes only</strong>
                            This OTP will expire in 5 minutes for security reasons. Please use it promptly.
                        </div>
                        
                        <div class="warning-box">
                            <p><span class="warning-icon">⚠️</span><strong>Security Notice:</strong> Never share this OTP with anyone, including Smart Farming Assistant staff. We will never ask for your OTP.</p>
                        </div>
                        
                        <p class="footer-note">
                            If you didn't request this password reset, please ignore this email and your password will remain unchanged. 
                            For added security, we recommend changing your password regularly.
                        </p>
                        
                        <div class="signature">
                            Best regards,<br>
                            <strong>Smart Farming Assistant Team</strong>
                        </div>
                    </div>
                    <div class="footer">
                        <p>© 2026 Smart Farming Assistant. All rights reserved.</p>
                        <p>This is an automated message. Please do not reply to this email.</p>
                        <div class="footer-links">
                            <a href="#">Help Center</a> • 
                            <a href="#">Privacy Policy</a> • 
                            <a href="#">Terms of Service</a>
                        </div>
                    </div>
                </div>
            </body>
            </html>
            """
        else:  # verification
            subject = "✅ Email Verification OTP - Smart Farming Assistant"
            html_content = f"""
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                    * {{ margin: 0; padding: 0; box-sizing: border-box; }}
                    body {{ 
                        font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
                        line-height: 1.6; 
                        color: #2c3e50;
                        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                        padding: 40px 20px;
                    }}
                    .email-wrapper {{ 
                        max-width: 600px; 
                        margin: 0 auto; 
                        background: #ffffff;
                        border-radius: 16px;
                        overflow: hidden;
                        box-shadow: 0 20px 60px rgba(0,0,0,0.3);
                    }}
                    .header {{ 
                        background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
                        padding: 40px 30px;
                        text-align: center;
                    }}
                    .header-icon {{
                        width: 80px;
                        height: 80px;
                        background: rgba(255,255,255,0.2);
                        border-radius: 50%;
                        display: inline-flex;
                        align-items: center;
                        justify-content: center;
                        font-size: 40px;
                        margin-bottom: 15px;
                    }}
                    .header h1 {{ 
                        color: #ffffff; 
                        font-size: 28px;
                        font-weight: 600;
                        margin: 0;
                        text-shadow: 0 2px 4px rgba(0,0,0,0.1);
                    }}
                    .header p {{
                        color: rgba(255,255,255,0.95);
                        font-size: 16px;
                        margin-top: 10px;
                    }}
                    .content {{ 
                        padding: 40px 30px;
                        background: #ffffff;
                    }}
                    .greeting {{
                        font-size: 18px;
                        color: #2c3e50;
                        margin-bottom: 20px;
                        font-weight: 500;
                    }}
                    .message {{
                        font-size: 15px;
                        color: #5a6c7d;
                        margin-bottom: 30px;
                        line-height: 1.8;
                    }}
                    .otp-container {{
                        background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
                        border-radius: 12px;
                        padding: 30px;
                        text-align: center;
                        margin: 30px 0;
                        box-shadow: 0 8px 24px rgba(79, 172, 254, 0.3);
                    }}
                    .otp-label {{
                        color: rgba(255,255,255,0.9);
                        font-size: 13px;
                        font-weight: 600;
                        letter-spacing: 1px;
                        text-transform: uppercase;
                        margin-bottom: 15px;
                    }}
                    .otp-code {{ 
                        background: #ffffff;
                        color: #4facfe;
                        padding: 20px 30px;
                        border-radius: 8px;
                        font-size: 36px;
                        font-weight: 700;
                        letter-spacing: 8px;
                        display: inline-block;
                        font-family: 'Courier New', monospace;
                        box-shadow: inset 0 2px 4px rgba(0,0,0,0.1);
                    }}
                    .validity {{
                        background: #fff3cd;
                        border-left: 4px solid #ffc107;
                        padding: 15px 20px;
                        border-radius: 8px;
                        margin: 25px 0;
                        font-size: 14px;
                        color: #856404;
                    }}
                    .validity strong {{
                        display: block;
                        margin-bottom: 5px;
                        font-size: 15px;
                    }}
                    .warning-box {{ 
                        background: #ffe5e5;
                        border-left: 4px solid #dc3545;
                        padding: 15px 20px;
                        border-radius: 8px;
                        margin: 20px 0;
                    }}
                    .warning-box p {{
                        color: #842029;
                        font-size: 14px;
                        margin: 0;
                    }}
                    .warning-icon {{
                        font-size: 20px;
                        margin-right: 8px;
                    }}
                    .features {{
                        background: #f8f9fa;
                        border-radius: 8px;
                        padding: 20px;
                        margin: 25px 0;
                    }}
                    .features h3 {{
                        color: #4facfe;
                        font-size: 16px;
                        margin-bottom: 15px;
                    }}
                    .feature-list {{
                        list-style: none;
                        padding: 0;
                    }}
                    .feature-list li {{
                        padding: 8px 0;
                        color: #5a6c7d;
                        font-size: 14px;
                    }}
                    .feature-list li:before {{
                        content: "✓ ";
                        color: #28a745;
                        font-weight: bold;
                        margin-right: 8px;
                    }}
                    .footer-note {{
                        color: #6c757d;
                        font-size: 14px;
                        margin-top: 30px;
                        padding-top: 20px;
                        border-top: 2px solid #e9ecef;
                    }}
                    .signature {{
                        margin-top: 30px;
                        font-size: 15px;
                        color: #495057;
                    }}
                    .signature strong {{
                        color: #4facfe;
                        display: block;
                        font-size: 16px;
                    }}
                    .footer {{ 
                        background: #f8f9fa;
                        padding: 25px 30px;
                        text-align: center;
                        border-top: 1px solid #e9ecef;
                    }}
                    .footer p {{
                        color: #6c757d;
                        font-size: 13px;
                        margin: 5px 0;
                    }}
                    .footer-links {{
                        margin-top: 15px;
                    }}
                    .footer-links a {{
                        color: #4facfe;
                        text-decoration: none;
                        margin: 0 10px;
                        font-size: 12px;
                    }}
                </style>
            </head>
            <body>
                <div class="email-wrapper">
                    <div class="header">
                        <div class="header-icon">🌾</div>
                        <h1>Welcome to Smart Farming!</h1>
                        <p>Let's verify your email address</p>
                    </div>
                    <div class="content">
                        <p class="greeting">Hello, Future Farmer! 👋</p>
                        <p class="message">
                            Thank you for joining Smart Farming Assistant! We're excited to have you on board. 
                            To complete your registration and unlock all features, please verify your email address using the OTP below:
                        </p>
                        
                        <div class="otp-container">
                            <div class="otp-label">Your Verification Code</div>
                            <div class="otp-code">{otp}</div>
                        </div>
                        
                        <div class="validity">
                            <strong>⏰ Valid for 5 minutes only</strong>
                            This OTP will expire in 5 minutes for security reasons. Please complete verification promptly.
                        </div>
                        
                        <div class="warning-box">
                            <p><span class="warning-icon">⚠️</span><strong>Security Notice:</strong> Never share this OTP with anyone. We will never ask for your verification code.</p>
                        </div>
                        
                        <div class="features">
                            <h3>What's waiting for you:</h3>
                            <ul class="feature-list">
                                <li>Crop recommendations based on soil and weather</li>
                                <li>Market price tracking and insights</li>
                                <li>Equipment sharing marketplace</li>
                                <li>Growing activity management</li>
                                <li>AI-powered farming assistant</li>
                            </ul>
                        </div>
                        
                        <p class="footer-note">
                            If you didn't create an account with Smart Farming Assistant, please ignore this email and no account will be created.
                        </p>
                        
                        <div class="signature">
                            Best regards,<br>
                            <strong>Smart Farming Assistant Team</strong>
                        </div>
                    </div>
                    <div class="footer">
                        <p>© 2026 Smart Farming Assistant. All rights reserved.</p>
                        <p>Empowering farmers with smart technology for better yields</p>
                        <div class="footer-links">
                            <a href="#">Help Center</a> • 
                            <a href="#">Privacy Policy</a> • 
                            <a href="#">Terms of Service</a>
                        </div>
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
