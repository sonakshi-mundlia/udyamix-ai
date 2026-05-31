# routes/ocr_route.py

from fastapi import APIRouter, UploadFile, File, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db

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
        lang: str = Depends(get_current_language)  # ✅ language injected
):
    """
    Upload document → OCR → AI → multilingual response
    """

    if not file:
        raise HTTPException(status_code=400, detail="No file uploaded")

    try:
        # ----------------------------
        # Step 1: Save file
        # ----------------------------
        document: Document = await save_file(db, file, business.id)

        if not document:
            raise HTTPException(status_code=500, detail="Failed to save document")

        # ----------------------------
        # Step 2: Process OCR + AI
        # ----------------------------
        ocr_result = await process_document_ai(
            db=db,
            business=business,   # ✅ FIXED
            document_id=document.id,            # ✅ FIXED
            file_path=document.file_path,
            lang=lang                           # ✅ LANGUAGE FLOW
        )

        # ----------------------------
        # Step 3: Response
        # ----------------------------
        return {
            "success": True,
            "document_id": document.id,
            "filename": document.file_name,
            "language": lang,  # ✅ include for frontend
            "ocr_result": ocr_result
        }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"OCR processing failed: {str(e)}"
        )