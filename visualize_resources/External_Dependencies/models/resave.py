import numpy as np
import tensorflow as tf
from tensorflow import keras


def get_model():
    # Create a simple model.
    inputs = keras.Input(shape=(32,))
    outputs = keras.layers.Dense(1)(inputs)
    model = keras.Model(inputs, outputs)
    model.compile(optimizer="adam", loss="mean_squared_error")
    return model

model = get_model()

# It can be used to reconstruct the model identically.
model = keras.models.load_model("ffn_pretrained.h5")
tf.saved_model.save(model, "tmp_ffn")