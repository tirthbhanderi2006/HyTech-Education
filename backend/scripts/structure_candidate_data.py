import os
import json
import re

DATA_DIR = r"d:\git\visa\Document"
OUTPUT_FILE = os.path.join(DATA_DIR, "structured_candidates.json")

def clean_name(name: str) -> str:
    # Remove spacing, file extensions, and common descriptors
    name = re.sub(r'[\-_]', ' ', name)
    name = re.sub(r'\s+', ' ', name)
    return name.strip()

def structure_data():
    print(f"Scanning directory: {DATA_DIR}...")
    candidates = {}

    for root, dirs, files in os.walk(DATA_DIR):
        # Skip top level or root metadata folders
        if root == DATA_DIR:
            continue
            
        # Filter files to check for actual documents
        doc_files = [f for f in files if f.lower().endswith(('.pdf', '.jfif', '.jpeg', '.jpg', '.png')) and not f.startswith('~$')]
        if not doc_files:
            continue
            
        # Determine candidate category and folder path
        rel_path = os.path.relpath(root, DATA_DIR)
        parts = rel_path.split(os.sep)
        
        # Candidate name is usually the immediate parent folder name
        candidate_folder_name = parts[-1]
        
        # If candidate name is a generic visa category (e.g. Student, Visitor, AUS, USA, Canada, UK, Dubai)
        # we check the parent folder
        generic_names = {'student', 'visitor', 'visitor visa', 'tourist', 'aus', 'usa', 'canada', 'uk', 'dubai', 'new folder'}
        cand_name = candidate_folder_name
        idx = -2
        while cand_name.lower() in generic_names and abs(idx) <= len(parts):
            cand_name = parts[idx]
            idx -= 1
            
        cand_key = clean_name(cand_name)
        
        if cand_key not in candidates:
            candidates[cand_key] = {
                "name": cand_key,
                "relative_folder": os.path.dirname(rel_path) if idx < -2 else rel_path,
                "absolute_folder": os.path.dirname(root) if idx < -2 else root,
                "documents": []
            }
            
        for f in doc_files:
            file_path = os.path.join(root, f)
            # Try to infer document type from filename
            doc_type = "other"
            fl = f.lower()
            if "passport" in fl:
                doc_type = "passport"
            elif "statement" in fl or "balance" in fl or "bank" in fl:
                doc_type = "bank_statement"
            elif "transcript" in fl or "college" in fl or "degree" in fl or "certificate" in fl or "marksheet" in fl:
                doc_type = "degree_certificate"
            elif "itr" in fl or "tax" in fl or "income tax" in fl:
                doc_type = "tax_return"
            elif "ticket" in fl or "flight" in fl:
                doc_type = "flight_ticket"
            elif "hotel" in fl or "hostel" in fl or "booking" in fl:
                doc_type = "hotel_booking"
            elif "insurance" in fl:
                doc_type = "travel_insurance"
            elif "visa" in fl or "vfs" in fl or "ds160" in fl:
                doc_type = "visa_application"
            elif "cover" in fl or "letter" in fl:
                doc_type = "cover_letter"
                
            candidates[cand_key]["documents"].append({
                "filename": f,
                "inferred_type": doc_type,
                "absolute_path": file_path,
                "file_size_kb": round(os.path.getsize(file_path) / 1024, 2)
            })

    # Convert to list and filter out empty folders
    candidate_list = [c for c in candidates.values() if c["documents"]]
    
    # Save structured index
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(candidate_list, f, indent=2)
        
    print(f"\nStructured {len(candidate_list)} candidates successfully!")
    print(f"Structured metadata saved to: {OUTPUT_FILE}")
    
    # Print sample
    if candidate_list:
        print("\nSample Candidate Structured:")
        print(json.dumps(candidate_list[0], indent=2)[:800] + "...")

if __name__ == "__main__":
    structure_data()
