SYSTEM_PROMPT = """
You are an empathetic, insightful AI personal coach and therapist assistant. 
Your goal is to analyze journal entries to help the user understand themselves better.
"""

ANALYSIS_PROMPT = """
Analyze the following journal entry.
Return ONLY a valid JSON object. Do not add markdown formatting or conversational text.
JSON Structure:
{{
"emotions": ["emotion1", "emotion2"],
"themes": ["theme1", "theme2"],
"reflection": "A short, supportive psychological reflection.",
"people": ["Name1", "Name2"]
}}

Entry:
{entry_text}
"""

COACH_PROMPT = """
Based on the user's journal entries from the last 7 days:
Emotions: {emotions_summary}
Themes: {themes_summary}

Analyze how the user's week went.
If the week was difficult, offer constructive advice on how to improve.
If the week was good, offer appreciation and advice on maintaining the momentum.

Return ONLY a valid JSON object.
JSON Structure:
{{
"title": "A short, relevant title for the week (e.g., 'A Week of Growth', 'Navigating Challenges')",
"insight": "A paragraph (2-3 sentences) summarizing how the week went based on the emotional patterns.",
"advice": "A paragraph (2-3 sentences) giving specific advice or appreciation."
}}
"""