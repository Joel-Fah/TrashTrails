
import { View, Image, StyleSheet, ScrollView } from "react-native";
import LoginCard from "../components/LoginCard";

export default function LoginScreen() {
  return (
    <ScrollView
      showsVerticalScrollIndicator={false}
      contentContainerStyle={styles.scrollContainer}
    >
      <Image
        source={require("../assets/login-bg.png")}
        style={styles.image}
      />

      <LoginCard />
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  scrollContainer: {
    paddingBottom: 40, 
    backgroundColor: "#fff",
  },
  image: {
    width: "100%",
    height: 260,
    resizeMode: "cover",
  },
});
