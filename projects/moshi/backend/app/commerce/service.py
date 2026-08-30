from __future__ import annotations

from app.commerce.models import MessageCatalogCard, MessageOrderCard, OrderDraft
from app.commerce.schemas import CatalogCardResponse, OrderCardResponse, OrderDraftItemResponse, OrderDraftResponse


def serialize_catalog_card(card: MessageCatalogCard) -> CatalogCardResponse:
    return CatalogCardResponse(
        catalog_item_id=card.catalog_item_id,
        seller_id=card.seller_id,
        business_name=card.business_name,
        kind=card.kind,
        title=card.title,
        description=card.description,
        price_amount=card.price_amount,
        currency=card.currency,
        availability=card.availability,
        stock_qty=card.stock_qty,
        image_path=f"/v1/commerce/catalog-cards/{card.message_id}/image" if card.image_attachment_id else None,
    )


def serialize_order_card(card: MessageOrderCard) -> OrderCardResponse:
    return OrderCardResponse(
        order_id=card.order_id,
        buyer_id=card.buyer_id,
        seller_id=card.seller_id,
        status=card.status,
        item_title=card.item_title,
        quantity=card.quantity,
        total_amount=card.total_amount,
        currency=card.currency,
    )


def serialize_order(order: OrderDraft) -> OrderDraftResponse:
    items = [
        OrderDraftItemResponse(
            id=item.id,
            catalog_item_id=item.catalog_item_id,
            source_message_id=item.source_message_id,
            kind=item.kind,
            title=item.title,
            unit_price_amount=item.unit_price_amount,
            currency=item.currency,
            quantity=item.quantity,
            image_path=None,
        )
        for item in order.items
    ]
    currencies = {item.currency for item in order.items}
    currency = next(iter(currencies)) if len(currencies) == 1 else "IDR"
    total_amount = None
    if order.items and all(item.unit_price_amount is not None for item in order.items):
        total_amount = sum(int(item.unit_price_amount or 0) * item.quantity for item in order.items)
    return OrderDraftResponse(
        id=order.id,
        conversation_id=order.conversation_id,
        buyer_id=order.buyer_id,
        seller_id=order.seller_id,
        status=order.status,
        note=order.note,
        items=items,
        total_amount=total_amount,
        currency=currency,
        created_at=order.created_at,
        updated_at=order.updated_at,
    )
