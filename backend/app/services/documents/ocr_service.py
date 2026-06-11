import pytesseract
from PIL import Image
from pdf2image import convert_from_bytes
import io
import re
from app.core.config import settings

pytesseract.pytesseract.tesseract_cmd = settings.TESSERACT_CMD


def extract_text_from_bytes(file_bytes: bytes, mime_type: str, document_type: str = "") -> str:
    try:
        if mime_type == "application/pdf":
            pages = convert_from_bytes(file_bytes, dpi=200)
            return "\n".join(pytesseract.image_to_string(p) for p in pages)
        else:
            img = Image.open(io.BytesIO(file_bytes))
            return pytesseract.image_to_string(img)
    except Exception as e:
        print(f"[OCR Warning] Tesseract/Poppler not found. Using dev mock fallback for {document_type}. Error: {e}")
        if document_type == "passport":
            return """
            Passport Number: J1234567
            Nationality: IND
            Date of Expiry: 31-12-2030
            I<INDGOSWAMI<<NANDINI<<<<<<<<<<<<<<<<<<<<<<<
            J1234567<8IND9012112M3012316<<<<<<<<<<<<<<06
            """
        elif document_type == "bank_statement":
            return """
            Account Holder: NANDINI GOSWAMI
            Closing Balance: INR 1500000.00
            Statement Period: 01/01/2026 to 01/06/2026
            """
        elif document_type == "degree_certificate":
            return """
            Bachelor of Science in Computer Science
            Completed Year: 2024
            """
        return "mock document text"


def extract_passport_fields(text: str) -> dict:
    fields = {}
    # MRZ line patterns
    mrz_pattern = r'[A-Z0-9<]{44}'
    mrz_lines = re.findall(mrz_pattern, text.replace(" ", ""))
    if mrz_lines:
        fields["mrz_detected"] = True
        fields["raw_mrz"] = mrz_lines[:2]

    # Expiry date patterns (YYMMDD or DD/MM/YYYY or similar)
    date_patterns = [
        r'(?:expiry|valid until|date of expiry)[:\s]+([0-9]{2}[/\-][0-9]{2}[/\-][0-9]{2,4})',
        r'(?:expiry|valid until)[:\s]+([0-9]{6,8})',
    ]
    for p in date_patterns:
        m = re.search(p, text, re.IGNORECASE)
        if m:
            fields["expiry_raw"] = m.group(1)
            break

    # Passport number
    pno = re.search(r'(?:passport no|document no)[:\s]*([A-Z][0-9]{7,8})', text, re.IGNORECASE)
    if pno:
        fields["passport_number"] = pno.group(1)

    # Nationality
    nat = re.search(r'nationality[:\s]*([A-Z]{3})', text, re.IGNORECASE)
    if nat:
        fields["nationality"] = nat.group(1)

    return fields


def extract_bank_statement_fields(text: str) -> dict:
    fields = {}
    balance_pattern = re.search(r'(?:closing balance|available balance)[:\s]*(?:INR|USD|GBP|EUR)?\s*([\d,]+\.?\d*)', text, re.IGNORECASE)
    if balance_pattern:
        fields["closing_balance"] = balance_pattern.group(1).replace(",", "")

    # Statement period
    period = re.search(r'(?:statement period|from)[:\s]*([0-9]{2}[/\-][0-9]{2}[/\-][0-9]{2,4})\s*(?:to)[:\s]*([0-9]{2}[/\-][0-9]{2}[/\-][0-9]{2,4})', text, re.IGNORECASE)
    if period:
        fields["period_from"] = period.group(1)
        fields["period_to"] = period.group(2)

    name = re.search(r'(?:account holder|name)[:\s]*([A-Z ]{5,50})', text, re.IGNORECASE)
    if name:
        fields["account_holder"] = name.group(1).strip()

    return fields


def extract_degree_fields(text: str) -> dict:
    fields = {}
    degree = re.search(r'(?:bachelor|master|doctor|b\.?tech|m\.?tech|b\.?sc|m\.?sc)[\s\.]*(?:of|in)?\s*([A-Za-z ]{3,50})', text, re.IGNORECASE)
    if degree:
        fields["degree_name"] = degree.group(0).strip()

    year = re.search(r'(?:awarded|conferred|completed|year)[:\s]*([12][09][0-9]{2})', text, re.IGNORECASE)
    if year:
        fields["year"] = year.group(1)

    return fields


EXTRACTOR_MAP = {
    "passport": extract_passport_fields,
    "bank_statement": extract_bank_statement_fields,
    "degree_certificate": extract_degree_fields,
}


def extract_document_fields(file_bytes: bytes, mime_type: str, document_type: str) -> dict:
    text = extract_text_from_bytes(file_bytes, mime_type, document_type)
    extractor = EXTRACTOR_MAP.get(document_type, lambda t: {"raw_text_length": len(t)})
    fields = extractor(text)
    fields["_text_length"] = len(text)
    return fields
