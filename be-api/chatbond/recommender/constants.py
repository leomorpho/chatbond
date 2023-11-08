import os

from chatbond.config import (
    QUESTION_FEED_LIFESPAN_IN_MINUTES,
    TOTAL_NUM_QUESTIONS_IN_DAILY_FEED,
)

QUESTION_FEED_LIFESPAN_IN_MINUTES = QUESTION_FEED_LIFESPAN_IN_MINUTES
NUM_ONBOARDING_QUESTIONS = 15

# Distribution of question count in feed
NUM_QUESTIONS_IN_FEED_RANDOM = int(TOTAL_NUM_QUESTIONS_IN_DAILY_FEED / 3 * 2)
NUM_QUESTIONS_IN_FEED_SIMILAR_TO_TASTES = int(TOTAL_NUM_QUESTIONS_IN_DAILY_FEED / 3)

# NOTE: only scheduled tasks should write to the shared data volume. All
# app containers should only read from it.
SHARED_DATA_DIR = "/shared_data"
KMEANS_MODEL_PATH = os.path.join(SHARED_DATA_DIR, "kmeans_model")

ANNOY_LOCAL_MODEL_PATH = os.path.join(SHARED_DATA_DIR, "annoy")
ANNOY_INDEX_LOCAL_PATH = os.path.join(ANNOY_LOCAL_MODEL_PATH, "questions.ann")
ANNOY_INDEX_TO_ID_LOCAL_PATH = os.path.join(ANNOY_LOCAL_MODEL_PATH, "index_to_id.pkl")

MINI_LML6V2_ZIPPED_LOCAL_MODEL_PATH = os.path.join(
    SHARED_DATA_DIR, "sentence-transformers/all-MiniLM-L6-v2.zip"
)
MINI_LML6V2_UNZIPPED_LOCAL_MODEL_PATH = os.path.join(
    SHARED_DATA_DIR, "sentence-transformers/all-MiniLM-L6-v2"
)

ANNOY_QUESTION_INDEX_S3_FILE = "annoy/questions_index.ann"
ANNOY_QUESTION_INDEX_TO_ID_S3_FILE = "annoy/question_index_to_id_dict.pkl"

SENTENCE_TRANSFORMER_ALL_MINI_LML6V2_MODEL_S3_FILE = "all-MiniLM-L6-v2.zip"
ALL_MINI_LML6V2_SRC = "https://public.ukp.informatik.tu-darmstadt.de/reimers/sentence-transformers/v0.2/all-MiniLM-L6-v2.zip"


# TODO: this is used when a user doesn't yet have a question feed, when:
# 1. A user is onboarding
# 2. An error happened and somehow a user has no question feed. Used as a fallback.
DEFAULT_QUESTION_IDS = [
    "70891df6-b74c-479a-b314-b54835a43caf",  # How can we engage in more shared hobbies or interests?
    "3077a4e5-fd5d-4d40-bb0a-86f27900983c",  # How do you want to be remembered?
    "5a476dfa-093b-4615-a261-f1a749013ef7",  # What do you think is your greatest strength?
    "17de88eb-d9a8-49b1-a105-fc57adbacf00",  # What qualities do you look for in a partner?
    "2720e937-7473-4580-9f89-50db465ef019",  # If you could be in any comedy movie, which one and which character would you be?
    "58fde83f-de94-4ad7-8158-b2666a5176f1",  # If you could time travel to any place in the world, where would you want to go?
    "2c099889-d159-4ff8-818b-84c43724053b",  # What's your morning routine like?
    "eb40e1e4-6b23-4d3f-901c-4a0756a1fa1c",  # What would you do if fear wasn't holding you back?
    "79deb5e7-1e88-4b60-ae66-2140dc9ceac6",  # What's the craziest thing you've ever done for fun?
    "5e4d8fcf-ec2e-4086-8c88-60db425c486b",  # What's something you'd like to tell your future self?
    "f2a8fddc-ec7b-4a51-82fe-b27edd072250",  # What is something you wish you could go back and tell your younger self?
    "6a319910-0c16-4553-aa83-56310b202b26",  # What is something you wish you had said to someone who is no longer alive?
    "028abc95-1019-49d5-955b-795831602af8",  # What's something about me that you've come to appreciate?
    "b699245c-6240-4d5e-97f2-6c25c46d84bb",  # What are some of the challenges that your family has faced together?
    "b945eeeb-bd7c-4e3a-8e3c-98dc1d07cd48",  # How do you usually unwind after a long day?
    "b81f49f9-0f6a-40be-b40b-1da2d37adf4e",  # How do you prioritize your personal life without feeling guilty or stressed about work?
    "1df4ac02-16bb-4cf5-9140-3f9f9467e26d",  # What have you been doing to take care of yourself?
    "9e9a46ca-be85-4488-99a9-e090c7b19301",  # In what ways do you think pets enhance our lives?
    "f871542b-3b92-4e52-b320-8eaa13d98447",  # What is something that always uplifts your spirits?
    "62abdb0a-40b6-4ffe-832b-8202195e270f",  # What are your team management strategies?
    "badcc7e8-1752-4e78-aeea-ea8e37e79912",  # What is a value or belief that you think is important for a happy life?
    "911ab92f-f6e6-4915-9676-f8fb0bcb5359",  # How can you connect with more people in your community?
    "21fbfea4-1aec-41b1-9ab5-6cb052854bce",  # How do you think we can encourage people to be more environmentally friendly?
    "f8b09330-ace7-4d93-845f-4cb8614f8380",  # What are some fun activities you and your partner enjoy doing together?
    "b40a2b55-4f7b-4186-9235-dfa87c2c1294",  # How do you feel about sharing your dreams with others?
    "a45f3969-9f86-40d6-ad32-06d8a8d8cc2c",  # What is your idea of a successful relationship?
    "400e9695-f768-455b-9db3-3c5b00d11d21",  # How do you define your personal boundaries?
    "1594db7b-10f7-472a-8c26-34778bb3e1be",  # Can you describe a time when you achieved a goal you set for yourself?
    "5e1c5760-4ed3-476e-872f-08d90289c9f9",  # Do you have a dream hobby or interest that you have not yet pursued?
    "23f28cd3-082f-4d08-bf89-858c13f58ec7",  # What qualities do you admire most in your parents?
    "6047810f-1370-4203-b563-737eda713219",  # If you had a time machine, would you rather go back in time or visit the future?
    "c803756e-953d-4986-9719-4791cd7be93d",  # What's one thing that always makes you happy in our relationship?
    "e375b6a9-ffce-4d5b-a6ac-93eda7000b40",  # What's a moment when you felt like we were a great team?
    "ec89c2b1-d66b-4646-8779-31f324365d13",  # What's a way we can make our everyday lives more romantic?
    "dbe07bc5-0818-45a9-b425-209110fb0827",  # How can we keep each other motivated in achieving personal and shared goals?
    "232c77a7-e778-4760-b3dc-1740df72153b",  # What are some of your favorite self-care practices?
    "cee614c5-f73c-4e6b-9fbf-9b6989a88811",  # Have you had any big realizations or aha moments lately?
    "9cb561ee-9e59-4627-9b6e-5a8e1c1fef5b",  # How have your life experiences influenced your worldview?
    "cac40ccf-7e43-4298-8e12-594a9802e000",  # What are some things that you feel like I could improve on in our relationship?
    "0888b31b-2c2f-4814-ada9-c87d5d8d266d",  # Do you like trying new foods or sticking to the ones you know?
    "f0725584-a570-4b5e-b300-b4a36d82047d",  # What religious or spiritual practices do you engage in regularly?
    "c2ea14a7-b307-4337-9232-fdaa65cf243f",  # How can you stay focused and avoid distractions that might prevent you from reaching your goals?
    "4a2e073c-aae6-40a8-b5c5-da6dd276617b",  # What is your go-to stress-relief technique when you're feeling overwhelmed?
    "e4b91063-a2c2-4b83-87d9-a4298bcecc69",  # How do you envision our life five years from now?
    "f8a4013c-3ec4-4486-95ac-0b1af6d97811",  # What are the things in your life that make you feel the most connected?
    "4d527df6-486e-4d8d-a7e4-ab576e3804ad",  # What is a personal habit you'd like to break?
    "f64c1d8e-c7c6-4179-bf0a-351992dab4c7",  # What motivates you to be your best self?
    "ac51b931-e999-4efb-81a2-2eb5c01dd616",  # What are three things you're grateful for in your life?
    "55529f68-ea2e-4894-9f87-252f1eee7b4d",  # What is one mistake you've made that you've been able to laugh about?
    "89a1748a-744b-45cb-8752-a5884bcf7157",  # How do you handle disagreements in a relationship?
    "24ed19cf-95c2-4146-b3f4-0671d5eaeaf4",  # Which movie do you think has the best soundtrack and why?
    "c38cea40-e4d3-44b1-8156-7bce51e5f98a",  # How do you respond when someone is vulnerable with you?
    "776a93d8-50cb-4cd3-9f24-817dfb3f2f47",  # How can you cultivate courage?
    "01526cc6-6022-4db0-b83f-64b6bc55b82e",  # What is the best thing that happened to you this week?
    "78981576-3a27-4695-8d15-ddadc8711efe",  # What is something unique about your cultural heritage that you are proud of?
    "a37b22cb-7b77-4dbf-a04d-9986482d0889",  # What are your coping mechanisms when dealing with setbacks?
    "c2c8d909-4345-4d68-b56e-1e2d5290e836",  # Can you describe a time when you had to forgive someone?
    "7e7178b2-34f5-436c-8d1f-3601f91c3ec5",  # What is a childhood memory that you wish you could relive?
    "af15c272-c830-44e6-bde1-a12e90a4746b",  # What do you think you could do to cultivate more mindfulness in your daily life?
    "ef3b327c-570d-4203-800e-1317230e86c0",  # What is one risk you regret not taking?
    "a4d193ef-aa7b-43c8-a990-fd27cd86092c",  # If you could have dinner with any historical figure, who would it be?
]
