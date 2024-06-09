import sys
import os
from logging import getLogger, INFO, basicConfig
from typing import List
from fastapi import Depends, FastAPI, HTTPException
from pydantic import BaseModel
from sqlalchemy import create_engine, select, String,  Boolean
from sqlalchemy.orm import (
    DeclarativeBase,
    Mapped,
    Session,
    mapped_column,
    scoped_session,
    sessionmaker,
)


# logging
basicConfig(stream=sys.stdout, level=INFO, format='%(asctime)s %(levelname)s %(message)s')
logger = getLogger(__name__)


# database
DB_USER     = os.getenv('DB_USER')
DB_PASSWORD = os.getenv('DB_PASSWORD')
DB_HOST     = os.getenv('DB_HOST')
DATABASE    = os.getenv('DATABASE')

engine = create_engine(f'mysql+mysqlconnector://{DB_USER}:{DB_PASSWORD}@{DB_HOST}/{DATABASE}')
SessionLocal = scoped_session(
    sessionmaker(autocommit=False, autoflush=False, future=True, bind=engine)
)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# model
class Base(DeclarativeBase):
    pass


class ZipCode(Base):
    __tablename__ = "zipcode"

    code:           Mapped[str] = mapped_column(String(7), primary_key=True)
    publicCode:     Mapped[str] = mapped_column(String(5))
    oldCode:        Mapped[str] = mapped_column(String(5))
    prefectureKana: Mapped[str] = mapped_column(String(10))
    cityKana:       Mapped[str] = mapped_column(String(100))
    townKana:       Mapped[str] = mapped_column(String(100))
    prefecture:     Mapped[str] = mapped_column(String(10))
    city:           Mapped[str] = mapped_column(String(200))
    town:           Mapped[str] = mapped_column(String(200))
    flgMultiCode:   Mapped[bool] = mapped_column(Boolean)
    flgKoazaBanchi: Mapped[bool] = mapped_column(Boolean)
    flgChome:       Mapped[bool] = mapped_column(Boolean)
    flgMultiTown:   Mapped[bool] = mapped_column(Boolean)
    updateState:    Mapped[bool] = mapped_column(Boolean)
    updateReason:   Mapped[bool] = mapped_column(Boolean)


# schema
class ZipCodeResponse(BaseModel):
    code:           str
    publicCode:     str
    oldCode:        str
    prefectureKana: str
    cityKana:       str
    townKana:       str
    prefecture:     str
    city:           str
    town:           str
    flgMultiCode:   bool
    flgKoazaBanchi: bool
    flgChome:       bool
    flgMultiTown:   bool
    updateState:    bool
    updateReason:   bool

    class Config:
        orm_mode = True


app = FastAPI()


@app.get("/zipcodes", response_model=List[ZipCodeResponse])
async def get_zipcodes(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    zipcodes = db.execute(select(ZipCode).offset(skip).limit(limit)).scalars().all()
    return zipcodes


@app.get("/zipcode/{code}", response_model=ZipCodeResponse)
async def get_zipcode(code: str, db: Session = Depends(get_db)):
    zipcode = db.execute(select(ZipCode).where(ZipCode.code == code)).scalars().first()
    if not zipcode:
        raise HTTPException(status_code=404, detail=f"Code: {code} not found")
    return zipcode
