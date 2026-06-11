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
You are the Risk Agent for HyTech Visa Copilot.
Analyze the case data and produce a rejection risk score.
Consider: document completeness, financial consistency,
employment gaps, travel history, profile-visa match.

Respond ONLY with valid JSON:
{
  "risk_score": float,           
  "risk_category": "Low|Medium|High|Critical",
  "top_risk_factors": [
    {"factor": str, "contribution": float, "explanation": str}
  ],
  "improvement_recommendations": [
    {"action": str, "estimated_score_reduction": float}
  ],
  "disclaimer": "This is AI-generated guidance, not legal advice."
}
"""


async def run_risk_agent(case_data: dict) -> dict:
    response = await client.chat.completions.create(
        model=MODEL_NAME,
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": json.dumps(case_data, indent=2)}
        ],
        response_format={"type": "json_object"},
        temperature=0.2,
    )
    return json.loads(response.choices[0].message.content)
