import os
import sys
import uuid
import asyncio
import httpx
from datetime import datetime

# Add current directory to python path for module imports
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

# Import app components
from app.main import app as fastapi_app
import app.api.v1.routes.cases as cases_routes

# --- MONKEY PATCH AI AGENTS TO AVOID REQUIRING REAL API KEYS IN VERIFICATION ---
async def mock_generate_personalized_checklist(user_profile, visa_type, destination_country):
    print("   [Mock AI] Generating personalized checklist for Nandini...")
    return [
        {"type": "passport", "item_type": "mandatory", "template": "Nandini's Passport with 6+ months validity"},
        {"type": "bank_statement", "item_type": "mandatory", "template": "HDFC bank statement showing closing balance of INR 1,500,000"},
        {"type": "degree_certificate", "item_type": "mandatory", "template": "Nandini Goswami College Transcript from university"}
    ]

async def mock_run_eligibility_agent(user_profile, visa_program):
    print("   [Mock AI] Running eligibility analysis...")
    return {
        "overall_score": 92.0,
        "category": "High",
        "factors": {
            "passport_strength": 90.0,
            "financial_capacity": 95.0,
            "education_match": 95.0,
            "work_experience": 0.0,
            "language_proficiency": 90.0,
            "travel_history": 50.0
        },
        "gap_analysis": [
            {"factor": "work_experience", "severity": "low", "detail": "Student visa applicant, prior work experience is not critical."}
        ],
        "recommended_actions": [
            "Maintain current HDFC account balance until visa decision.",
            "Bring original HDFC Balance Certificate to interview."
        ],
        "explainability": "Nandini Goswami has an outstanding academic record (GPA/Transcripts) and strong financial support, making her highly eligible for the US F-1 visa. Disclaimer: This is software guidance only, not legal advice."
    }

async def mock_run_risk_agent(case_data):
    print("   [Mock AI] Running visa rejection risk assessment...")
    return {
        "risk_score": 8.5,
        "risk_category": "Low",
        "top_risk_factors": [
            {"factor": "travel_history", "contribution": 5.0, "explanation": "Fresh passport with no previous travel history."}
        ],
        "improvement_recommendations": [
            {"action": "Bring original transcripts and SEVIS fee receipt to the visa interview.", "estimated_score_reduction": 3.0}
        ],
        "disclaimer": "This is AI-generated guidance, not legal advice."
    }

# Apply the patches
cases_routes.generate_personalized_checklist = mock_generate_personalized_checklist
cases_routes.run_eligibility_agent = mock_run_eligibility_agent
cases_routes.run_risk_agent = mock_run_risk_agent

# --- DEFINE FILE PATHS FOR CANDIDATE ---
CANDIDATE_DIR = r"d:\git\visa\Document\Rupesh Bhai File\Nandini"
PASSPORT_PATH = os.path.join(CANDIDATE_DIR, "Nandini passport.PDF")
BANK_STATEMENT_PATH = os.path.join(CANDIDATE_DIR, "Nandini HDFC Bank Balance Certificate.pdf")
TRANSCRIPT_PATH = os.path.join(CANDIDATE_DIR, "Nandini Goswami College Transcript.pdf")

async def main():
    print("=" * 80)
    print("HYTECH VISA COPILOT - CANDIDATE PIPELINE VERIFICATION (ASYNC)")
    print("=" * 80)
    
    # 1. Initialize async client
    transport = httpx.ASGITransport(app=fastapi_app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        
        # 2. Register Candidate
        print("\n[Step 1] Registering Candidate 'Nandini Goswami'...")
        email = f"nandini_{uuid.uuid4().hex[:6]}@example.com"
        reg_data = {
            "email": email,
            "password": "SecurePassword123!",
            "full_name": "Nandini Goswami",
            "phone": "+919876543210",
            "nationality": "IND"
        }
        res = await client.post("/api/v1/auth/register", json=reg_data)
        assert res.status_code == 201, f"Registration failed: {res.text}"
        token_resp = res.json()
        token = token_resp["access_token"]
        user_id = token_resp["user"]["id"]
        headers = {"Authorization": f"Bearer {token}"}
        print(f" -> Success! Registered user ID: {user_id}")
        
        # 3. Update Profile details
        print("\n[Step 2] Updating Candidate Profile details...")
        profile_data = {
            "education_level": "Bachelor of Science",
            "work_years": 0,
            "language_scores": {"pte": 78},
            "financial_info": {"savings_inr": 1500000},
            "travel_history": []
        }
        res = await client.patch("/api/v1/auth/profile", json=profile_data, headers=headers)
        assert res.status_code == 200, f"Profile update failed: {res.text}"
        print(" -> Success! Profile updated with language scores and financial info.")
        
        # 4. Create Visa Case
        print("\n[Step 3] Creating Student Visa Case (USA)...")
        case_data = {
            "destination_country": "USA",
            "visa_type": "student",
            "purpose": "Master of Science in Computer Science",
            "intended_travel_date": "2026-08-15"
        }
        res = await client.post("/api/v1/cases/", json=case_data, headers=headers)
        assert res.status_code == 201, f"Case creation failed: {res.text}"
        case_resp = res.json()
        case_id = case_resp["id"]
        print(f" -> Success! Created Case ID: {case_id}")
        
        # 5. Fetch Checklist
        print("\n[Step 4] Fetching Case Checklist items...")
        res = await client.get(f"/api/v1/cases/{case_id}/checklist", headers=headers)
        assert res.status_code == 200, f"Checklist fetch failed: {res.text}"
        checklist = res.json()
        print(f" -> Found {len(checklist)} checklist items:")
        for idx, item in enumerate(checklist, 1):
            print(f"    {idx}. [{item['item_type'].upper()}] Type: {item['document_type']} - Status: {item['status']}")
            print(f"       Desc: {item['personalized_description']}")
            
        # 6. Upload Candidate Documents
        print("\n[Step 5] Uploading Candidate Documents from disk...")
        uploads = [
            {"type": "passport", "path": PASSPORT_PATH},
            {"type": "bank_statement", "path": BANK_STATEMENT_PATH},
            {"type": "degree_certificate", "path": TRANSCRIPT_PATH}
        ]
        
        for upload in uploads:
            doc_type = upload["type"]
            path = upload["path"]
            print(f"  - Uploading {doc_type} from {path}...")
            
            if not os.path.exists(path):
                print(f"    [Warning] File not found at {path}! Creating a dummy file for simulation...")
                os.makedirs(os.path.dirname(path), exist_ok=True)
                with open(path, "w") as f:
                    f.write("dummy document contents for simulation")
                    
            with open(path, "rb") as f:
                # Use standard file upload format for httpx
                files = {"file": (os.path.basename(path), f, "application/pdf")}
                data = {
                    "case_id": case_id,
                    "document_type": doc_type,
                    "intended_travel_date": "2026-08-15"
                }
                res = await client.post("/api/v1/documents/upload", data=data, files=files, headers=headers)
                assert res.status_code == 201, f"Upload failed for {doc_type}: {res.text}"
                doc_resp = res.json()
                print(f"    -> Success! Document ID: {doc_resp['id']}, Status: {doc_resp['status']}, Health Score: {doc_resp['health_score']}")
                if doc_resp["validation_flags"] and doc_resp["validation_flags"].get("flags"):
                    print(f"       Flags: {doc_resp['validation_flags']['flags']}")
                if doc_resp["suggested_fixes"]:
                    print(f"       Suggested Fixes: {doc_resp['suggested_fixes']}")
                    
        # 7. Check Updated Case
        print("\n[Step 6] Verifying updated Case readiness score and status...")
        res = await client.get(f"/api/v1/cases/{case_id}", headers=headers)
        assert res.status_code == 200, f"Case fetch failed: {res.text}"
        case_updated = res.json()
        print(f" -> Case Status: {case_updated['status']}")
        print(f" -> Readiness Score: {case_updated['readiness_score']}%")
        
        # 8. Run AI Eligibility Agent
        print("\n[Step 7] Running AI Eligibility Assessment...")
        res = await client.post(f"/api/v1/cases/{case_id}/eligibility", headers=headers)
        assert res.status_code == 200, f"Eligibility check failed: {res.text}"
        el_resp = res.json()
        print(f" -> Overall Eligibility Score: {el_resp['overall_score']}")
        print(f" -> Category: {el_resp['category']}")
        print(f" -> Recommended Actions:")
        for action in el_resp["recommended_actions"]:
            print(f"    - {action}")
        print(f" -> Explainability (AI summary): {el_resp['explainability']}")
        
        # 9. Run AI Risk Agent
        print("\n[Step 8] Running AI Visa Rejection Risk Analysis...")
        res = await client.post(f"/api/v1/cases/{case_id}/risk", headers=headers)
        assert res.status_code == 200, f"Risk check failed: {res.text}"
        risk_resp = res.json()
        print(f" -> Rejection Risk Score: {risk_resp['risk_score']}%")
        print(f" -> Risk Category: {risk_resp['risk_category']}")
        print(f" -> Top Risk Factors:")
        for f in risk_resp["top_risk_factors"]:
            print(f"    - {f['factor']} (Contribution: {f['contribution']}%): {f['explanation']}")
        print(f" -> Improvement Recommendations:")
        for rec in risk_resp["improvement_recommendations"]:
            print(f"    - Action: {rec['action']} (Est reduction: {rec['estimated_score_reduction']}%)")
            
        print("\n" + "=" * 80)
        print("CANDIDATE PIPELINE VERIFICATION COMPLETED SUCCESSFULLY!")
        print("=" * 80)

if __name__ == "__main__":
    asyncio.run(main())
