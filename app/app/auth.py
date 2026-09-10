from flask import Blueprint, render_template, request, redirect, url_for, flash
from flask_login import login_user, logout_user, login_required
from . import db
from .models import User, CAREER_PATHS

auth_bp = Blueprint("auth", __name__)


@auth_bp.route("/signup", methods=["GET", "POST"])
def signup():
    if request.method == "POST":
        first_name = request.form["first_name"].strip()
        last_name = request.form["last_name"].strip()
        phone = request.form["phone"].strip()
        email = request.form["email"].strip().lower()
        password = request.form["password"]
        career_path = request.form["career_path"]

        if career_path not in CAREER_PATHS:
            flash("Please choose a valid career path.")
            return redirect(url_for("auth.signup"))

        if User.query.filter_by(email=email).first():
            flash("An account with that email already exists.")
            return redirect(url_for("auth.signup"))

        user = User(
            first_name=first_name,
            last_name=last_name,
            phone=phone,
            email=email,
            career_path=career_path,
        )
        user.set_password(password)
        db.session.add(user)
        db.session.commit()

        flash("Account created - please log in.")
        return redirect(url_for("auth.login"))

    return render_template("signup.html", career_paths=CAREER_PATHS)


@auth_bp.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        email = request.form["email"].strip().lower()
        password = request.form["password"]

        user = User.query.filter_by(email=email).first()
        if user and user.check_password(password):
            login_user(user)
            return redirect(url_for("courses.list_courses"))

        flash("Invalid email or password.")
        return redirect(url_for("auth.login"))

    return render_template("login.html")


@auth_bp.route("/logout")
@login_required
def logout():
    logout_user()
    return redirect(url_for("auth.login"))