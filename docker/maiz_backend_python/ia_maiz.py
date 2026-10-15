import os
import io
import numpy as np
import tensorflow as tf
from PIL import Image


class CornDiagnosisModel:

    def __init__(self):
        # Soportar dos tipos de modelos: 'enfermedad' (default) y 'plaga'
        self.interpreters = {}
        self.input_details = {}
        self.output_details = {}
        self.labels = {}

        # Cargar modelo de enfermedades si existe
        try:
            if os.path.exists("modelo_maiz.tflite"):
                interp = tf.lite.Interpreter(model_path="modelo_maiz.tflite")
                interp.allocate_tensors()
                self.interpreters['enfermedad'] = interp
                self.input_details['enfermedad'] = interp.get_input_details()
                self.output_details['enfermedad'] = interp.get_output_details()
                if os.path.exists("labels.txt"):
                    with open("labels.txt", "r") as f:
                        self.labels['enfermedad'] = [line.strip() for line in f.readlines()]
                print("✔ Modelo enfermedad cargado")
        except Exception as e:
            print("No se pudo cargar modelo enfermedad:", e)

        # Cargar modelo de plagas si existe
        try:
            if os.path.exists("modelo_plagas.tflite"):
                interp = tf.lite.Interpreter(model_path="modelo_plagas.tflite")
                interp.allocate_tensors()
                self.interpreters['plaga'] = interp
                self.input_details['plaga'] = interp.get_input_details()
                self.output_details['plaga'] = interp.get_output_details()
                if os.path.exists("labels_plagas.txt"):
                    with open("labels_plagas.txt", "r") as f:
                        self.labels['plaga'] = [line.strip() for line in f.readlines()]
                print("✔ Modelo plaga cargado")
        except Exception as e:
            print("No se pudo cargar modelo plaga:", e)

        if not self.interpreters:
            print("⚠ Ningún modelo cargado: revisa los archivos .tflite y labels")

    def preprocess_image(self, img_bytes):
        image = Image.open(io.BytesIO(img_bytes)).convert("RGB")
        image = image.resize((224, 224))
        img_array = np.array(image, dtype=np.float32)
        img_array = img_array / 255.0
        img_array = np.expand_dims(img_array, axis=0)
        return img_array

    def predict(self, img_bytes, tipo='enfermedad'):
        tipo = (tipo or 'enfermedad').lower()
        tipo_key = 'plaga' if tipo.startswith('plag') else 'enfermedad'

        # seleccionar interpreter y labels
        interpreter = self.interpreters.get(tipo_key) or self.interpreters.get('enfermedad')
        labels = self.labels.get(tipo_key) or self.labels.get('enfermedad')

        if interpreter is None:
            raise ValueError('No hay modelo disponible para el tipo solicitado')

        input_det = self.input_details[tipo_key]
        output_det = self.output_details[tipo_key]

        img_array = self.preprocess_image(img_bytes)

        interpreter.set_tensor(input_det[0]['index'], img_array)
        interpreter.invoke()

        predictions = interpreter.get_tensor(output_det[0]['index'])[0]
        label_index = int(np.argmax(predictions))
        disease = labels[label_index] if labels and label_index < len(labels) else str(label_index)
        confidence = float(np.max(predictions))
        is_corn_leaf = disease != "no_maiz"

        advice = self.get_recommendation(disease)

        return {
            "disease": disease,
            "confidence": confidence,
            "advice": advice,
            "is_corn_leaf": is_corn_leaf
        }

    def get_recommendation(self, disease):
        recommendations = {
            "hoja_sana": "La hoja está sana. Mantenga buenas prácticas agrícolas.",
            "mancha_gris": "Aplicar fungicidas a base de estrobilurinas.",
            "tizon": "Usar control preventivo con productos cúpricos.",
            "roya": "Aplicar fungicidas sistémicos y retirar hojas infectadas.",
            "no_maiz": "La imagen no es de hoja de maíz. Intente otra foto."
        }
        return recommendations.get(disease, "Sin recomendación disponible.")
