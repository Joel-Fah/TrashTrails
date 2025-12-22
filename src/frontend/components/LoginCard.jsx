
import { View, Text, StyleSheet } from "react-native";
import LoginForm from "./LoginForm";

export default function LoginCard() {
  return (
    <View style={styles.card}>
      <Text style={styles.title}>Your City Needs You</Text>
      <Text style={styles.title}>Log In and Start the Cleanup</Text>

      <Text style={styles.description}>
        Ready to ditch the litter and finally use your street smarts for good?
        TrashTrails is where your biggest complaint becomes your greatest
        contribution. Sign up fast, because that illegal dump site on Elm Street
        isn’t going to report itself!
      </Text>

      <LoginForm />

      <Text style={styles.footer}>
        New to the trail?{" "}
        <Text style={styles.link}>Sign up here</Text> and start tackling the city
        mess!
      </Text>

      <Text style={styles.privacy}>
        Your privacy is safe: We only use your location data to map reported dump
        sites. We promise not to dump your data in a messy, unsecured landfill.
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: "#fff",
    borderTopLeftRadius: 28,
    borderTopRightRadius: 28,
    marginTop: -30,
    padding: 22,
  },
  title: {
    fontSize: 22,
    fontWeight: "800",
    color: "#1f4e79",
    lineHeight: 28,
  },
  description: {
    color: "#6b7280",
    marginVertical: 14,
    fontSize: 14,
    lineHeight: 20,
  },
  footer: {
    marginTop: 22,
    textAlign: "center",
    color: "#374151",
    fontSize: 13,
  },
  link: {
    color: "#356f9a",
    fontWeight: "600",
  },
  privacy: {
    marginTop: 10,
    textAlign: "center",
    fontSize: 11,
    color: "#9ca3af",
    lineHeight: 16,
  },
});
