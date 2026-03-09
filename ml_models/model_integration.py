import os
import sys

# Set UTF-8 encoding for Windows console
if sys.platform == 'win32':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except:
        pass

# Console colors for consistent logging
class Colors:
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    ENDC = '\033[0m'

def log_success(msg): 
    try:
        print(f"{Colors.GREEN}[SUCCESS]{Colors.ENDC} {msg}")
    except:
        print(f"[SUCCESS] {msg}")

def log_warning(msg): 
    try:
        print(f"{Colors.YELLOW}[WARNING]{Colors.ENDC} {msg}")
    except:
        print(f"[WARNING] {msg}")

def log_error(msg): 
    try:
        print(f"{Colors.RED}[ERROR]{Colors.ENDC} {msg}")
    except:
        print(f"[ERROR] {msg}")

def log_info(msg): 
    try:
        print(f"{Colors.BLUE}[INFO]{Colors.ENDC} {msg}")
    except:
        print(f"[INFO] {msg}")

class CropPredictor:
    def __init__(self, model_dir="ml_models"):
        self.model = None
        self.scaler = None
        self.use_sklearn = False
        self.load_model()
    
    def load_model(self):
        """Load the trained model or fallback to simple model"""
        try:
            # Try to load sklearn model first
            import joblib
            # Use absolute path relative to this script
            base_dir = os.path.dirname(os.path.abspath(__file__))
            model_path = os.path.join(base_dir, 'crop_recommendation_model.joblib')
            scaler_path = os.path.join(base_dir, 'feature_scaler.joblib')
            
            if os.path.exists(model_path) and os.path.exists(scaler_path):
                self.model = joblib.load(model_path)
                self.scaler = joblib.load(scaler_path)
                self.use_sklearn = True
                log_success("Scikit-learn crop model loaded successfully!")
                log_info(f"Model classes: {len(self.model.classes_)} crops available")
                return True
        except ImportError:
            log_info("Scikit-learn not available, falling back to simple model")
        except Exception as e:
            log_warning(f"Error loading sklearn model: {e}")
        
        # Fallback to simple rule-based model
        try:
            from ml_models.crop_model_simple import simple_crop_predictor
            self.simple_model = simple_crop_predictor
            log_success("Simple rule-based crop model loaded successfully!")
            return True
        except ImportError:
            log_warning("crop_model_simple.py not found - creating basic fallback")
            # Create a basic fallback predictor
            self.simple_model = self._create_basic_fallback()
            return True
        except Exception as e:
            log_error(f"Error loading simple model: {e}")
            return False
    
    def predict_crop_recommendation(self, nitrogen, phosphorus, potassium, temperature, humidity, ph, rainfall):
        """Predict crop recommendation using available model"""
        try:
            if self.use_sklearn and self.model and self.scaler:
                # Use sklearn model
                import numpy as np
                features = np.array([[nitrogen, phosphorus, potassium, temperature, humidity, ph, rainfall]])
                features_scaled = self.scaler.transform(features)
                
                prediction = self.model.predict(features_scaled)[0]
                probabilities = self.model.predict_proba(features_scaled)[0]
                
                class_names = self.model.classes_
                crop_probabilities = []
                
                for crop, prob in zip(class_names, probabilities):
                    crop_probabilities.append({
                        'name': crop.capitalize(),
                        'probability': float(prob),
                        'confidence_percentage': float(prob * 100),
                        'priority': 'High' if prob > 0.7 else 'Medium' if prob > 0.4 else 'Low'
                    })
                
                crop_probabilities.sort(key=lambda x: x['probability'], reverse=True)
                
                return {
                    'recommended_crop': prediction.capitalize(),
                    'top_recommendations': crop_probabilities[:6],
                    'input_parameters': {
                        'nitrogen': nitrogen,
                        'phosphorus': phosphorus,
                        'potassium': potassium,
                        'temperature': temperature,
                        'humidity': humidity,
                        'ph': ph,
                        'rainfall': rainfall
                    }
                }
            else:
                # Use simple rule-based model
                return self.simple_model.predict_crop_recommendation(
                    nitrogen, phosphorus, potassium, temperature, humidity, ph, rainfall
                )
                
        except Exception as e:
            print(f"Error in prediction: {e}")
            # Return fallback recommendation
            return {
                'recommended_crop': 'Rice',
                'top_recommendations': [
                    {'name': 'Rice', 'probability': 0.85, 'confidence_percentage': 85, 'priority': 'High'},
                    {'name': 'Wheat', 'probability': 0.70, 'confidence_percentage': 70, 'priority': 'Medium'},
                    {'name': 'Maize', 'probability': 0.60, 'confidence_percentage': 60, 'priority': 'Medium'},
                ],
                'input_parameters': {
                    'nitrogen': nitrogen, 'phosphorus': phosphorus, 'potassium': potassium,
                    'temperature': temperature, 'humidity': humidity, 'ph': ph, 'rainfall': rainfall
                }
            }
    
    def _create_basic_fallback(self):
        """Create a basic fallback predictor when crop_model_simple.py is missing"""
        class BasicFallback:
            def predict_crop_recommendation(self, nitrogen, phosphorus, potassium, temperature, humidity, ph, rainfall):
                # Simple rule-based recommendations
                recommendations = []
                
                # Rice - Good for high rainfall and humidity
                if rainfall > 150 and humidity > 80:
                    recommendations.append(('Rice', 0.85))
                elif rainfall > 100:
                    recommendations.append(('Rice', 0.70))
                    
                # Wheat - Good for moderate rainfall and cooler temps
                if 15 <= temperature <= 25 and 50 <= rainfall <= 150:
                    recommendations.append(('Wheat', 0.80))
                    
                # Maize - Adaptable crop
                if 18 <= temperature <= 27:
                    recommendations.append(('Maize', 0.75))
                    
                # Cotton - Warm weather, moderate rainfall
                if temperature > 20 and 50 <= rainfall <= 100:
                    recommendations.append(('Cotton', 0.70))
                    
                # Default fallback if no good matches
                if not recommendations:
                    recommendations = [('Rice', 0.60), ('Wheat', 0.55), ('Maize', 0.50)]
                
                # Sort by probability and return top 3
                recommendations.sort(key=lambda x: x[1], reverse=True)
                top_3 = recommendations[:3]
                
                return [crop for crop, prob in top_3]
                
        return BasicFallback()

# Global predictor instance
crop_predictor = CropPredictor()
