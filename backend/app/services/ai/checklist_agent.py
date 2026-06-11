from openai import AsyncOpenAI
from app.core.config import settings
import json

# Dynamically choose between Groq and OpenAI
if settings.GROQ_API_KEY:
    client = AsyncOpenAI(api_key=settings.GROQ_API_KEY, base_url=settings.GROQ_API_BASE)
    MODEL_NAME = settings.GROQ_MODEL
else:
    client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)
    MODEL_NAME = settings.OPENAI_MODEL

REQUIRED_DOCUMENTS = {
    "student": [
        {"type": "passport", "item_type": "mandatory", "template": "Valid passport with at least 6 months validity beyond your intended course end date"},
        {"type": "admission_letter", "item_type": "mandatory", "template": "Official admission/offer letter from the university on letterhead"},
        {"type": "degree_certificate", "item_type": "mandatory", "template": "Previous academic transcripts and degree certificates"},
        {"type": "bank_statement", "item_type": "mandatory", "template": "Bank statements for the last 6 months showing sufficient funds for tuition + living costs"},
        {"type": "language_score_card", "item_type": "mandatory", "template": "IELTS/TOEFL/Duolingo score report (must be within 2 years)"},
        {"type": "photo", "item_type": "mandatory", "template": "Recent passport-size photograph (white background, 35x45mm)"},
        {"type": "travel_insurance", "item_type": "recommended", "template": "Travel/health insurance valid for duration of stay"},
        {"type": "police_clearance", "item_type": "conditional", "template": "Police clearance certificate (required if staying > 6 months)"},
    ],
    "work": [
        {"type": "passport", "item_type": "mandatory", "template": "Valid passport"},
        {"type": "employment_letter", "item_type": "mandatory", "template": "Employment letter from sponsoring company on company letterhead with salary, role, and start date"},
        {"type": "degree_certificate", "item_type": "mandatory", "template": "Highest qualification certificate"},
        {"type": "bank_statement", "item_type": "mandatory", "template": "Last 3 months bank statements"},
        {"type": "tax_return", "item_type": "mandatory", "template": "Last 2 years income tax returns"},
        {"type": "photo", "item_type": "mandatory", "template": "Passport-size photograph"},
        {"type": "medical_certificate", "item_type": "conditional", "template": "Medical fitness certificate from approved physician"},
        {"type": "police_clearance", "item_type": "mandatory", "template": "Police clearance certificate from home country"},
    ],
    "tourist": [
        {"type": "passport", "item_type": "mandatory", "template": "Passport valid for at least 6 months from return date"},
        {"type": "bank_statement", "item_type": "mandatory", "template": "3 months bank statements showing travel funds"},
        {"type": "photo", "item_type": "mandatory", "template": "Passport-size photograph"},
        {"type": "travel_insurance", "item_type": "mandatory", "template": "Travel insurance covering medical and repatriation"},
        {"type": "invitation_letter", "item_type": "conditional", "template": "Invitation letter from host (if visiting family/friends)"},
    ],
    "family": [
        {"type": "passport", "item_type": "mandatory", "template": "Passport of applicant"},
        {"type": "bank_statement", "item_type": "mandatory", "template": "Bank statements of sponsor"},
        {"type": "photo", "item_type": "mandatory", "template": "Passport-size photograph"},
        {"type": "invitation_letter", "item_type": "mandatory", "template": "Sponsor's invitation letter + proof of relationship"},
        {"type": "employment_letter", "item_type": "conditional", "template": "Sponsor's employment letter or proof of income"},
    ],
}


async def generate_personalized_checklist(user_profile: dict, visa_type: str, destination_country: str) -> list:
    base_items = REQUIRED_DOCUMENTS.get(visa_type, REQUIRED_DOCUMENTS["tourist"])

    prompt = f"""
Personalize each checklist item for this user:
User: {json.dumps(user_profile, indent=2)}
Destination: {destination_country}
Visa Type: {visa_type}
Base items: {json.dumps(base_items, indent=2)}

For each item, make the description specific to this user's situation.
Include exact thresholds (e.g., minimum balance = {destination_country} cost of living estimate).
Respond with JSON array of checklist items preserving all fields but updating template text.
"""

    response = await client.chat.completions.create(
        model=MODEL_NAME,
        messages=[{"role": "user", "content": prompt}],
        response_format={"type": "json_object"},
        temperature=0.3,
    )
    result = json.loads(response.choices[0].message.content)
    return result.get("items", base_items)
