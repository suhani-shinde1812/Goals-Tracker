from datetime import date, timedelta
from sqlalchemy.orm import Session
from .models import (
    User, UserPreference, ScheduledTask, GateSubject, GateTopic,
    SemesterSubject, SemesterUnit, WorkoutDefinition, HabitDefinition
)

GATE_SYLLABUS = [
    {
        "code": "EM",
        "name": "Engineering Mathematics",
        "topics": [
            "Linear Algebra: Matrices, determinants, system of linear equations, eigenvalues and eigenvectors, LU decomposition",
            "Calculus: Limits, continuity and differentiability, Maxima and minima, Mean value theorem, Integration",
            "Probability: Random variables, Uniform, normal, exponential, Poisson and binomial distributions, Mean, median, mode, Conditional probability and Bayes theorem"
        ]
    },
    {
        "code": "DM",
        "name": "Discrete Mathematics",
        "topics": [
            "Propositional and first order logic",
            "Sets, relations, functions, partial orders and lattices",
            "Monoids, Groups",
            "Graphs: connectivity, matching, coloring",
            "Combinatorics: counting, recurrence relations, generating functions"
        ]
    },
    {
        "code": "DL",
        "name": "Digital Logic",
        "topics": [
            "Boolean algebra, Combinational and sequential circuits",
            "Minimization of functions, Number representations and computer arithmetic (fixed and floating point)"
        ]
    },
    {
        "code": "COA",
        "name": "Computer Organization and Architecture",
        "topics": [
            "Machine instructions and addressing modes, ALU, data-path and control unit",
            "Instruction pipelining, pipeline hazards",
            "Memory hierarchy: cache, main memory and secondary storage",
            "I/O interface (interrupt and DMA mode)"
        ]
    },
    {
        "code": "PDS",
        "name": "Programming and Data Structures",
        "topics": [
            "Programming in C: recursion, arrays, pointers, structures",
            "Stacks, queues, linked lists, trees, binary search trees, binary heaps, graphs"
        ]
    },
    {
        "code": "ALGO",
        "name": "Algorithms",
        "topics": [
            "Searching, sorting, hashing",
            "Asymptotic worst and average time and space complexity",
            "Algorithm design: greedy, dynamic programming, divide-and-conquer",
            "Graph traversals, minimum spanning trees, shortest paths"
        ]
    },
    {
        "code": "TOC",
        "name": "Theory of Computation",
        "topics": [
            "Regular expressions and finite automata",
            "Context-free grammars and push-down automata",
            "Regular and context-free languages, pumping lemma",
            "Turing machines and undecidability"
        ]
    },
    {
        "code": "CD",
        "name": "Compiler Design",
        "topics": [
            "Lexical analysis, parsing, syntax-directed translation",
            "Runtime environments, intermediate code generation",
            "Local optimization, Data flow analyses: constant propagation, liveness analysis, common subexpression elimination"
        ]
    },
    {
        "code": "OS",
        "name": "Operating Systems",
        "topics": [
            "System calls, processes, threads, inter-process communication, concurrency and synchronization",
            "Deadlock, CPU and CPU scheduling algorithms",
            "Memory management and virtual memory",
            "File systems and disk scheduling"
        ]
    },
    {
        "code": "DBMS",
        "name": "Databases",
        "topics": [
            "ER-model, Relational model: relational algebra, tuple calculus",
            "SQL, Integrity constraints, normal forms",
            "File organization, indexing (e.g., B and B+ trees)",
            "Transactions and concurrency control"
        ]
    },
    {
        "code": "CN",
        "name": "Computer Networks",
        "topics": [
            "Concept of layering: OSI and TCP/IP protocol stacks",
            "Basics of packet, circuit and virtual circuit switching",
            "Data link layer: framing, error detection, Medium Access Control, Ethernet bridging",
            "Routing protocols: shortest path, flooding, distance vector and link state routing",
            "Fragmentation and IP addressing (IPv4, IPv6), CIDR",
            "Transport layer: flow control, congestion control, UDP, TCP, sockets",
            "Application layer protocols: DNS, SMTP, HTTP, FTP"
        ]
    },
    {
        "code": "GA",
        "name": "General Aptitude",
        "topics": [
            "Verbal Aptitude: Basic English grammar, vocabulary, reading comprehension",
            "Quantitative Aptitude: Data interpretation, numerical computation and estimation",
            "Analytical Aptitude: Logic, deduction and induction, analogy",
            "Spatial Aptitude: Transformation of shapes, paper folding, patterns"
        ]
    }
]

WORKOUT_ROUTINES = [
    {
        "name": "Brisk Morning Walk & Daylight",
        "category": "Cardio & Sunlight",
        "difficulty": "Beginner",
        "duration_mins": 30,
        "description": "Gentle outdoor walk to absorb morning sunlight, wake up circadian rhythms, and gently elevate heart rate.",
        "instructions": "Walk at a steady, comfortable pace. Breathe deeply through your nose. Swing arms naturally.",
        "target_body_parts": "Full Body, Cardiovascular"
    },
    {
        "name": "Beginner Chair Squats",
        "category": "Home Workout",
        "difficulty": "Beginner",
        "duration_mins": 15,
        "description": "Safe, knee-friendly lower-body movement to strengthen quads, glutes, and core.",
        "instructions": "Stand in front of a sturdy chair. Lower your hips back until lightly touching the seat, then press through heels to stand. 3 sets of 10-12 reps.",
        "target_body_parts": "Quadriceps, Glutes, Core"
    },
    {
        "name": "Wall Push-Ups",
        "category": "Home Workout",
        "difficulty": "Beginner",
        "duration_mins": 12,
        "description": "Low-impact upper body movement building shoulder, chest, and triceps stability without floor strain.",
        "instructions": "Face a wall an arm-length away. Place palms flat at chest height. Bend elbows to bring chest toward wall, then push back smoothly. 3 sets of 10-12 reps.",
        "target_body_parts": "Chest, Triceps, Anterior Deltoids"
    },
    {
        "name": "Glute Bridges",
        "category": "Home Workout",
        "difficulty": "Beginner",
        "duration_mins": 15,
        "description": "Great for relieving lower back tightness, pelvic floor support, and activating glutes after long study hours.",
        "instructions": "Lie on your back with knees bent and feet flat on floor. Lift hips toward ceiling squeezing glutes at the top. Hold 2 seconds, lower slowly. 3 sets of 12 reps.",
        "target_body_parts": "Glutes, Hamstrings, Lower Back"
    },
    {
        "name": "Bird-Dog Core Stability",
        "category": "Mobility & Core",
        "difficulty": "Beginner",
        "duration_mins": 12,
        "description": "Gentle spine-sparing exercise that strengthens the deep abdominal wall and enhances stability.",
        "instructions": "On hands and knees, extend opposite arm forward and opposite leg back in a straight line. Hold 3 seconds. Alternate sides for 10 reps each.",
        "target_body_parts": "Core, Spinal Erectors, Balance"
    },
    {
        "name": "Gentle Evening Stretching & Mobility",
        "category": "Stretching & Relaxation",
        "difficulty": "Beginner",
        "duration_mins": 20,
        "description": "Calming mobility flow focusing on hips, neck, shoulders, and chest to unwind before bedtime.",
        "instructions": "Child's pose, cat-cow stretches, gentle seated spinal twists, hamstring reach, and deep belly breathing.",
        "target_body_parts": "Hips, Spine, Neck, Nervous System"
    }
]


def seed_gate_and_workouts(db: Session):
    # Seed GATE Subjects & Topics
    for order, subj_data in enumerate(GATE_SYLLABUS):
        subj = db.query(GateSubject).filter(GateSubject.code == subj_data["code"]).first()
        if not subj:
            subj = GateSubject(
                code=subj_data["code"],
                name=subj_data["name"],
                order_index=order
            )
            db.add(subj)
            db.flush()
            for topic_name in subj_data["topics"]:
                topic = GateTopic(
                    subject_id=subj.id,
                    name=topic_name,
                    status="Not Started"
                )
                db.add(topic)
    
    # Seed Workouts
    for w in WORKOUT_ROUTINES:
        existing = db.query(WorkoutDefinition).filter(WorkoutDefinition.name == w["name"]).first()
        if not existing:
            workout = WorkoutDefinition(
                name=w["name"],
                category=w["category"],
                difficulty=w["difficulty"],
                duration_mins=w["duration_mins"],
                description=w["description"],
                instructions=w["instructions"],
                target_body_parts=w["target_body_parts"]
            )
            db.add(workout)
            
    db.commit()


def seed_user_initial_data(db: Session, user: User, target_date: date = None):
    if not target_date:
        target_date = date.today()

    # 1. Ensure User Preferences
    if not user.preferences:
        pref = UserPreference(
            user_id=user.id,
            height_cm=162.6,
            starting_weight_kg=66.0,
            target_weight_kg=56.0,
            current_weight_kg=66.0,
            timezone="Asia/Kolkata",
            quiet_hours_start="22:15",
            quiet_hours_end="06:30",
            diet_preference="Veg & Non-Veg with Eggs",
            workout_preference="Home Workouts",
            pcod_history="PCOD / Irregular periods every 2-3 months",
            cycle_reminder_threshold_days=60,
            previous_hemoglobin_g_dl=11.4,
            daily_water_target_ml=2200,
            daily_sleep_target_hours=8.0
        )
        db.add(pref)

    # 2. Seed Semester Subjects S1-S5 if not present
    existing_sem = db.query(SemesterSubject).filter(SemesterSubject.user_id == user.id).first()
    if not existing_sem:
        sem_subjects = [
            ("S1", "Subject 1 (e.g. Distributed Systems)", "High", "Hard"),
            ("S2", "Subject 2 (e.g. Cloud Computing)", "High", "Medium"),
            ("S3", "Subject 3 (e.g. Information Security)", "Medium", "Medium"),
            ("S4", "Subject 4 (e.g. Machine Learning Elective)", "Medium", "Hard"),
            ("S5", "Subject 5 (e.g. Management & Entrepreneurship)", "Low", "Easy")
        ]
        for code, name, prio, diff in sem_subjects:
            s = SemesterSubject(
                user_id=user.id,
                code=code,
                name=name,
                priority=prio,
                difficulty=diff,
                exam_date=date(2026, 12, 15),
                syllabus_completion_pct=0.0
            )
            db.add(s)
            db.flush()
            for unit_idx in range(1, 6):
                unit = SemesterUnit(
                    subject_id=s.id,
                    unit_number=unit_idx,
                    title=f"Unit {unit_idx}: Core Concepts & PYQs",
                    is_completed=False
                )
                db.add(unit)

    # 3. Seed Habits if not present
    existing_habit = db.query(HabitDefinition).filter(HabitDefinition.user_id == user.id).first()
    if not existing_habit:
        default_habits = [
            ("Drink 2.2L Water", "Hydration", "water_drop", 7, "08:00"),
            ("Morning Daylight & Walk", "Exercise", "wb_sunny", 7, "06:30"),
            ("GATE CS Daily Focus (2h)", "Study", "menu_book", 7, "08:00"),
            ("Semester Prep & PYQs (1.5h)", "Study", "school", 6, "10:20"),
            ("ExcelR Placement Prep", "Career", "laptop_mac", 6, "17:00"),
            ("High-Fiber & Protein Nutrition", "Health", "restaurant", 7, "13:00"),
            ("Gentle Stretching & Wind-down", "Wellness", "self_improvement", 7, "21:15"),
            ("Digestive & Symptom Log", "Health", "favorite", 7, "21:00")
        ]
        for title, cat, icon, days, rem in default_habits:
            h = HabitDefinition(
                user_id=user.id,
                title=title,
                category=cat,
                icon=icon,
                target_days_per_week=days,
                reminder_time=rem
            )
            db.add(h)

    # 4. Generate Prepopulated Schedule for the date
    generate_day_tasks(db, user.id, target_date)
    db.commit()


def generate_day_tasks(db: Session, user_id: int, task_date: date):
    # Check if tasks already exist for this date to prevent duplicate tasks
    existing_count = db.query(ScheduledTask).filter(
        ScheduledTask.user_id == user_id,
        ScheduledTask.date == task_date
    ).count()
    if existing_count > 0:
        return

    weekday = task_date.weekday()  # 0=Monday, 5=Saturday, 6=Sunday

    if weekday < 5:  # Monday to Friday
        schedule = [
            ("Wake up, drink water, and get daylight", "Morning", "06:30", 15, "high", "Start with a tall glass of room temperature water and natural light."),
            ("Home workout or brisk walking", "Health", "06:45 - 07:20", 35, "high", "Gentle mobility, brisk walk or bodyweight routine."),
            ("Bath, skincare, and breakfast", "Morning", "07:20 - 08:00", 40, "medium", "Nutritious breakfast with protein and fibre."),
            ("GATE CS focused study", "GATE", "08:00 - 10:00", 120, "high", "Deep focus block on priority GATE CS topics."),
            ("Break and optional snack", "Wellness", "10:00 - 10:20", 20, "low", "Hydrate, step away from screens, eat a fruit or nuts."),
            ("Semester subject study", "Semester", "10:20 - 12:00", 100, "high", "Seventh semester subject syllabus coverage."),
            ("Lunch and rest", "Wellness", "12:00 - 13:00", 60, "medium", "Balanced lunch, slow chewing, relaxation."),
            ("GATE practice and previous-year questions", "GATE", "13:00 - 14:30", 90, "high", "Solve PYQs with accuracy focus."),
            ("Break and movement", "Wellness", "14:30 - 15:00", 30, "low", "Gentle walk to relieve bloating and eye fatigue."),
            ("Semester revision or ExcelR practice", "Study", "15:00 - 16:00", 60, "medium", "Quick revision or coding assignments."),
            ("Snack and training preparation", "Wellness", "16:00 - 16:30", 30, "low", "Pre-training prep and hydration."),
            ("ExcelR placement training", "Placement", "17:00 - 20:00", 180, "high", "Live placement class / technical sessions."),
            ("Dinner", "Nutrition", "20:00 - 20:30", 30, "medium", "Light dinner, chew well to prevent nocturnal bloating."),
            ("Gentle walk if comfortable", "Health", "20:30 - 20:45", 15, "low", "15 min slow walk aids digestion and glucose control."),
            ("Light revision and planning", "Study", "20:45 - 21:15", 30, "medium", "Review today's takeaways and organize tomorrow's goals."),
            ("Relaxation, skincare, and bedtime routine", "Evening", "21:15 - 22:15", 60, "medium", "Skincare, digestive check-in, wind down."),
            ("Sleep", "Evening", "22:15", 480, "high", "Aim for 8 hours restful recovery.")
        ]
    elif weekday == 5:  # Saturday
        schedule = [
            ("Wake up", "Morning", "06:45", 15, "medium", "Gentle wake-up and hydration."),
            ("Gentle exercise", "Health", "07:00 - 07:30", 30, "medium", "Light mobility and stretching."),
            ("Bath, skincare, and breakfast", "Morning", "07:30 - 08:00", 30, "low", "Balanced morning meal."),
            ("GATE CS study", "GATE", "08:00 - 10:00", 120, "high", "Focused study on challenging concepts."),
            ("Break and snack", "Wellness", "10:00 - 10:30", 30, "low", "Rest and hydrate."),
            ("Semester study", "Semester", "10:30 - 12:00", 90, "high", "Focus on weakest semester subject."),
            ("Lunch and preparation", "Wellness", "12:00 - 13:00", 60, "medium", "Wholesome lunch and brief rest."),
            ("ExcelR placement training", "Placement", "14:00 - 17:00", 180, "high", "Weekend live technical session."),
            ("Snack and walk", "Health", "17:30 - 18:00", 30, "low", "Fresh air and gentle movement."),
            ("Optional GATE revision, depending on energy", "GATE", "18:00 - 19:30", 90, "medium", "Formula revision or light reading if feeling energized."),
            ("Dinner, relaxation, and sleep routine", "Evening", "20:00 - 22:15", 135, "medium", "Enjoy a relaxing evening and prepare for sleep.")
        ]
    else:  # Sunday (Recovery-friendly Day)
        schedule = [
            ("Wake up and gentle morning", "Morning", "07:30", 30, "medium", "Restful start without rush."),
            ("GATE mock test or previous-year questions", "GATE", "08:30 - 11:30", 180, "high", "Timed mock practice or PYQ test."),
            ("Analyse mistakes and revise weak topics", "GATE", "11:45 - 13:00", 75, "high", "Review wrong questions and note key formulas."),
            ("Lunch and rest", "Wellness", "13:00 - 14:00", 60, "medium", "Nourishing lunch."),
            ("Semester study and assignments", "Semester", "14:30 - 16:30", 120, "medium", "Complete pending semester lab works or assignments."),
            ("Meal prep, room organisation, and weekly planning", "Wellness", "16:30 - 18:00", 90, "medium", "Prepare outfits, organize desk, plan upcoming week."),
            ("Relaxation, optional walking, and light revision", "Evening", "18:30 - 20:30", 120, "low", "Training holiday - recharge body and mind."),
            ("Dinner and bedtime routine", "Evening", "20:30 - 22:15", 105, "medium", "Wind down and rest early for Monday.")
        ]

    for idx, (title, cat, time_str, duration, prio, notes) in enumerate(schedule):
        task = ScheduledTask(
            user_id=user_id,
            title=title,
            category=cat,
            date=task_date,
            scheduled_time=time_str,
            duration_minutes=duration,
            priority=prio,
            is_completed=False,
            notes=notes,
            recurring_rule="routine",
            is_custom=False,
            order_index=idx
        )
        db.add(task)
