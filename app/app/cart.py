from flask import Blueprint, render_template, redirect, url_for, flash
from flask_login import login_required, current_user
from . import db
from .models import CartItem, Purchase

cart_bp = Blueprint("cart", __name__)


@cart_bp.route("/cart")
@login_required
def view_cart():
    items = (CartItem.query
             .filter_by(user_id=current_user.id)
             .order_by(CartItem.priority)
             .all())
    total = sum(item.course.price for item in items)
    return render_template("cart.html", items=items, total=total)


@cart_bp.route("/cart/<int:item_id>/remove", methods=["POST"])
@login_required
def remove_from_cart(item_id):
    item = CartItem.query.get_or_404(item_id)
    if item.user_id != current_user.id:
        flash("Not authorized.")
        return redirect(url_for("cart.view_cart"))

    db.session.delete(item)
    db.session.commit()
    return redirect(url_for("cart.view_cart"))


@cart_bp.route("/cart/checkout", methods=["POST"])
@login_required
def checkout():
    items = CartItem.query.filter_by(user_id=current_user.id).all()

    if not items:
        flash("Your cart is empty.")
        return redirect(url_for("cart.view_cart"))

    total = 0
    for item in items:
        db.session.add(Purchase(
            user_id=current_user.id,
            course_id=item.course_id,
            amount=item.course.price,
        ))
        total += item.course.price
        db.session.delete(item)

    db.session.commit()
    flash(f"Payment of ${total} confirmed (mock payment) - enrollment complete.")
    return redirect(url_for("cart.receipt"))


@cart_bp.route("/receipt")
@login_required
def receipt():
    purchases = Purchase.query.filter_by(user_id=current_user.id).order_by(Purchase.purchased_at.desc()).all()
    return render_template("receipt.html", purchases=purchases)