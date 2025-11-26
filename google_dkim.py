#!/usr/bin/env python3
"""
Google Workspace Admin API - Get/Generate DKIM Keys
Then adds to Cloudflare DNS via API
"""

import os
import sys
import json
import subprocess
from typing import Optional, Dict, Any

try:
    import google.auth
    from google.oauth2 import service_account
    from googleapiclient.discovery import build
    from googleapiclient.errors import HttpError
except ImportError:
    print("Error: Google API libraries not installed")
    print("Install with: pip install --user google-auth google-api-python-client")
    sys.exit(1)

DOMAIN = os.getenv("DOMAIN", "fedlin.com")
SELECTOR = os.getenv("DKIM_SELECTOR", "google")
CUSTOMER_ID = os.getenv("GOOGLE_CUSTOMER_ID", "my_customer")
ADMIN_EMAIL = os.getenv("GOOGLE_ADMIN_EMAIL", "")
GCP_PROJECT = os.getenv("GCP_PROJECT", os.getenv("GOOGLE_CLOUD_PROJECT", "fedlin"))


def get_credentials():
    """Get Google API credentials via OAuth (preferred) or service account"""
    scopes = ['https://www.googleapis.com/auth/admin.directory.domain']
    
    # Set GCP project if specified
    if GCP_PROJECT and GCP_PROJECT != "fedlin":
        import subprocess
        try:
            subprocess.run(['gcloud', 'config', 'set', 'project', GCP_PROJECT], 
                         check=False, capture_output=True)
        except:
            pass
    
    # Try to use default credentials first (OAuth via gcloud application-default)
    try:
        credentials, project = google.auth.default(scopes=scopes)
        print(f"✓ Using OAuth credentials (project: {project})")
        
        # OAuth credentials don't need delegation - they're already for the user
        return credentials
    except Exception as e:
        print(f"OAuth credentials not available: {e}")
        print("Trying service account fallback...")
    
    # Fall back to service account file (if provided)
    creds_file = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    
    if not creds_file:
        print("Error: No Google credentials found")
        print("")
        print("For OAuth (recommended):")
        print("  Run: gcloud auth application-default login")
        print("")
        print("Or for service account:")
        print("  Set GOOGLE_APPLICATION_CREDENTIALS to service account JSON file")
        sys.exit(1)
    
    if not os.path.exists(creds_file):
        print(f"Error: Credentials file not found: {creds_file}")
        sys.exit(1)
    
    print("Using service account credentials...")
    credentials = service_account.Credentials.from_service_account_file(
        creds_file, scopes=scopes
    )
    
    # If admin email is provided, delegate to that user
    if ADMIN_EMAIL:
        credentials = credentials.with_subject(ADMIN_EMAIL)
    
    return credentials


def get_dkim_keys(service: Any, domain: str) -> Optional[Dict]:
    """Get existing DKIM keys for a domain"""
    try:
        request = service.domains().get(
            customer=CUSTOMER_ID,
            domainName=domain
        )
        response = request.execute()
        return response
    except HttpError as e:
        if e.resp.status == 404:
            print(f"Domain {domain} not found or no DKIM keys")
            return None
        print(f"Error getting DKIM keys: {e}")
        return None


def generate_dkim_key(service: Any, domain: str, selector: str) -> Optional[Dict]:
    """Generate a new DKIM key"""
    try:
        request = service.domains().generateDkimKey(
            customer=CUSTOMER_ID,
            domainName=domain,
            body={'selector': selector}
        )
        response = request.execute()
        return response
    except HttpError as e:
        print(f"Error generating DKIM key: {e}")
        if e.resp.status == 400:
            print("Note: DKIM may already exist for this selector")
        return None


def get_or_generate_dkim(domain: str, selector: str) -> Optional[str]:
    """Get existing DKIM key or generate a new one"""
    print(f"Authenticating with Google Workspace Admin API...")
    credentials = get_credentials()
    
    print(f"Building Admin SDK service...")
    service = build('admin', 'directory_v1', credentials=credentials)
    
    # Try to get existing DKIM keys
    print(f"Checking for existing DKIM keys for {domain}...")
    domain_info = get_dkim_keys(service, domain)
    
    if domain_info and 'dkimKeys' in domain_info:
        dkim_keys = domain_info['dkimKeys']
        print(f"Found {len(dkim_keys)} existing DKIM key(s)")
        
        # Look for our selector
        for key in dkim_keys:
            if key.get('selector') == selector:
                public_key = key.get('publicKey')
                if public_key:
                    print(f"✓ Found existing DKIM key for selector: {selector}")
                    return public_key
        
        print(f"Selector '{selector}' not found in existing keys")
    
    # Generate new DKIM key
    print(f"Generating new DKIM key for selector: {selector}...")
    result = generate_dkim_key(service, domain, selector)
    
    if result and 'publicKey' in result:
        public_key = result['publicKey']
        print(f"✓ DKIM key generated successfully")
        return public_key
    
    print("Error: Could not get or generate DKIM key")
    return None


def add_to_cloudflare(domain: str, selector: str, dkim_txt: str) -> bool:
    """Add DKIM record to Cloudflare DNS via API"""
    script_path = os.path.join(os.path.dirname(__file__), 'cloudflare-dns.sh')
    
    if not os.path.exists(script_path):
        print("Error: cloudflare-dns.sh not found")
        return False
    
    # Check for Cloudflare credentials
    if not os.getenv("CLOUDFLARE_API_TOKEN") and not os.getenv("CLOUDFLARE_API_KEY"):
        print("Cloudflare API credentials not set")
        print("Set CLOUDFLARE_API_TOKEN or CLOUDFLARE_API_KEY + CLOUDFLARE_EMAIL")
        return False
    
    print(f"Adding DKIM record to Cloudflare DNS...")
    result = subprocess.run(
        [script_path, domain, 'add-dkim', selector, dkim_txt],
        capture_output=True,
        text=True
    )
    
    if result.returncode == 0:
        print("✓ DKIM record added to Cloudflare DNS")
        return True
    else:
        print(f"Error adding to Cloudflare: {result.stderr}")
        return False


def main():
    print("=" * 50)
    print("Google Workspace DKIM via Admin API")
    print(f"Domain: {DOMAIN}")
    print("=" * 50)
    print()
    
    # Get or generate DKIM key
    public_key = get_or_generate_dkim(DOMAIN, SELECTOR)
    
    if not public_key:
        print("Failed to get or generate DKIM key")
        sys.exit(1)
    
    # Construct DKIM TXT record
    dkim_txt = f"v=DKIM1; k=rsa; p={public_key}"
    
    print()
    print("=" * 50)
    print("DKIM Key Retrieved")
    print("=" * 50)
    print(f"Selector: {SELECTOR}")
    print(f"Public Key (first 50 chars): {public_key[:50]}...")
    print()
    print("DKIM TXT Record:")
    print(f"{dkim_txt[:100]}...")
    print()
    
    # Add to Cloudflare
    if add_to_cloudflare(DOMAIN, SELECTOR, dkim_txt):
        print()
        print("=" * 50)
        print("Success!")
        print("=" * 50)
        print("Next steps:")
        print("1. Wait 5-15 minutes for DNS propagation")
        print("2. Verify: ./verify-email-auth.sh fedlin.com")
        print("3. In Google Admin Console, enable DKIM authentication")
    else:
        print()
        print("=" * 50)
        print("DKIM Key Retrieved (not added to Cloudflare)")
        print("=" * 50)
        print("To add manually:")
        print(f"Selector: {SELECTOR}")
        print(f"Record name: {SELECTOR}._domainkey.{DOMAIN}")
        print(f"TXT Record: {dkim_txt}")
        print()
        print("Or set Cloudflare credentials and run:")
        print(f"  ./cloudflare-dns.sh {DOMAIN} add-dkim {SELECTOR} '{dkim_txt}'")


if __name__ == "__main__":
    main()

