import { View, Text, StyleSheet } from "react-native";
import RegisterForm from "./RegisterForm";

export default function RegisterCard() {
  return (
    <View style={styles.card}>
      <Text style={styles.logo}>Trashtrails</Text>

      <Text style={styles.title}>
        Ready to Be a Trash Trailblazer? Sign Up!
      </Text>

      <Text style={styles.description}>
        Your city is waiting for its newest hero. Signing up is fast, free,
        and instantly gets you on the leaderboard. Stop being annoyed by the
        litter — start earning points for mapping it!
      </Text>

      <RegisterForm />

      <Text style={styles.footer}>
        Already a Trash Scout?{" "}
        <Text style={styles.link}>Log in here</Text>
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
  logo: {
    fontWeight: "800",
    color: "#2f6f9f",
    marginBottom: 6,
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
