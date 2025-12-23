import { View, Text, TextInput, TouchableOpacity, StyleSheet } from "react-native";
import { MaterialIcons, FontAwesome } from "@expo/vector-icons";

export default function RegisterForm() {
  return (
    <View>
      {/* Name */}
      <View style={styles.inputWrapper}>
        <MaterialIcons name="person" size={20} color="#6b8ba4" />
        <TextInput
          placeholder="How should we call you?"
          placeholderTextColor="#6b8ba4"
          style={styles.input}
        />
      </View>

      {/* Email */}
      <View style={styles.inputWrapper}>
        <MaterialIcons name="email" size={20} color="#6b8ba4" />
        <TextInput
          placeholder="Your reporting email"
          placeholderTextColor="#6b8ba4"
          keyboardType="email-address"
          style={styles.input}
        />
      </View>

      {/* Password */}
      <View style={styles.inputWrapper}>
        <MaterialIcons name="lock" size={20} color="#6b8ba4" />
        <TextInput
          placeholder="Your top secret password"
          placeholderTextColor="#6b8ba4"
          secureTextEntry
          style={styles.input}
        />
      </View>

      {/* Confirm Password */}
      <View style={styles.inputWrapper}>
        <MaterialIcons name="lock-outline" size={20} color="#6b8ba4" />
        <TextInput
          placeholder="Confirm your password"
          placeholderTextColor="#6b8ba4"
          secureTextEntry
          style={styles.input}
        />
      </View>

      {/* Submit */}
      <TouchableOpacity style={styles.button}>
        <Text style={styles.buttonText}>Start Earning Points!</Text>
      </TouchableOpacity>

      {/* Divider */}
      <View style={styles.divider}>
        <View style={styles.line} />
        <Text style={styles.or}>or</Text>
        <View style={styles.line} />
      </View>

      {/* Google */}
      <TouchableOpacity style={styles.googleButton}>
        <FontAwesome name="google" size={18} color="#4285F4" />
        <Text style={styles.googleText}>Join the Cleanup Crew with Google</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  inputWrapper: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: "#f1f5f9",
    borderRadius: 14,
    paddingHorizontal: 14,
    paddingVertical: 13,
    marginBottom: 12,
  },
  input: {
    flex: 1,
    marginLeft: 10,
    color: "#1f2937",
  },
  button: {
    backgroundColor: "#2f6f9f",
    paddingVertical: 15,
    borderRadius: 14,
    alignItems: "center",
    marginTop: 10,
  },
  buttonText: {
    color: "#fff",
    fontWeight: "700",
    fontSize: 16,
  },
  divider: {
    flexDirection: "row",
    alignItems: "center",
    marginVertical: 22,
  },
  line: {
    flex: 1,
    height: 1,
    backgroundColor: "#e5e7eb",
  },
  or: {
    marginHorizontal: 10,
    color: "#9ca3af",
  },
  googleButton: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: "#eef3f8",
    paddingVertical: 14,
    borderRadius: 14,
  },
  googleText: {
    marginLeft: 10,
    fontWeight: "600",
    color: "#1f2937",
  },
});
