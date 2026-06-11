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

SYSTEM_PROMPT = """
You are the Eligibility Agent for HyTech Visa Copilot.
Given a user's profile and target visa program, you must:
1. Score their eligibility from 0-100
2. Identify gaps with severity (critical/high/medium/low)
3. Suggest specific next actions
4. Explain your reasoning in plain language

IMPORTANT: You are an AI assistant providing software guidance only.
This is NOT legal advice. Always include this disclaimer in your explainability text.

Respond ONLY with valid JSON matching this schema:
{
  "overall_score": float,
  "category": "Low|Medium|High|Critical",
  "factors": {
    "passport_strength": float,
    "financial_capacity": float,
    "education_match": float,
    "work_experience": float,
    "language_proficiency": float,
    "travel_history": float
  },
  "gap_analysis": [
    {"factor": str, "severity": str, "detail": str}
  ],
  "recommended_actions": [str],
  "explainability": str
}
"""


async def run_eligibility_agent(user_profile: dict, visa_program: dict) -> dict:
    user_msg = json.dumps({
        "user_profile": user_profile,
        "target_visa": visa_program
    }, indent=2)

    response = await client.chat.completions.create(
        model=MODEL_NAME,
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": user_msg}
        ],
        response_format={"type": "json_object"},
        temperature=0.2,
    )
    return json.loads(response.choices[0].message.content)
