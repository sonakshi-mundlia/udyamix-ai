import os
import uuid
import logging
from pathlib import Path
from typing import List

from fastapi import UploadFile, HTTPException
from sqlalchemy.orm import Session

from ..models.document_model import Document
from ..models.business_model import Business
from ..schemas.document_schema import DocumentResponse
from ..config import UPLOAD_DIR

import argostranslate.translate


MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB

logger = logging.getLogger("document_service")
logger.setLevel(logging.INFO)


# ============================================================
# TRANSLATION
# ============================================================

def translate_text(
        text: str,
        source_lang: str,
        target_lang: str
) -> str:

    if not text:
        return text

    if not source_lang or source_lang == target_lang:
        return text

    try:
        return argostranslate.translate.translate(
            text,
            source_lang,
            target_lang
        )

    except Exception as e:
        logger.error(f"Argos translation failed: {e}")

        # Safe fallback:
        # return original text instead of breaking the request
        return text

# ============================================================
# SAVE FILE
# ============================================================

async def save_file(
        db: Session,
        file: UploadFile,
        business: Business
) -> DocumentResponse:

    os.makedirs(
        UPLOAD_DIR,
        exist_ok=True
    )

    # --------------------------------------------------------
    # Validate filename
    # --------------------------------------------------------

    if not file.filename:

        raise HTTPException(
            status_code=400,
            detail="Invalid file"
        )


    # --------------------------------------------------------
    # File extension
    # --------------------------------------------------------

    ext = Path(file.filename).suffix.lower()

    allowed_extensions = {
        ".pdf",
        ".jpg",
        ".jpeg"
    }

    if ext not in allowed_extensions:

        raise HTTPException(
            status_code=400,
            detail=f"Unsupported file type: {ext}"
        )


    # --------------------------------------------------------
    # Generate unique filename
    # --------------------------------------------------------

    filename = f"{uuid.uuid4()}{ext}"

    path = os.path.join(
        UPLOAD_DIR,
        filename
    )


    # --------------------------------------------------------
    # Save uploaded file
    # --------------------------------------------------------

    size = 0

    try:

        with open(path, "wb") as f:

            while chunk := await file.read(
                    1024 * 1024
            ):

                size += len(chunk)

                # File size protection
                if size > MAX_FILE_SIZE:

                    if os.path.exists(path):
                        os.remove(path)

                    raise HTTPException(
                        status_code=413,
                        detail="File too large. Maximum size is 10 MB."
                    )

                f.write(chunk)

    except HTTPException:
        raise

    except Exception as e:

        logger.error(
            f"Failed to save file: {e}"
        )

        if os.path.exists(path):
            os.remove(path)

        raise HTTPException(
            status_code=500,
            detail="Failed to save file"
        )

    # --------------------------------------------------------
    # Save document metadata
    # --------------------------------------------------------

    try:

        document = Document(
            business_id=business.id,
            file_path=path,
            file_type=file.content_type or ext,
            file_size=size
        )

        db.add(document)

        db.commit()

        db.refresh(document)

    except Exception as e:

        db.rollback()

        logger.error(
            f"Database error while saving document: {e}"
        )

        if os.path.exists(path):
            os.remove(path)

        raise HTTPException(
            status_code=500,
            detail=f"DB error: {str(e)}"
        )


    logger.info(
        f"Document saved successfully. ID={document.id}"
    )


    return DocumentResponse.from_orm(
        document
    )


# ============================================================
# GET DOCUMENTS
# ============================================================

def get_documents(
        db: Session,
        business: Business
) -> List[DocumentResponse]:

    documents = (
        db.query(Document)
        .filter(
            Document.business_id == business.id
        )
        .order_by(
            Document.created_at.desc()
        )
        .all()
    )

    return [
        DocumentResponse.from_orm(document)
        for document in documents
    ]


# ============================================================
# DELETE DOCUMENT
# ============================================================

def delete_document(
        db: Session,
        document_id: int,
        business: Business
):

    document = (
        db.query(Document)
        .filter(
            Document.id == document_id,
            Document.business_id == business.id
        )
        .first()
    )


    if not document:

        raise HTTPException(
            status_code=404,
            detail="Document not found"
        )


    # --------------------------------------------------------
    # Delete physical file
    # --------------------------------------------------------

    if (
            document.file_path
            and os.path.exists(document.file_path)
    ):

        try:
            os.remove(document.file_path)

        except Exception as e:

            logger.warning(
                f"Could not delete physical file: {e}"
            )


    # --------------------------------------------------------
    # Delete database record
    # --------------------------------------------------------

    db.delete(document)

    db.commit()


    return {
        "success": True,
        "message": "Document deleted successfully"
    }

