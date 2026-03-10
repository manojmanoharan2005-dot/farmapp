"""
Smart Farming Assistant - Crop Recommendation Model Training
Loads data, trains the RandomForest model, and saves the trained model + scaler.
"""

import os
import sys
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import StandardScaler
import joblib


class CropModelTrainer:
    def __init__(self):
        self.model = RandomForestClassifier(n_estimators=100, random_state=42)
        self.scaler = StandardScaler()
        self.feature_names = ['N', 'P', 'K', 'temperature', 'humidity', 'ph', 'rainfall']
        self.target_name = 'label'

    def load_data(self, file_path):
        """Load and prepare the dataset"""
        try:
            self.data = pd.read_csv(file_path)
            print("[SUCCESS] Dataset loaded successfully!")
            print(f"Dataset shape: {self.data.shape}")
            print(f"Columns: {list(self.data.columns)}")
            return True
        except Exception as e:
            print(f"[ERROR] Error loading dataset: {e}")
            return False

    def explore_data(self):
        """Explore the dataset"""
        print("\n" + "=" * 60)
        print("DATASET EXPLORATION")
        print("=" * 60)

        print(f"\nDataset Info:")
        print(f"  Total samples: {len(self.data)}")
        print(f"  Total features: {len(self.feature_names)}")
        print(f"  Target classes: {self.data['label'].nunique()}")

        print(f"\nStatistical Summary:")
        stats = self.data[self.feature_names].describe()
        for feature in self.feature_names:
            row = stats[feature]
            print(f"  {feature}: min={row['min']:.2f}, max={row['max']:.2f}, mean={row['mean']:.2f}")

        missing_values = self.data.isnull().sum().sum()
        print(f"\nMissing Values: {missing_values}")

        print(f"\nCrop Distribution:")
        class_counts = self.data['label'].value_counts()
        for crop, count in class_counts.head(10).items():
            print(f"  {crop.capitalize()}: {count} samples")

        print(f"\nTotal unique crops: {len(class_counts)}")
        return class_counts

    def prepare_data(self, test_size=0.2, validation_size=0.1):
        """Split data into train, validation, and test sets"""
        X = self.data[self.feature_names]
        y = self.data[self.target_name]

        X_temp, X_test, y_temp, y_test = train_test_split(
            X, y, test_size=test_size, random_state=42, stratify=y
        )

        val_size_adjusted = validation_size / (1 - test_size)
        X_train, X_val, y_train, y_val = train_test_split(
            X_temp, y_temp, test_size=val_size_adjusted, random_state=42, stratify=y_temp
        )

        print(f"\nData Split:")
        print(f"  Training set:   {X_train.shape[0]} samples ({X_train.shape[0] / len(self.data) * 100:.1f}%)")
        print(f"  Validation set: {X_val.shape[0]} samples ({X_val.shape[0] / len(self.data) * 100:.1f}%)")
        print(f"  Test set:       {X_test.shape[0]} samples ({X_test.shape[0] / len(self.data) * 100:.1f}%)")

        X_train_scaled = self.scaler.fit_transform(X_train)
        X_val_scaled = self.scaler.transform(X_val)
        X_test_scaled = self.scaler.transform(X_test)

        return (X_train_scaled, X_val_scaled, X_test_scaled,
                y_train, y_val, y_test)

    def train_model(self, X_train, y_train):
        """Train the Random Forest model"""
        print("\n" + "=" * 60)
        print("TRAINING MODEL")
        print("=" * 60)

        print("Training Random Forest Classifier...")
        self.model.fit(X_train, y_train)
        print("[SUCCESS] Model training completed!")

        feature_importance = pd.DataFrame({
            'feature': self.feature_names,
            'importance': self.model.feature_importances_
        }).sort_values('importance', ascending=False)

        print(f"\nFeature Importance:")
        for _, row in feature_importance.iterrows():
            print(f"  {row['feature']}: {row['importance']:.4f}")

        return feature_importance

    def save_model(self, model_dir="ml_models"):
        """Save the trained model and scaler"""
        os.makedirs(model_dir, exist_ok=True)

        model_path = os.path.join(model_dir, 'crop_recommendation_model.joblib')
        scaler_path = os.path.join(model_dir, 'feature_scaler.joblib')

        joblib.dump(self.model, model_path)
        joblib.dump(self.scaler, scaler_path)

        print(f"\nMODEL SAVED SUCCESSFULLY!")
        print(f"  Model:  {model_path}")
        print(f"  Scaler: {scaler_path}")


def main():
    """Main training pipeline"""
    print("=" * 60)
    print("SMART CROP RECOMMENDATION - TRAINING PIPELINE")
    print("=" * 60)

    trainer = CropModelTrainer()

    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    dataset_path = os.path.join(base_dir, "datasets", "Crop_recommendation.csv")

    if not trainer.load_data(dataset_path):
        print("[ERROR] Failed to load dataset. Please check the file path.")
        return

    trainer.explore_data()

    X_train, X_val, X_test, y_train, y_val, y_test = trainer.prepare_data()

    trainer.train_model(X_train, y_train)

    model_dir = os.path.join(base_dir, "ml_models")
    trainer.save_model(model_dir=model_dir)

    print("\nTraining pipeline completed successfully!")


if __name__ == "__main__":
    main()
