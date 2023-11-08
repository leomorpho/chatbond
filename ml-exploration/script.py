from sentence_transformers import SentenceTransformer

from data.questions import questions

model = SentenceTransformer("all-mpnet-base-v2")

from sentence_transformers import util

# Encode all sentences
embeddings = model.encode(questions)

# Compute cosine similarity between all pairs
cos_sim = util.cos_sim(embeddings, embeddings)

# Add all pairs to a list with their cosine similarity score
all_sentence_combinations = []
for i in range(len(cos_sim) - 1):
    for j in range(i + 1, len(cos_sim)):
        all_sentence_combinations.append([cos_sim[i][j], i, j])

# Sort list by the highest cosine similarity score
all_sentence_combinations = sorted(
    all_sentence_combinations, key=lambda x: x[0], reverse=True
)
print(all_sentence_combinations)

result = []
for score, i, j in all_sentence_combinations[0:1000]:
    result.append(
        {
            "question1": questions[i],
            "question2": questions[j],
            "similarity": cos_sim[i][j],
        }
    )

print(result)


with open("output.txt", "w") as f:
    # Write list to file as JSON
    f.write(str(result))
