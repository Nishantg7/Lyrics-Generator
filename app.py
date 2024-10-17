from typing import List, Optional
import json
import os
from pydantic import BaseModel
from groq import Groq
from flask import Flask, request, jsonify
from flask_cors import CORS  # Import CORS
from dotenv import load_dotenv
load_dotenv()
app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Initialize the GROQ client with your API key
api_key = os.environ.get("GROQ_API_KEY")
groq = Groq(api_key=api_key)

# Data model for song lyrics
class Lyrics(BaseModel):
    title: str
    genre: str
    language: str  # Language of the song
    content: str   # Lyrics of the song

def get_lyrics(title: str, genre: str, language: str, description: Optional[str] = None) -> Lyrics:
    # Modify the prompt based on the language
    if language.lower() == "hindi":
        prompt = f"Write a song titled '{title}' in the genre of '{genre}' in Hindi language but use Roman (English) letters."
    else:
        prompt = f'''
        Create a unique and memorable set of song lyrics based on the following criteria:

1. Language: Generate the lyrics in a conversational, poetic form typical of {language}, but written phonetically in English letters if it is a non-English language. Make sure that the lyrics retain the cultural tone, phrasing, and nuance of the specified language.

2. Genre: Style the lyrics according to {genre}, matching the common themes, rhythm, and lyrical patterns often associated with this genre. For instance:
   - If the genre is Rock, make the lyrics energetic and evocative, emphasizing themes like rebellion or resilience.
   - For Pop, aim for catchy, simple lines that are emotionally engaging and widely relatable.
   - If Hip-Hop is chosen, use rhythmic flow, wordplay, and themes that reflect storytelling or personal expression.
   - For Country, incorporate narrative storytelling and imagery of nature or small-town life.
   - Adjust for other genres similarly, focusing on iconic stylistic markers.

Example Output:

   Verse 1:
   Incorporate introductory lines that establish the mood and introduce the theme in a culturally relevant style. For instance, if the theme is love, introduce a heartfelt line with imagery that reflects the chosen genre.

   Chorus:
   Create a catchy, repetitive line that captures the song’s main message, ideal for sing-along moments. The chorus should enhance the song’s emotional climax, in line with the genre and theme.

   Verse 2 and Bridge:
   Continue developing the song’s story or mood, adding unique phrases or rhymes that elevate the lyrics. Use language and phrasing that feel authentic and immersive.

   End with a closing line or phrase that resonates emotionally and leaves a lasting impression, suitable for the song’s message.
        '''
        # Include the description in the prompt if provided
        if description:
            prompt += f"\n\nTheme/Description: {description}"

    chat_completion = groq.chat.completions.create(
        messages=[
            {
                "role": "system",
                "content": "You are a highly creative and structured lyric generator. Your task is to produce unique song lyrics formatted strictly in JSON based on provided input for language, genre, and theme. Your output must strictly use the JSON schema provided below, and each section (verse, chorus, etc.) should align with the specified genre style. Ensure that the lyrics are written phonetically in English if the language is non-English. Use culturally appropriate phrases, maintaining the emotional tone and rhythm expected in each genre.\n\n"
                f"The JSON object must strictly use the schema: {json.dumps(Lyrics.model_json_schema(), indent=2)}",
            },
            {
                "role": "user",
                "content": f"{prompt}\n\nPlease return the output strictly in JSON format with the key 'content'.",
            },
        ],
        model="llama-3.1-70b-versatile",
        temperature=0.7,
        stream=False,
        response_format={"type": "json_object"},
    )

    # Validate and return the lyrics
    return Lyrics.model_validate_json(chat_completion.choices[0].message.content)

@app.route('/generate_lyrics', methods=['POST'])
def generate_lyrics_endpoint():
    data = request.get_json()
    title = data.get('title')
    genre = data.get('genre')
    language = data.get('language')
    description = data.get('description', '')

    # Get lyrics using the provided inputs
    try:
        lyrics = get_lyrics(title, genre, language, description)
        return jsonify(lyrics.model_dump()), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get("PORT", 5000)))
