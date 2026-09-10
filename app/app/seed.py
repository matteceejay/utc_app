from . import db
from .models import Course

COURSE_CATALOG = {
    "lawyer": [
        ("Intro to Constitutional Law", "Foundations of constitutional principles and case law."),
        ("Contract Law Fundamentals", "Formation, terms, and enforcement of contracts."),
        ("Criminal Law Basics", "Core concepts in criminal statutes and defenses."),
        ("Legal Research & Writing", "Research methods and persuasive legal writing."),
        ("Civil Procedure", "Rules governing civil litigation from filing to appeal."),
        ("Evidence Law", "Rules for admissibility and use of evidence at trial."),
    ],
    "doctor": [
        ("Human Anatomy I", "Structure and organization of the human body."),
        ("Medical Terminology", "Standard terminology used across clinical practice."),
        ("Introduction to Pharmacology", "How drugs interact with the human body."),
        ("Clinical Diagnostics", "Methods for diagnosing common conditions."),
        ("Patient Care Ethics", "Ethical frameworks for clinical decision-making."),
        ("Emergency Medicine Basics", "First-line response to acute medical situations."),
    ],
    "priest": [
        ("Introduction to Theology", "Core concepts and traditions in theological study."),
        ("Church History", "Major events and figures shaping church history."),
        ("Pastoral Counseling Basics", "Foundational skills for pastoral care."),
        ("Homiletics (Sermon Writing)", "Crafting and delivering effective sermons."),
        ("Sacred Scripture Studies", "Close reading and interpretation of scripture."),
        ("Canon Law Fundamentals", "Core principles of ecclesiastical law."),
    ],
}


def seed_courses():
    if Course.query.first():
        return

    for career_path, courses in COURSE_CATALOG.items():
        for idx, (title, description) in enumerate(courses, start=1):
            db.session.add(Course(
                career_path=career_path,
                title=title,
                description=description,
                price=400,
                sort_order=idx,
            ))
    db.session.commit()