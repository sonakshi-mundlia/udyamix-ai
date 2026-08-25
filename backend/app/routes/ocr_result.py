# routes/ocr_route.py

from fastapi import APIRouter, UploadFile, File, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from pathlib import Path

from ..models.business_model import Business
from ..utils.auth_dependency import get_current_business, get_current_language
from ..services.ocr_result_service import process_document_ai
from ..services.document_service import save_file
from ..models.document_model import Document

router = APIRouter(prefix="/ocr", tags=["OCR"])


@router.post("/upload")
async def upload_and_process_document(
        file: UploadFile = File(...),
        db: Session = Depends(get_db),
        business: Business = Depends(get_current_business),
        lang: str = Depends(get_current_language)
):
    """
    Upload document → OCR → AI → multilingual response
    """

    if not file:
        raise HTTPException(status_code=400, detail="No file uploaded")

    try:
        # Step 1: Save file
        print("STEP 1: Saving file...")
        print("Filename:", file.filename)
        print("Content type:", file.content_type)

        document: Document = await save_file(
            db,
            file,
            business
        )

        print("Document saved:", document)

        if not document:
            raise HTTPException(
                status_code=500,
                detail="Failed to save document"
            )

        # Step 2: OCR + AI
        print("STEP 2: Starting OCR + AI...")
        print("Document ID:", document.id)
        print("File path:", document.file_path)
        print("Language:", lang)

        ocr_result = await process_document_ai(
            db=db,
            business=business,
            document_id=document.id,
            file_path=document.file_path
        )

        print("STEP 3: OCR + AI completed")
        print("OCR result:", ocr_result)

        return {
            "success": True,
            "document_id": document.id,
            "filename": Path(document.file_path).name,
            "ocr_result": ocr_result
        }

    except Exception as e:
        import traceback

        print("========== OCR ERROR ==========")
        print("Error type:", type(e).__name__)
        print("Error:", str(e))
        traceback.print_exc()
        print("================================")

        raise HTTPException(
            status_code=500,
            detail=f"OCR processing failed: {str(e)}"
        )

