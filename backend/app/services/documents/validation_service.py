from datetime import datetime, date
from typing import List, Dict


def validate_passport(extracted: dict, intended_travel_date: str | None) -> List[Dict]:
    flags = []

    if not extracted.get("mrz_detected"):
        flags.append({"field": "mrz", "severity": "critical", "message": "MRZ barcode could not be read. Ensure full passport page is scanned clearly."})

    expiry_raw = extracted.get("expiry_raw", "")
    if expiry_raw:
        try:
            for fmt in ["%d/%m/%Y", "%d-%m-%Y", "%y%m%d", "%Y%m%d", "%d/%m/%y"]:
                try:
                    exp_date = datetime.strptime(expiry_raw, fmt).date()
                    break
                except ValueError:
                    continue
            else:
                raise ValueError("No format matched")

            today = date.today()
            if exp_date < today:
                flags.append({"field": "expiry", "severity": "critical", "message": f"Passport expired on {exp_date}. You must renew before applying."})
            elif intended_travel_date:
                travel = datetime.strptime(intended_travel_date, "%Y-%m-%d").date()
                months_valid = (exp_date - travel).days / 30
                if months_valid < 6:
                    flags.append({"field": "expiry", "severity": "high", "message": f"Passport expires {exp_date} — less than 6 months after intended travel ({travel}). Most countries require 6+ months validity."})
        except Exception:
            flags.append({"field": "expiry", "severity": "medium", "message": "Could not parse passport expiry date. Please verify manually."})
    else:
        flags.append({"field": "expiry", "severity": "high", "message": "Expiry date not detected. Ensure expiry page is included."})

    return flags


def validate_bank_statement(extracted: dict) -> List[Dict]:
    flags = []
    if not extracted.get("closing_balance"):
        flags.append({"field": "balance", "severity": "high", "message": "Closing balance not detected. Ensure the balance summary page is included."})
    if not extracted.get("period_from") or not extracted.get("period_to"):
        flags.append({"field": "period", "severity": "medium", "message": "Statement period not detected. Most embassies require 3–6 months of statements."})
    if not extracted.get("account_holder"):
        flags.append({"field": "name", "severity": "medium", "message": "Account holder name not found. Ensure the header page is included."})
    return flags


def validate_degree(extracted: dict) -> List[Dict]:
    flags = []
    if not extracted.get("degree_name"):
        flags.append({"field": "degree", "severity": "medium", "message": "Degree title not clearly detected."})
    if not extracted.get("year"):
        flags.append({"field": "year", "severity": "low", "message": "Graduation year not detected."})
    return flags


def compute_health_score(flags: List[Dict]) -> float:
    deductions = {"critical": 30, "high": 20, "medium": 10, "low": 5}
    score = 100.0
    for f in flags:
        score -= deductions.get(f.get("severity", "low"), 5)
    return max(0.0, score)


VALIDATORS = {
    "passport": validate_passport,
    "bank_statement": validate_bank_statement,
    "degree_certificate": validate_degree,
}


def validate_document(document_type: str, extracted: dict, intended_travel_date: str | None = None) -> dict:
    validator = VALIDATORS.get(document_type)
    if validator:
        if document_type == "passport":
            flags = validator(extracted, intended_travel_date)
        else:
            flags = validator(extracted)
    else:
        flags = []

    health = compute_health_score(flags)
    fixes = [f["message"] for f in flags]
    return {"health_score": health, "flags": flags, "suggested_fixes": fixes, "is_valid": health >= 60}
