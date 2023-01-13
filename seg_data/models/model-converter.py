import tensorflow as tf

# Load the model
model = tf.keras.models.load_model('unet3_pretrained.h5')

# save the model
model.save("unet/")

# load the weights in h5 format
model.load_weights("unet_weights/unet_weights_retrain_step1.h5")

# Save the model weights in TensorFlow format
model.save_weights('unet-weights/weights', save_format='tf')