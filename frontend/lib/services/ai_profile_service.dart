class AIProfileService {
  static Map<String, dynamic> currentProfile = {
    "business_name": "My Business",
    "business_type": "General Store",
    "background_animation": "assets/lottie/default_business.json",
    "dashboard_tone": "positive",
    "confidence": 0.6,
  };

  static void updateFromAI(String businessName, Map<String, dynamic> aiResponse) {
    currentProfile = {
      "business_name": businessName,
      "business_type": aiResponse["business_type"] ?? "General Store",
      "background_animation": mapAnimation(aiResponse["background_animation"]),
      "dashboard_tone": aiResponse["dashboard_tone"] ?? "positive",
      "confidence": aiResponse["is_confident"] == true ? 1.0 : 0.5,
    };
  }

  static bool needsClarification() {
    return (currentProfile["confidence"] ?? 0) < 0.7;
  }

  static String clarificationQuestion() {
    return "Can you briefly describe what your business sells or does?";
  }

  // Map AI string to Lottie asset
  static String mapAnimation(String? animation) {
    switch (animation?.toLowerCase()) {
      case "restaurant":
        return "assets/lottie/restaurant.json";
      case "grocery":
        return "assets/lottie/grocery.json";
      case "salon":
        return "assets/lottie/salon.json";
      case "tech":
        return "assets/lottie/tech.json";
      default:
        return "assets/lottie/default_business.json";
    }
  }
}
