
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras.preprocessing.text import Tokenizer
from tensorflow.keras.preprocessing.sequence import pad_sequences
import numpy as np
import json
import os

# 1. Synthetic Dataset
print("Generating synthetic dataset...")
data = [
    # SAFE (0)
    ("Your account XXXXX1234 has been credited with Rs. 5000.00 via UPI.", 0),
    ("Transaction of Rs. 250.00 using A/c XX1234 at STARBUCKS was successful.", 0),
    ("Dear Customer, your stmt for Ac XX1234 is sent to your email.", 0),
    ("OTP for transaction on Amazon is 123456. Do not share this.", 0),
    ("Your SIP installment of Rs. 2000 has been processed.", 0),
    ("Payment of Rs. 1200 received from Rahul via UPI.", 0),
    ("Your account balance is Rs. 15,400.00.", 0),
    ("Withdrawal of Rs. 10,000 from ATM was successful.", 0),
    
    # SUSPICIOUS (1)
    ("Congratulations! You won a lottery of Rs. 1 Lakh. Call now to claim.", 1),
    ("You are eligible for a pre-approved loan of 5 Lakhs. Click here to apply.", 1),
    ("Claim your free gift card worth Rs. 5000 today! Offer valid for 24 hours.", 1),
    ("Your mobile number has won a prize. Contact us to receive it.", 1),
    ("Instant loan approval in 5 mins. No documents required.", 1),
    
    # HIGH RISK SCAM (2)
    ("URGENT: Your bank account will be suspended. Update KYC immediately via this link: http://bit.ly/fake", 2),
    ("Your electricity connection will be cut tonight. Pay pending bill immediately at 9876543210.", 2),
    ("Account BLOCKED due to suspicious activity. Verify details here: http://scam.site", 2),
    ("Dear User, your PAN card is not linked. Your account will be frozen today. Click link.", 2),
    ("Verify your identity immediately or face legal action.", 2),
]

sentences = [d[0] for d in data]
labels = [d[1] for d in data]
labels = np.array(labels)

# 2. Preprocessing
vocab_size = 1000
embedding_dim = 16
max_length = 20
trunc_type='post'
padding_type='post'
oov_tok = "<OOV>"

tokenizer = Tokenizer(num_words=vocab_size, oov_token=oov_tok)
tokenizer.fit_on_texts(sentences)
word_index = tokenizer.word_index
sequences = tokenizer.texts_to_sequences(sentences)
padded = pad_sequences(sequences, maxlen=max_length, padding=padding_type, truncating=trunc_type)

# Determine correct paths specific to where the script is located
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(script_dir)
output_dir = os.path.join(project_root, 'assets', 'models')
os.makedirs(output_dir, exist_ok=True)

vocab_path = os.path.join(output_dir, 'vocab.txt')
model_path = os.path.join(output_dir, 'scam_detector.tflite')

# Save Vocab (Dictionary) for Flutter
vocab_list = ["" for _ in range(vocab_size)]
for word, index in word_index.items():
    if index < vocab_size:
        vocab_list[index] = word

# Correcting vocab export format for simple usage
with open(vocab_path, 'w', encoding='utf-8') as f:
    for word in vocab_list:
        f.write(word + '\n')

print(f"Vocabulary saved to {vocab_path}")

# 3. Model Definition
model = tf.keras.Sequential([
    tf.keras.layers.Embedding(vocab_size, embedding_dim, input_length=max_length),
    tf.keras.layers.GlobalAveragePooling1D(),
    tf.keras.layers.Dense(24, activation='relu'),
    tf.keras.layers.Dense(3, activation='softmax') # 3 classes: Safe, Suspicious, Scam
])

model.compile(loss='sparse_categorical_crossentropy',optimizer='adam',metrics=['accuracy'])

# 4. Training
print("Training model...")
num_epochs = 50
history = model.fit(padded, labels, epochs=num_epochs, verbose=0)
print("Training complete.")

# 5. Convert to TFLite
print("Converting to TFLite...")
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

# 6. Save Model
with open(model_path, 'wb') as f:
    f.write(tflite_model)

print(f"Model saved to {model_path}")

# Verification of output shape/signature for Flutter implementation reference
interpreter = tf.lite.Interpreter(model_content=tflite_model)
interpreter.allocate_tensors()
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()
print("Input shape:", input_details[0]['shape'])
print("Output shape:", output_details[0]['shape'])
