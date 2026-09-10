from flask import Blueprint, render_template, redirect, url_for, request, flash
from flask_login import login_required, current_user
from . import db
from .models import Course, CartItem

courses_bp = Blueprint("courses", __name__)


@courses_bp.route("/courses")
@login_required
def list_courses():
    courses = Course.query.filter_by(career_path=current_user.career_path).order_by(Course.sort_order).all()
    in_cart_ids = {ci.course_id for ci in CartItem.query.filter_by(user_id=current_user.id).all()}
    return render_template("courses.html", courses=courses, in_cart_ids=in_cart_ids)


@courses_bp.route("/courses/<int:course_id>/add", methods=["POST"])
@login_required
def add_to_cart(course_id):
    course = Course.query.get_or_404(course_id)

    if course.career_path != current_user.career_path:
        flash("That course isn't part of your career path.")
        return redirect(url_for("courses.list_courses"))

    existing = CartItem.query.filter_by(user_id=current_user.id, course_id=course_id).first()
    if not existing:
        priority = request.form.get("priority", type=int) or 1
        db.session.add(CartItem(user_id=current_user.id, course_id=course_id, priority=priority))
        db.session.commit()

    return redirect(url_for("courses.list_courses"))