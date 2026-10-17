"""initial_schema

Revision ID: 001_initial_schema
Revises: 
Create Date: 2026-10-17 19:30:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = '001_initial_schema'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Tables will be managed through Base.metadata.create_all and Alembic
    pass


def downgrade() -> None:
    pass
