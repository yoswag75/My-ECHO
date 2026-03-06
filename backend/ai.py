import json
import random
import os
from google import genai
from config import settings
from prompts import ANALYSIS_PROMPT, COACH_PROMPT

# --- Configuration & Setup ---
client = None
available_models = []

if settings.GEMINI_API_KEY:
    try:
        # Initialize client
        client = genai.Client(api_key=settings.GEMINI_API_KEY)
        
        try:
            models_iter = client.models.list()
            for m in models_iter:
                # Safer introspection to avoid AttributeError
                m_name = getattr(m, 'name', None)
                if not m_name:
                    continue
                    
                # Check capabilities if possible, otherwise assume it's valid if it has "gemini" in name
                methods = getattr(m, 'supported_generation_methods', [])
                
                if 'generateContent' in methods or 'gemini' in m_name.lower():
                    # Strip 'models/' prefix if present for cleaner list
                    clean_name = m_name.replace('models/', '')
                    available_models.append(clean_name)
            
        except Exception as e:
            print(f"Warning: Could not list models (Auth might be partial): {e}")
            # Fallback list if we can't query
            available_models = ['gemini-3-flash','Gemini 2.5 Flash','Gemini 2.5 Flash Lite','Gemini 2.5 Flash TTS','Gemma 3 27B','Gemma 3 12B']

    except Exception as e:
        print(f"Failed to initialize Gemini Client: {e}")

def clean_json_text(text: str) -> str:
    """Helper to strip markdown code blocks from LLM response"""
    if not text:
        return "{}"
    text = text.strip()
    if text.startswith("```json"):
        text = text[7:]
    elif text.startswith("```"):
        text = text[3:]
    if text.endswith("```"):
        text = text[:-3]
    return text.strip()

def generate_content_with_fallback(prompt: str):
    """
    Tries multiple model names until one works.
    """
    # Priority list based on your specific access logs
    preferred_order = available_models
    
    valid_candidates = []
    
    # 1. Filter: Match preferred models against what we actually have
    if available_models:
        for pref in preferred_order:
            if pref in available_models:
                valid_candidates.append(pref)
        
        # 2. Dynamic: If no exact preferred match, grab ANY 'flash' model
        if not valid_candidates:
            valid_candidates = [m for m in available_models if 'flash' in m]
            
        # 3. Last Resort: If still empty, just try the first available model
        if not valid_candidates and len(available_models) > 0:
            valid_candidates.append(available_models[0])

    # 4. Fallback: If discovery failed completely, use the hardcoded list
    if not valid_candidates: 
        valid_candidates = preferred_order

    last_error = None

    for model_name in valid_candidates:
        try:
            # print(f"Attempting AI call with model: {model_name}") 
            response = client.models.generate_content(
                model=model_name,
                contents=prompt
            )
            if response.text:
                return response
        except Exception as e:
            print(f"Model {model_name} failed: {e}")
            last_error = e
            continue
    
    # If all failed, raise the last error
    if last_error:
        print("All AI models failed.")
        raise last_error
    return None

def analyze_entry_gemini(text: str):
    """
    Calls Gemini to analyze the journal entry.
    """
    try:
        final_prompt = ANALYSIS_PROMPT.format(entry_text=text)
        
        response = generate_content_with_fallback(final_prompt)
        
        if not response or not response.text:
            return analyze_entry_stub(text)

        cleaned_text = clean_json_text(response.text)
        try:
            data = json.loads(cleaned_text)
        except json.JSONDecodeError:
            return analyze_entry_stub(text)
        
        return {
            "emotions": data.get("emotions", ["Neutral"]),
            "themes": data.get("themes", ["Daily Life"]),
            "reflection": data.get("reflection", "Keep writing to discover more about yourself."),
            "people": data.get("people", [])
        }
    except Exception as e:
        print(f"Gemini API All Models Failed: {e}")
        return analyze_entry_stub(text)

def generate_weekly_goal_gemini(emotions_summary: list, themes_summary: list):
    try:
        final_prompt = COACH_PROMPT.format(
            emotions_summary=json.dumps(emotions_summary), 
            themes_summary=json.dumps(themes_summary)
        )
        
        response = generate_content_with_fallback(final_prompt)

        if not response or not response.text:
            return generate_weekly_goal_stub(emotions_summary, themes_summary)

        cleaned_text = clean_json_text(response.text)
        try:
            data = json.loads(cleaned_text)
        except json.JSONDecodeError:
            return generate_weekly_goal_stub(emotions_summary, themes_summary)

        return {
            "title": data.get("title", "Reflecting on the Week"),
            "insight": data.get("insight", "You've had a varied week."),
            "advice": data.get("advice", "Continue to monitor your feelings.")
        }
    except Exception as e:
        print(f"Gemini API Coach Error: {e}")
        return generate_weekly_goal_stub(emotions_summary, themes_summary)

# --- STUB (Fallback) ---
def analyze_entry_stub(text: str):
    """Fallback logic if API fails or no key provided"""
    text_lower = text.lower()
    emotions = []
    if any(w in text_lower for w in ["happy", "joy", "good"]): emotions.append("Joy")
    if any(w in text_lower for w in ["sad", "bad", "tired"]): emotions.append("Sadness")
    if not emotions: emotions = ["Neutral"]

    themes = ["Daily Life"]
    if "work" in text_lower: themes.append("Work")

    return {
        "emotions": emotions,
        "themes": themes,
        "reflection": "This is a local fallback analysis because the AI key was missing or invalid.",
        "people": []
    }

def generate_weekly_goal_stub(emotions, themes):
    return {
        "title": "Offline Insights",
        "insight": "We couldn't reach the AI coach right now.",
        "advice": "Take a moment to read through your entries from this week."
    }

# --- Main Wrapper ---
def analyze_entry(text: str):
    if settings.USE_REAL_AI and settings.GEMINI_API_KEY and client:
        return analyze_entry_gemini(text)
    return analyze_entry_stub(text)

def generate_weekly_goal(emotions, themes):
    if settings.USE_REAL_AI and settings.GEMINI_API_KEY and client:
        return generate_weekly_goal_gemini(emotions, themes)
    return generate_weekly_goal_stub(emotions, themes)