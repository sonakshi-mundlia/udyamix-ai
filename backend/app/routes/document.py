from fastapi import APIRouter, Depends, UploadFile, File, HTTPException
from sqlalchemy.orm import Session
from fastapi.responses import FileResponse

from database import get_db
from ..models.business_model import Business
from ..services.document_service import (
    save_file,
    get_documents,
    delete_document
)
from ..models.document_model import Document
from ..schemas.document_schema import DocumentResponse
from ..utils.auth_dependency import get_current_business, get_current_language

router = APIRouter(prefix="/documents", tags=["Documents"])


# ----------------------------
# UPLOAD DOCUMENT
# ----------------------------
@router.post("/upload", response_model=DocumentResponse)
async def upload_document(
        file: UploadFile = File(...),
        db: Session = Depends(get_db),
        business: Business = Depends(get_current_business),
        lang: str = Depends(get_current_language)  # ✅ user language
):
    try:
        return await save_file(
            db=db,
            file=file,
            business=business,
            lang=lang  # ✅ pass language
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to upload document: {str(e)}"
        )


# ----------------------------
# LIST DOCUMENTS (AUTO TRANSLATION)
# ----------------------------
@router.get("/", response_model=list[DocumentResponse])
def list_documents(
        db: Session = Depends(get_db),
        business: Business = Depends(get_current_business),
        lang: str = Depends(get_current_language)  # ✅ target language
):
    return get_documents(
        db=db,
        business=business,
        lang=lang  # ✅ important
    )


# ----------------------------
# VIEW DOCUMENT FILE
# ----------------------------
@router.get("/{document_id}/view")
def view_document(
        document_id: int,
        db: Session = Depends(get_db),
        business: Business = Depends(get_current_business)
):
    document = db.query(Document).filter(
        Document.id == document_id,
        Document.business_id == business.id
    ).first()

    if not document:
        raise HTTPException(status_code=404, detail="Document not found")

    return FileResponse(
        path=document.file_path,
        media_type=document.file_type,
        filename=document.file_path.split("/")[-1]
    )


# ----------------------------
# DELETE DOCUMENT
# ----------------------------
@router.delete("/{document_id}")
def remove_document(
        document_id: int,
        db: Session = Depends(get_db),
        business: Business = Depends(get_current_business)
):
    document = db.query(Document).filter(
        Document.id == document_id,
        Document.business_id == business.id
    ).first()

    if not document:
        raise HTTPException(status_code=404, detail="Document not found")

    delete_document(
        db=db,
        document_id=document.id,   # ✅ FIXED
        business=business
    )

    return {"message": "Document deleted successfully"}

