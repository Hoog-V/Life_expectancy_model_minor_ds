# Main.py: # This Python file uses the following encoding: utf-8
import sys
from pathlib import Path

from PySide6.QtCore import QObject, Slot
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

import xgboost as xgb
import numpy as np
import pandas as pd  # Import pandas for DataFrame handling

# Define the indices corresponding to each feature
class DataIndex:
    GDP = 0
    MORTALITY_RATE = 1
    CLEAN_FUELS = 2
    UNDERFIVEDEATHS = 3
    FERTILITY_RATE = 4
    BASIC_SANITATION = 5
    ELECTRICITY = 6
    HEALTH_EXPENDITURE = 7

class PredictionBackend(QObject):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.model = self.load_model()

    def load_model(self):
        model = xgb.Booster()
        model_path = Path(__file__).resolve().parent / "model.json"  # Ensure 'model.json' is in the same directory
        try:
            model.load_model(str(model_path))
            print("Model loaded successfully.")
        except Exception as e:
            print(f"Error loading model: {e}")
        return model

    @Slot('QVariantList', result=str)
    def predictLifeExpectancy(self, inputData):
        # Convert QVariantList to Python list
        data = list(inputData)
        try:
            # Ensure all inputs are numeric
            data = [float(value) for value in data]
            
            # Apply log transformations to specific features
            # Ensure that these features are greater than 0 to avoid math errors
            if any(x <= 0 for x in [data[DataIndex.GDP], data[DataIndex.MORTALITY_RATE],
                                     data[DataIndex.CLEAN_FUELS], data[DataIndex.ELECTRICITY],
                                     data[DataIndex.HEALTH_EXPENDITURE]]):
                return "Invalid input data: Logarithm of non-positive number is undefined."
            
            data[DataIndex.GDP] = np.log(data[DataIndex.GDP])
            data[DataIndex.MORTALITY_RATE] = np.log(data[DataIndex.MORTALITY_RATE])
            data[DataIndex.CLEAN_FUELS] = np.log(data[DataIndex.CLEAN_FUELS])
            data[DataIndex.ELECTRICITY] = np.log(data[DataIndex.ELECTRICITY])
            data[DataIndex.HEALTH_EXPENDITURE] = np.log(data[DataIndex.HEALTH_EXPENDITURE])

            # Define feature names as per the model's training
            feature_names = ["GDP","MortRateAdult","CleanFuels","UnderFiveDeaths",
                             "FertilityRate","BasicSanitation","AccessElectricityRural",
                             "HealthExpenditure"]
            
            # Create a DataFrame with feature names
            df = pd.DataFrame([data], columns=feature_names)
            
            # Create DMatrix with feature names
            dmatrix = xgb.DMatrix(df)
            
            # Predict using the loaded model
            prediction = self.model.predict(dmatrix)
            
            # Assuming prediction is a single value
            predicted_value = float(prediction[0])
            return f"{predicted_value:.2f}"
        except (ValueError, IndexError) as e:
            print(f"Error during prediction: {e}")
            return "Invalid input data"
        except Exception as e:
            print(f"Unexpected error during prediction: {e}")
            return "Error: An unexpected error occurred."

if __name__ == "__main__":
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()

    # Create an instance of PredictionBackend
    backend = PredictionBackend()

    # Expose the backend to QML
    engine.rootContext().setContextProperty("backend", backend)

    qml_file = Path(__file__).resolve().parent / "main.qml"
    engine.load(str(qml_file))

    if not engine.rootObjects():
        sys.exit(-1)
    sys.exit(app.exec())
