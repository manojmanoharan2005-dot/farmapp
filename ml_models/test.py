"""
Smart Farming Assistant - Crop Recommendation Model Testing
Loads the trained model and evaluates it on test data with detailed metrics.
"""

import os
import sys
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import (
    accuracy_score, precision_score, recall_score, f1_score,
    classification_report, confusion_matrix
)
import joblib


class CropModelTester:
    def __init__(self, model_dir=None):
        if model_dir is None:
            model_dir = os.path.dirname(os.path.abspath(__file__))

        model_path = os.path.join(model_dir, 'crop_recommendation_model.joblib')
        scaler_path = os.path.join(model_dir, 'feature_scaler.joblib')

        self.model = joblib.load(model_path)
        self.scaler = joblib.load(scaler_path)
        self.feature_names = ['N', 'P', 'K', 'temperature', 'humidity', 'ph', 'rainfall']
        self.target_name = 'label'
        print(f"[SUCCESS] Model and scaler loaded from {model_dir}")

    def load_and_split_data(self, file_path, test_size=0.2, validation_size=0.1):
        """Load data and recreate the same train/val/test split used during training"""
        self.data = pd.read_csv(file_path)
        X = self.data[self.feature_names]
        y = self.data[self.target_name]

        X_temp, X_test, y_temp, y_test = train_test_split(
            X, y, test_size=test_size, random_state=42, stratify=y
        )

        val_size_adjusted = validation_size / (1 - test_size)
        X_train, X_val, y_train, y_val = train_test_split(
            X_temp, y_temp, test_size=val_size_adjusted, random_state=42, stratify=y_temp
        )

        X_val_scaled = self.scaler.transform(X_val)
        X_test_scaled = self.scaler.transform(X_test)

        return X_val_scaled, X_test_scaled, y_val, y_test

    def validate_model(self, X_val, y_val):
        """Validate model on the validation set"""
        print("\n" + "=" * 60)
        print("MODEL VALIDATION")
        print("=" * 60)

        y_val_pred = self.model.predict(X_val)

        val_accuracy = accuracy_score(y_val, y_val_pred)
        val_precision = precision_score(y_val, y_val_pred, average='weighted')
        val_recall = recall_score(y_val, y_val_pred, average='weighted')
        val_f1 = f1_score(y_val, y_val_pred, average='weighted')

        print(f"Validation Results:")
        print(f"  Accuracy:  {val_accuracy:.4f} ({val_accuracy * 100:.2f}%)")
        print(f"  Precision: {val_precision:.4f} ({val_precision * 100:.2f}%)")
        print(f"  Recall:    {val_recall:.4f} ({val_recall * 100:.2f}%)")
        print(f"  F1-Score:  {val_f1:.4f} ({val_f1 * 100:.2f}%)")

        return {
            'accuracy': val_accuracy,
            'precision': val_precision,
            'recall': val_recall,
            'f1_score': val_f1
        }

    def test_model(self, X_test, y_test):
        """Test model on the test set with full metrics"""
        print("\n" + "=" * 60)
        print("FINAL MODEL TESTING")
        print("=" * 60)

        y_test_pred = self.model.predict(X_test)

        test_accuracy = accuracy_score(y_test, y_test_pred)
        test_precision = precision_score(y_test, y_test_pred, average='weighted')
        test_recall = recall_score(y_test, y_test_pred, average='weighted')
        test_f1 = f1_score(y_test, y_test_pred, average='weighted')

        precision_per_class = precision_score(y_test, y_test_pred, average=None)
        recall_per_class = recall_score(y_test, y_test_pred, average=None)
        f1_per_class = f1_score(y_test, y_test_pred, average=None)

        print(f"FINAL TEST RESULTS:")
        print(f"  Accuracy:  {test_accuracy:.4f} ({test_accuracy * 100:.2f}%)")
        print(f"  Precision: {test_precision:.4f} ({test_precision * 100:.2f}%)")
        print(f"  Recall:    {test_recall:.4f} ({test_recall * 100:.2f}%)")
        print(f"  F1-Score:  {test_f1:.4f} ({test_f1 * 100:.2f}%)")

        cm = confusion_matrix(y_test, y_test_pred)
        report = classification_report(y_test, y_test_pred, output_dict=True)

        crop_scores = []
        for crop in report.keys():
            if crop not in ['accuracy', 'macro avg', 'weighted avg']:
                crop_scores.append((crop, report[crop]['f1-score']))

        crop_scores.sort(key=lambda x: x[1], reverse=True)
        print(f"\nTop 5 Best Predicted Crops:")
        for i, (crop, f1) in enumerate(crop_scores[:5], 1):
            print(f"  {i}. {crop.capitalize()}: F1={f1:.4f}")

        return {
            'accuracy': test_accuracy,
            'precision': test_precision,
            'recall': test_recall,
            'f1_score': test_f1,
            'precision_per_class': precision_per_class,
            'recall_per_class': recall_per_class,
            'f1_per_class': f1_per_class,
            'confusion_matrix': cm,
            'y_true': y_test,
            'y_pred': y_test_pred
        }

    def analyze_results(self, test_results):
        """Analyze and interpret the test results"""
        print("\n" + "=" * 60)
        print("RESULTS ANALYSIS")
        print("=" * 60)

        accuracy = test_results['accuracy']
        precision = test_results['precision']
        recall = test_results['recall']
        f1 = test_results['f1_score']

        print(f"\nMODEL PERFORMANCE SUMMARY:")
        print(f"  Accuracy:  {accuracy:.4f} ({accuracy * 100:.2f}%)")
        print(f"  Precision: {precision:.4f} ({precision * 100:.2f}%)")
        print(f"  Recall:    {recall:.4f} ({recall * 100:.2f}%)")
        print(f"  F1-Score:  {f1:.4f} ({f1 * 100:.2f}%)")

        # Accuracy interpretation
        if accuracy >= 0.95:
            print(f"\n  Accuracy: EXCELLENT - Model shows outstanding accuracy!")
        elif accuracy >= 0.90:
            print(f"\n  Accuracy: VERY GOOD - Strong predictive performance")
        elif accuracy >= 0.85:
            print(f"\n  Accuracy: GOOD - Reliable for most farming scenarios")
        elif accuracy >= 0.80:
            print(f"\n  Accuracy: FAIR - Consider feature engineering")
        else:
            print(f"\n  Accuracy: NEEDS IMPROVEMENT")

        # Precision interpretation
        if precision >= 0.95:
            print(f"  Precision: Very few false recommendations - highly trustworthy")
        elif precision >= 0.90:
            print(f"  Precision: Low false positive rate - recommendations are reliable")
        else:
            print(f"  Precision: Some incorrect recommendations - needs validation")

        # Recall interpretation
        if recall >= 0.95:
            print(f"  Recall: Excellent at identifying suitable crops")
        elif recall >= 0.90:
            print(f"  Recall: Good at identifying most suitable crops")
        else:
            print(f"  Recall: Some suitable crops may be missed")

        # Deployment readiness
        unique_crops = len(np.unique(test_results['y_true']))
        print(f"\n  Successfully classifies {unique_crops} different crop types")
        print(f"  Uses 7 key agricultural parameters: N, P, K, Temperature, Humidity, pH, Rainfall")

        if accuracy >= 0.90 and f1 >= 0.90:
            print(f"\n  DEPLOYMENT STATUS: READY FOR PRODUCTION!")
        else:
            print(f"\n  DEPLOYMENT STATUS: NEEDS IMPROVEMENT")

    def predict_example(self):
        """Run an example prediction to verify the model"""
        print("\n" + "=" * 60)
        print("EXAMPLE PREDICTION")
        print("=" * 60)

        features = np.array([[90, 42, 43, 20.8, 82.0, 6.5, 202.9]])
        features_scaled = self.scaler.transform(features)

        prediction = self.model.predict(features_scaled)[0]
        probabilities = self.model.predict_proba(features_scaled)[0]

        class_names = self.model.classes_
        prob_dict = dict(zip(class_names, probabilities))
        top_5 = sorted(prob_dict.items(), key=lambda x: x[1], reverse=True)[:5]

        print(f"Input: N=90, P=42, K=43, Temp=20.8C, Humidity=82%, pH=6.5, Rainfall=202.9mm")
        print(f"\nBest Crop: {prediction.upper()}")
        print(f"Confidence: {max(probabilities):.3f} ({max(probabilities) * 100:.1f}%)")

        print(f"\nTop 5 Recommendations:")
        for i, (crop, prob) in enumerate(top_5, 1):
            print(f"  {i}. {crop.capitalize()}: {prob:.3f} ({prob * 100:.1f}%)")


def main():
    """Main testing pipeline"""
    print("=" * 60)
    print("SMART CROP RECOMMENDATION - TESTING PIPELINE")
    print("=" * 60)

    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    model_dir = os.path.join(base_dir, "ml_models")
    dataset_path = os.path.join(base_dir, "datasets", "Crop_recommendation.csv")

    tester = CropModelTester(model_dir=model_dir)

    X_val, X_test, y_val, y_test = tester.load_and_split_data(dataset_path)

    tester.validate_model(X_val, y_val)

    test_results = tester.test_model(X_test, y_test)

    tester.analyze_results(test_results)

    tester.predict_example()

    print("\nTesting pipeline completed successfully!")


if __name__ == "__main__":
    main()
